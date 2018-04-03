module Zipkin
  class Span
    attr_accessor :operation_name

    attr_reader :context, :start_time, :tags, :logs

    # Creates a new {Span}
    #
    # @param context [SpanContext] the context of the span
    # @param operation_name [String] the operation name
    # @param collector [Collector] the span collector
    #
    # @return [Span] a new Span
    def initialize(context, operation_name, collector, start_time: Time.now, tags: {}, logs: [])
      @context = context
      @operation_name = operation_name
      @collector = collector
      @start_time = start_time
      @tags = tags
      @logs = logs
    end

    # Set a tag value on this span
    #
    # @param key [String] the key of the tag
    # @param value [String, Numeric, Boolean] the value of the tag. If it's not
    # a String, Numeric, or Boolean it will be encoded with to_s
    def set_tag(key, value)
      @tags = @tags.merge(key => value)
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

    # @deprecated Use {#log_kv} instead.
    # Reason: event is an optional standard log field defined in spec and not required.  Also,
    # method name {#log_kv} is more consistent with other language implementations such as Python and Go.
    #
    # Add a log entry to this span
    # @param event [String] event name for the log
    # @param timestamp [Time] time of the log
    # @param fields [Hash] Additional information to log
    def log(event: nil, timestamp: Time.now, **fields)
      warn "Span#log is deprecated.  Please use Span#log_kv instead."
      nil
    end

    # Add a log entry to this span
    # @param timestamp [Time] time of the log
    # @param fields [Hash] Additional information to log
    def log_kv(timestamp: Time.now, **fields)
      @logs.push({
        timestamp: timestamp,
        fields: fields,
      })
      self
    end

    # Finish the {Span}
    #
    # @param end_time [Time] custom end time, if not now
    def finish(end_time: Time.now)
      @collector.send_span(self, end_time)
    end
  end
end
