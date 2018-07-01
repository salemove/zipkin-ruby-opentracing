# frozen_string_literal: true

require 'opentracing'
require 'logger'

require_relative 'span'
require_relative 'span_context'
require_relative 'carrier'
require_relative 'trace_id'
require_relative 'json_client'
require_relative 'endpoint'
require_relative 'collector'
require_relative 'scope_manager'
require_relative 'scope'

module Zipkin
  class Tracer
    DEFAULT_FLUSH_INTERVAL = 10

    def self.build(url:, service_name:, flush_interval: DEFAULT_FLUSH_INTERVAL, logger: Logger.new(STDOUT))
      collector = Collector.new(Endpoint.local_endpoint(service_name))
      sender = JsonClient.new(
        url: url,
        collector: collector,
        flush_interval: flush_interval,
        logger: logger
      )
      sender.start
      new(collector, sender, logger: logger)
    end

    def initialize(collector, sender, logger: Logger.new(STDOUT))
      @collector = collector
      @sender = sender
      @logger = logger
      @scope_manager = ScopeManager.new
    end

    def stop
      @sender.stop
    end

    # @return [ScopeManager] the current ScopeManager, which may be a no-op but
    #   may not be nil.
    attr_reader :scope_manager

    # @return [Span, nil] the active span. This is a shorthand for
    #   `scope_manager.active.span`, and nil will be returned if
    #   Scope#active is nil.
    def active_span
      scope = scope_manager.active
      scope.span if scope
    end

    # Starts a new span
    #
    # This is similar to #start_active_span, but the returned Span will not be
    # registered via the ScopeManager.
    #
    # @param operation_name [String] The operation name for the Span
    # @param child_of [SpanContext, Span] SpanContext that acts as a parent to
    #   the newly-started Span. If a Span instance is provided, its
    #   context is automatically substituted. See [Reference] for more
    #   information.
    #
    #   If specified, the `references` parameter must be omitted.
    # @param references [Array<Reference>] An array of reference
    #   objects that identify one or more parent SpanContexts.<Paste>
    # @param start_time [Time] When the Span started, if not now
    # @param tags [Hash] Tags to assign to the Span at start time
    # @param ignore_active_scope [Boolean] whether to create an implicit
    #   References#CHILD_OF reference to the ScopeManager#active.
    #
    # @return [Span] The newly-started Span
    def start_span(operation_name,
                   child_of: nil,
                   start_time: Time.now,
                   tags: {},
                   references: nil,
                   ignore_active_scope: false,
                   **)
      context = prepare_span_context(
        child_of: child_of,
        references: references,
        ignore_active_scope: ignore_active_scope
      )
      Span.new(
        context,
        operation_name,
        @collector,
        start_time: start_time,
        references: references,
        tags: tags
      )
    end

    # Creates a newly started and activated Scope
    #
    # If the Tracer's ScopeManager#active is not nil, no explicit references
    # are provided, and `ignore_active_scope` is false, then an inferred
    # References#CHILD_OF reference is created to the ScopeManager#active's
    # SpanContext when start_active is invoked.
    #
    # @param operation_name [String] The operation name for the Span
    # @param child_of [SpanContext, Span] SpanContext that acts as a parent to
    #   the newly-started Span. If a Span instance is provided, its
    #   context is automatically substituted. See [Reference] for more
    #   information.
    #
    #   If specified, the `references` parameter must be omitted.
    # @param references [Array<Reference>] An array of reference
    #   objects that identify one or more parent SpanContexts.
    # @param start_time [Time] When the Span started, if not now
    # @param tags [Hash] Tags to assign to the Span at start time
    # @param ignore_active_scope [Boolean] whether to create an implicit
    #   References#CHILD_OF reference to the ScopeManager#active.
    # @param finish_on_close [Boolean] whether span should automatically be
    #   finished when Scope#close is called
    # @yield [Scope] If an optional block is passed to start_active it will
    #   yield the newly-started Scope. If `finish_on_close` is true then the
    #   Span will be finished automatically after the block is executed.
    # @return [Scope] The newly-started and activated Scope
    def start_active_span(operation_name,
                          child_of: nil,
                          references: nil,
                          start_time: Time.now,
                          tags: nil,
                          ignore_active_scope: false,
                          finish_on_close: true,
                          **)
      span = start_span(
        operation_name,
        child_of: child_of,
        references: references,
        start_time: start_time,
        tags: tags,
        ignore_active_scope: ignore_active_scope
      )
      scope = @scope_manager.activate(span, finish_on_close: finish_on_close)

      if block_given?
        begin
          yield scope
        ensure
          scope.close
        end
      end

      scope
    end

    # Inject a SpanContext into the given carrier
    #
    # @param span_context [SpanContext]
    # @param format [OpenTracing::FORMAT_TEXT_MAP, OpenTracing::FORMAT_BINARY, OpenTracing::FORMAT_RACK]
    # @param carrier [Carrier] A carrier object of the type dictated by the specified `format`
    def inject(span_context, format, carrier)
      case format
      when OpenTracing::FORMAT_TEXT_MAP
        carrier['x-b3-traceid'] = span_context.trace_id
        carrier['x-b3-parentspanid'] = span_context.parent_id
        carrier['x-b3-spanid'] = span_context.span_id
        carrier['x-b3-sampled'] = span_context.sampled? ? '1' : '0'
      when OpenTracing::FORMAT_RACK
        carrier['X-B3-TraceId'] = span_context.trace_id
        carrier['X-B3-ParentSpanId'] = span_context.parent_id
        carrier['X-B3-SpanId'] = span_context.span_id
        carrier['X-B3-Sampled'] = span_context.sampled? ? '1' : '0'
      else
        @logger.error "Logasm::Tracer with format #{format} is not supported yet"
      end
    end

    # Extract a SpanContext in the given format from the given carrier.
    #
    # @param format [OpenTracing::FORMAT_TEXT_MAP, OpenTracing::FORMAT_BINARY, OpenTracing::FORMAT_RACK]
    # @param carrier [Carrier] A carrier object of the type dictated by the specified `format`
    # @return [SpanContext] the extracted SpanContext or nil if none could be found
    def extract(format, carrier)
      case format
      when OpenTracing::FORMAT_TEXT_MAP
        trace_id = carrier['x-b3-traceid']
        parent_id = carrier['x-b3-parentspanid']
        span_id = carrier['x-b3-spanid']
        sampled = carrier['x-b3-sampled'] == '1'

        create_span_context(trace_id, span_id, parent_id, sampled)
      when OpenTracing::FORMAT_RACK
        trace_id = carrier['HTTP_X_B3_TRACEID']
        parent_id = carrier['HTTP_X_B3_PARENTSPANID']
        span_id = carrier['HTTP_X_B3_SPANID']
        sampled = carrier['HTTP_X_B3_SAMPLED'] == '1'

        create_span_context(trace_id, span_id, parent_id, sampled)
      else
        @logger.error "Logasm::Tracer with format #{format} is not supported yet"
        nil
      end
    end

    private

    def create_span_context(trace_id, span_id, parent_id, sampled)
      return nil if !trace_id || !span_id

      SpanContext.new(
        trace_id: trace_id,
        parent_id: parent_id,
        span_id: span_id,
        sampled: sampled
      )
    end

    def prepare_span_context(child_of:, references:, ignore_active_scope:)
      context =
        context_from_child_of(child_of) ||
        context_from_references(references) ||
        context_from_active_scope(ignore_active_scope)

      if context
        SpanContext.create_from_parent_context(context)
      else
        SpanContext.create_parent_context
      end
    end

    def context_from_child_of(child_of)
      return nil unless child_of
      child_of.respond_to?(:context) ? child_of.context : child_of
    end

    def context_from_references(references)
      return nil if !references || references.none?

      # Prefer CHILD_OF reference if present
      ref = references.detect do |reference|
        reference.type == OpenTracing::Reference::CHILD_OF
      end
      (ref || references[0]).context
    end

    def context_from_active_scope(ignore_active_scope)
      return if ignore_active_scope

      active_scope = @scope_manager.active
      active_scope.span.context if active_scope
    end
  end
end
