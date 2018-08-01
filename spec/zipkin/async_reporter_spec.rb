require 'spec_helper'

RSpec.describe Zipkin::AsyncReporter do
  let(:reporter) { described_class.new(sender) }
  let(:operation_name) { 'op-name' }
  let(:sender) { spy }

  describe '#report' do
    let(:context) do
      Zipkin::SpanContext.new(
        trace_id: Zipkin::TraceId.generate,
        span_id: Zipkin::TraceId.generate,
        sampled: sampled
      )
    end
    let(:span) { Zipkin::Span.new(context, operation_name, reporter) }

    context 'when span is sampled' do
      let(:sampled) { true }

      it 'buffers the span' do
        reporter.report(span)
        expect(reporter.flush).not_to be_empty
      end
    end

    context 'when span does not have debug mode nor is sampled' do
      let(:sampled) { false }

      it 'does not buffer the span' do
        reporter.report(span)
        expect(reporter.flush).to be_empty
      end
    end
  end
end
