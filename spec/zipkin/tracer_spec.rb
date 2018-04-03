require 'spec_helper'

describe Zipkin::Tracer do
  let(:tracer) { described_class.new(collector, service_name) }
  let(:service_name) { 'service-name' }
  let(:collector) { instance_spy(Zipkin::Collector) }

  describe '#start_span' do
    let(:operation_name) { 'operator-name' }

    context 'when a root span' do
      let(:span) { tracer.start_span(operation_name) }

      describe 'span context' do
        it 'has span_id' do
          expect(span.context.span_id).not_to be_nil
        end

        it 'has trace_id' do
          expect(span.context.trace_id).not_to be_nil
        end

        it 'does not have parent_id' do
          expect(span.context.parent_id).to be_nil
        end
      end
    end

    context 'when a child span context' do
      let(:root_span) { tracer.start_span(root_operation_name) }
      let(:span) { tracer.start_span(operation_name, child_of: root_span.context) }
      let(:root_operation_name) { 'root-operation-name' }

      describe 'span context' do
        it 'has span_id' do
          expect(span.context.span_id).not_to be_nil
        end

        it 'has trace_id' do
          expect(span.context.trace_id).not_to be_nil
        end

        it 'does not have parent_id' do
          expect(span.context.parent_id).not_to be_nil
        end
      end
    end

    context 'when a child span' do
      let(:root_span) { tracer.start_span(root_operation_name) }
      let(:span) { tracer.start_span(operation_name, child_of: root_span) }
      let(:root_operation_name) { 'root-operation-name' }

      describe 'span context' do
        it 'has span_id' do
          expect(span.context.span_id).not_to be_nil
        end

        it 'has trace_id' do
          expect(span.context.trace_id).not_to be_nil
        end

        it 'does not have parent_id' do
          expect(span.context.parent_id).not_to be_nil
        end
      end
    end
  end

  describe '#inject' do
    let(:span_context) do
      Zipkin::SpanContext.new(
        trace_id: trace_id,
        parent_id: parent_id,
        span_id: span_id,
        sampled: sampled
      )
    end
    let(:trace_id) { 'trace-id' }
    let(:parent_id) { 'trace-id' }
    let(:span_id) { 'trace-id' }
    let(:sampled) { true }
    let(:carrier) { {} }

    context 'when FORMAT_TEXT_MAP' do
      before { tracer.inject(span_context, OpenTracing::FORMAT_TEXT_MAP, carrier) }

      it 'sets trace-id' do
        expect(carrier['x-b3-traceid']).to eq(trace_id)
      end

      it 'sets parent-id' do
        expect(carrier['x-b3-parentspanid']).to eq(parent_id)
      end

      it 'sets span-id' do
        expect(carrier['x-b3-spanid']).to eq(span_id)
      end

      context 'when sampled' do
        let(:sampled) { true }

        it 'sets sampled to true' do
          expect(carrier['x-b3-sampled']).to eq('1')
        end
      end

      context 'when not sampled' do
        let(:sampled) { false }

        it 'sets sampled to 0' do
          expect(carrier['x-b3-sampled']).to eq('0')
        end
      end
    end

    context 'when FORMAT_RACK' do
      before { tracer.inject(span_context, OpenTracing::FORMAT_RACK, carrier) }

      it 'sets X-B3-TraceId' do
        expect(carrier['X-B3-TraceId']).to eq(trace_id)
      end

      it 'sets X-B3-ParentSpanId' do
        expect(carrier['X-B3-ParentSpanId']).to eq(parent_id)
      end

      it 'sets X-B3-SpanId' do
        expect(carrier['X-B3-SpanId']).to eq(span_id)
      end

      context 'when sampled' do
        let(:sampled) { true }

        it 'sets X-B3-Sampled to 1' do
          expect(carrier['X-B3-Sampled']).to eq('1')
        end
      end

      context 'when not sampled' do
        let(:sampled) { false }

        it 'sets X-B3-Sampled to 0' do
          expect(carrier['X-B3-Sampled']).to eq('0')
        end
      end
    end
  end

  describe '#extract' do
    let(:operation_name) { 'operator-name' }
    let(:trace_id) { 'trace-id' }
    let(:parent_id) { 'parent-id' }
    let(:span_id) { 'span-id' }
    let(:sampled) { '1' }

    context 'when FORMAT_TEXT_MAP' do
      let(:carrier) do
        {
          'x-b3-traceid' => trace_id,
          'x-b3-parentspanid' => parent_id,
          'x-b3-spanid' => span_id,
          'x-b3-sampled' => sampled
        }
      end
      let(:span_context) { tracer.extract(OpenTracing::FORMAT_TEXT_MAP, carrier) }

      it 'has trace id' do
        expect(span_context.trace_id).to eq(trace_id)
      end

      it 'has parent id' do
        expect(span_context.parent_id).to eq(parent_id)
      end

      it 'has span id' do
        expect(span_context.span_id).to eq(span_id)
      end

      context 'when trace-id is missing' do
        let(:trace_id) { nil }

        it 'returns nil' do
          expect(span_context).to eq(nil)
        end
      end

      context 'when span-id is missing' do
        let(:span_id) { nil }

        it 'returns nil' do
          expect(span_context).to eq(nil)
        end
      end
    end

    context 'when FORMAT_RACK' do
      let(:carrier) do
        {
          'HTTP_X_B3_TRACEID' => trace_id,
          'HTTP_X_B3_PARENTSPANID' => parent_id,
          'HTTP_X_B3_SPANID' => span_id,
          'HTTP_X_B3_SAMPLED' => sampled
        }
      end
      let(:span_context) { tracer.extract(OpenTracing::FORMAT_RACK, carrier) }

      it 'has trace id' do
        expect(span_context.trace_id).to eq(trace_id)
      end

      it 'has parent id' do
        expect(span_context.parent_id).to eq(parent_id)
      end

      it 'has span id' do
        expect(span_context.span_id).to eq(span_id)
      end

      context 'when X-B3-TraceId is missing' do
        let(:trace_id) { nil }

        it 'returns nil' do
          expect(span_context).to eq(nil)
        end
      end

      context 'when X-B3-SpanId is missing' do
        let(:span_id) { nil }

        it 'returns nil' do
          expect(span_context).to eq(nil)
        end
      end
    end
  end
end
