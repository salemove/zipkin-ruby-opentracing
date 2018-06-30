require 'spec_helper'

RSpec.describe Zipkin::Collector do
  let(:collector) { described_class.new(local_endpoint) }
  let(:local_endpoint) { Zipkin::Endpoint.local_endpoint('local') }
  let(:operation_name) { 'op-name' }

  describe '#send_span' do
    let(:context) do
      Zipkin::SpanContext.new(
        trace_id: Zipkin::TraceId.generate,
        span_id: Zipkin::TraceId.generate,
        sampled: sampled
      )
    end
    let(:span) { Zipkin::Span.new(context, operation_name, collector) }

    context 'when span is sampled' do
      let(:sampled) { true }

      it 'buffers the span' do
        collector.send_span(span, Time.now)
        expect(collector.retrieve).not_to be_empty
      end
    end

    context 'when span does not have debug mode nor is sampled' do
      let(:sampled) { false }

      it 'does not buffer the span' do
        collector.send_span(span, Time.now)
        expect(collector.retrieve).to be_empty
      end
    end
  end
end
