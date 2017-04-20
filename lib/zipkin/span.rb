module Zipkin
  class Span
    attr_accessor :operation_name

    attr_reader :context

    # Creates a new {Span}
    #
    # @param context [SpanContext] the context of the span
    # @param context [String] the operation name
    # @param client [Faraday] faraday instace for making http requests
    #
    # @return [Span] a new Span
    def initialize(context, operation_name, client, start_time: Time.now, tags: {}, local_endpoint:)
      @context = context
      @operation_name = operation_name
      @client = client
      @start_time = start_time
      @tags = tags
      @local_endpoint = local_endpoint
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

    # Add a log entry to this span
    #
    # @param event [String] event name for the log
    # @param timestamp [Time] time of the log
    # @param fields [Hash] Additional information to log
    def log(event: nil, timestamp: Time.now, **fields)
      nil
    end

    # Finish the {Span}
    #
    # @param end_time [Time] custom end time, if not now
    def finish(end_time: Time.now)
      finish_ts = (end_time.to_f * 1_000_000).to_i
      start_ts = (@start_time.to_f * 1_000_000).to_i
      duration = finish_ts - start_ts
      is_server = ['server', 'consumer'].include?(@tags['span.kind'] || 'server')

      @client.send_span(
        traceId: @context.trace_id,
        id: @context.span_id,
        parentId: @context.parent_id,
        name: @operation_name,
        timestamp: start_ts,
        duration: duration,
        annotations: [
          {
            timestamp: start_ts,
            value: is_server ? 'sr' : 'cs',
            endpoint: @local_endpoint
          },
          {
            timestamp: finish_ts,
            value: is_server ? 'ss': 'cr',
            endpoint: @local_endpoint
          }
        ],
        binaryAnnotations: build_binary_annotations
      )
    end

    private

    def build_binary_annotations
      @tags.map do |name, value|
        {key: name, value: value.to_s}
      end
    end
  end
end
