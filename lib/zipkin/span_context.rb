module Zipkin
  # SpanContext holds the data for a span that gets inherited to child spans
  class SpanContext
    def self.create_parent_context
      span_id = TraceId.generate
      trace_id = span_id
      new(span_id: span_id, trace_id: trace_id)
    end

    def self.create_from_parent(parent_span)
      trace_id = parent_span.context.trace_id
      parent_id = parent_span.context.span_id
      span_id = TraceId.generate
      new(span_id: span_id, parent_id: parent_id, trace_id: trace_id)
    end

    attr_reader :span_id, :parent_id, :trace_id, :baggage

    def initialize(span_id:, parent_id: nil, trace_id:, baggage: {})
      @span_id = span_id
      @parent_id = parent_id
      @trace_id = trace_id
      @baggage = baggage
    end
  end
end
