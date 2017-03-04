module Zipkin
  class Tracer
    def self.build(host:, port:, service_name:)
    end

    def initialize(client)
      @client = client
    end

    # Start a new span
    #
    # @param operation_name [String]
    #   The operation name for the Span
    # @param child_of [SpanContext]
    #   SpanContext that acts as a parent to the newly-started Span. If a Span
    #   instance is provided, its #context is automatically substituted.
    # @param start_time [Time]
    #   The time when the Span started, if not now
    # @param tags [Hash]
    #   Tags to assign to the Span at start time
    #
    # @return [Span]
    #   The newly-started Span
    def start_span(operation_name, child_of: nil, start_time: Time.now, tags: nil)
      context = child_of ? child_of.context : SpanContext::NOOP_INSTANCE
      span = Span.new(self, context)
      span.operation_name = operation_name
      span
    end

    # Inject a SpanContext into the given carrier
    #
    # @param span_context [SpanContext]
    # @param format [OpenTracing::FORMAT_TEXT_MAP, OpenTracing::FORMAT_BINARY, OpenTracing::FORMAT_RACK]
    #
    # @param carrier [Carrier]
    #   A carrier object of the type dictated by the specified `format`
    def inject(span_context, format, carrier)
      case format
      when OpenTracing::FORMAT_TEXT_MAP, OpenTracing::FORMAT_BINARY, OpenTracing::FORMAT_RACK
        return nil
      else
        warn 'Unknown inject format'
      end
    end

    # Extract a SpanContext in the given format from the given carrier.
    #
    # @param format [OpenTracing::FORMAT_TEXT_MAP, OpenTracing::FORMAT_BINARY, OpenTracing::FORMAT_RACK]
    # @param carrier [Carrier]
    #   A carrier object of the type dictated by the specified `format`
    #
    # @return [SpanContext]
    #   the extracted SpanContext or nil if none could be found
    def extract(format, carrier)
      case format
      when OpenTracing::FORMAT_TEXT_MAP, OpenTracing::FORMAT_BINARY, OpenTracing::FORMAT_RACK
        return SpanContext::NOOP_INSTANCE
      else
        warn 'Unknown extract format'
        nil
      end
    end

  end
end
