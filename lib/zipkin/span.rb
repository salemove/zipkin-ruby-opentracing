# frozen_string_literal: true

module Zipkin
  class Span
    attr_accessor :operation_name

    attr_reader :context, :start_time, :end_time, :tags, :logs, :references

    # Creates a new {Span}
    #
    # @param context [SpanContext] the context of the span
    # @param operation_name [String] the operation name
    # @param reporter [#report] the span reporter
    #
    # @return [Span] a new Span
    def initialize(
      context,
      operation_name,
      reporter,
      start_time: Time.now,
      tags: {},
      references: nil
    )
      @context = context
      @operation_name = operation_name
      @reporter = reporter
      @start_time = start_time
      @tags = {}
      @logs = []
      @references = references

      tags.each { |key, value| set_tag(key, value) }
    end

    # Set a tag value on this span
    #
    # @param key [String] the key of the tag
    # @param value [String, Numeric, Boolean] the value of the tag. If it's not
    # a String, Numeric, or Boolean it will be encoded with to_s
    def set_tag(key, value)
      sanitized_value = valid_tag_value?(value) ? value : value.to_s
      @tags = @tags.merge(key.to_s => sanitized_value)
    end

    # Set a baggage item on the span
    #
    # @param key [String] the key of the baggage item
    # @param value [String] the value of the baggage item
    def set_baggage_item(key, value)
      self
    end

    # Get a baggage item
    #
    # @param key [String] the key of the baggage item
    #
    # @return Value of the baggage item
    def get_baggage_item(key)
      nil
    end

    # Add a log entry to this span
    #
    # @deprecated Use {#log_kv} instead.
    def log(*args)
      warn 'Span#log is deprecated. Please use Span#log_kv instead.'
      log_kv(*args)
    end

    # Add a log entry to this span
    #
    # @param timestamp [Time] time of the log
    # @param fields [Hash] Additional information to log
    def log_kv(timestamp: Time.now, **fields)
      @logs << fields.merge(timestamp: timestamp)
      nil
    end

    # Finish the {Span}
    #
    # @param end_time [Time] custom end time, if not now
    def finish(end_time: Time.now)
      @end_time = end_time
      @reporter.report(self)
    end

    private

    # Zipkin supports only strings and numbers
    def valid_tag_value?(value)
      value.is_a?(String) || value.is_a?(Numeric)
    end
  end
end
