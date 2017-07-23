require 'opentracing'

require_relative 'span'
require_relative 'span_context'
require_relative 'carrier'
require_relative 'trace_id'
require_relative 'json_client'
require_relative 'endpoint'
require_relative 'collector'

module Zipkin
  class Tracer
    DEFAULT_FLUSH_INTERVAL = 10

    def self.build(url:, service_name:, flush_interval: DEFAULT_FLUSH_INTERVAL)
      collector = Collector.new(Endpoint.local_endpoint(service_name))
      sender = JsonClient.new(
        url: url,
        collector: collector,
        flush_interval: flush_interval
      )
      sender.start
      new(collector, sender)
    end

    def initialize(collector, sender)
      @collector = collector
      @sender = sender
    end

    def stop
      @sender.stop
    end

    # Starts a new span.
    #
    # @param operation_name [String] The operation name for the Span
    # @param child_of [SpanContext, Span] SpanContext that acts as a parent to
    #        the newly-started Span. If a Span instance is provided, its
    #        context is automatically substituted.
    # @param start_time [Time] When the Span started, if not now
    # @param tags [Hash] Tags to assign to the Span at start time
    #
    # @return [Span] The newly-started Span
    def start_span(operation_name, child_of: nil, start_time: Time.now, tags: {}, **)
      context =
        if child_of
          parent_context = child_of.respond_to?(:context) ? child_of.context : child_of
          SpanContext.create_from_parent_context(parent_context)
        else
          SpanContext.create_parent_context
        end
      Span.new(context, operation_name, @collector, {
        start_time: start_time,
        tags: tags
      })
    end

    # Inject a SpanContext into the given carrier
    #
    # @param span_context [SpanContext]
    # @param format [OpenTracing::FORMAT_TEXT_MAP, OpenTracing::FORMAT_BINARY, OpenTracing::FORMAT_RACK]
    # @param carrier [Carrier] A carrier object of the type dictated by the specified `format`
    def inject(span_context, format, carrier)
      case format
      when OpenTracing::FORMAT_RACK
        carrier['X-B3-TraceId'] = span_context.trace_id
        carrier['X-B3-ParentSpanId'] = span_context.parent_id
        carrier['X-B3-SpanId'] = span_context.span_id
        carrier['X-B3-Sampled'] = span_context.sampled? ? '1' : '0'
      else
        STDERR.puts "Logasm::Tracer with format #{format} is not supported yet"
      end
    end

    # Extract a SpanContext in the given format from the given carrier.
    #
    # @param format [OpenTracing::FORMAT_TEXT_MAP, OpenTracing::FORMAT_BINARY, OpenTracing::FORMAT_RACK]
    # @param carrier [Carrier] A carrier object of the type dictated by the specified `format`
    # @return [SpanContext] the extracted SpanContext or nil if none could be found
    def extract(format, carrier)
      case format
      when OpenTracing::FORMAT_RACK
        trace_id = carrier['HTTP_X_B3_TRACEID']
        parent_id = carrier['HTTP_X_B3_PARENTSPANID']
        span_id = carrier['HTTP_X_B3_SPANID']
        sampled = carrier['HTTP_X_B3_SAMPLED'] == '1'

        if trace_id && span_id
          SpanContext.new(
            trace_id: trace_id,
            parent_id: parent_id,
            span_id: span_id,
            sampled: sampled
          )
        else
          nil
        end
      else
        STDERR.puts "Logasm::Tracer with format #{format} is not supported yet"
        nil
      end
    end
  end
end
