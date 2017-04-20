require 'spec_helper'

describe Zipkin::Tracer do
  let(:tracer) { described_class.new(client, service_name) }
  let(:service_name) { 'service-name' }
  let(:client) { spy(Zipkin::JsonClient) }

  describe '#start_span' do
    let(:operation_name) { 'operator-name' }

    context 'when a root span' do
      let(:span) { tracer.start_span(operation_name) }

      context 'span context' do
        it 'has span_id' do
          expect(span.context.span_id).to_not be_nil
        end

        it 'has trace_id' do
          expect(span.context.trace_id).to_not be_nil
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

      context 'span context' do
        it 'has span_id' do
          expect(span.context.span_id).to_not be_nil
        end

        it 'has trace_id' do
          expect(span.context.trace_id).to_not be_nil
        end

        it 'does not have parent_id' do
          expect(span.context.parent_id).to_not be_nil
        end
      end
    end

    context 'when a child span' do
      let(:root_span) { tracer.start_span(root_operation_name) }
      let(:span) { tracer.start_span(operation_name, child_of: root_span) }
      let(:root_operation_name) { 'root-operation-name' }

      context 'span context' do
        it 'has span_id' do
          expect(span.context.span_id).to_not be_nil
        end

        it 'has trace_id' do
          expect(span.context.trace_id).to_not be_nil
        end

        it 'does not have parent_id' do
          expect(span.context.parent_id).to_not be_nil
        end
      end
    end
  end

  describe '#inject' do
    let(:operation_name) { 'operator-name' }
    let(:span) { tracer.start_span(operation_name) }
    let(:span_context) { span.context }
    let(:carrier) { {} }

    context 'when FORMAT_TEXT_MAP' do
      before { tracer.inject(span_context, OpenTracing::FORMAT_TEXT_MAP, carrier) }

      it 'sets trace-id' do
        expect(carrier['trace-id']).to eq(span_context.trace_id)
      end

      it 'sets parent-id' do
        expect(carrier['parent-id']).to eq(span_context.parent_id)
      end

      it 'sets span-id' do
        expect(carrier['span-id']).to eq(span_context.span_id)
      end
    end
  end

  describe '#extract' do
    let(:operation_name) { 'operator-name' }
    let(:trace_id) { 'trace-id' }
    let(:parent_id) { 'parent-id' }
    let(:span_id) { 'span-id' }

    context 'when FORMAT_TEXT_MAP' do
      let(:carrier) do
        {
          'trace-id' => trace_id,
          'parent-id' => parent_id,
          'span-id' => span_id
        }
      end
      let(:span_context) { tracer.extract(OpenTracing::FORMAT_TEXT_MAP, carrier) }

      it 'has trace-id' do
        expect(span_context.trace_id).to eq(trace_id)
      end

      it 'has parent-id' do
        expect(span_context.parent_id).to eq(parent_id)
      end

      it 'has span-id' do
        expect(span_context.span_id).to eq(span_id)
      end

      context 'when trace-id missing' do
        let(:trace_id) { nil }

        it 'returns nil' do
          expect(span_context).to eq(nil)
        end
      end

      context 'when span-id missing' do
        let(:span_id) { nil }

        it 'returns nil' do
          expect(span_context).to eq(nil)
        end
      end
    end

    context 'when FORMAT_RACK' do
      let(:carrier) do
        {
          'HTTP_X_TRACE_ID' => trace_id,
          'HTTP_X_TRACE_PARENT_ID' => parent_id,
          'HTTP_X_TRACE_SPAN_ID' => span_id
        }
      end
      let(:span_context) { tracer.extract(OpenTracing::FORMAT_RACK, carrier) }

      it 'has trace-id' do
        expect(span_context.trace_id).to eq(trace_id)
      end

      it 'has parent-id' do
        expect(span_context.parent_id).to eq(parent_id)
      end

      it 'has span-id' do
        expect(span_context.span_id).to eq(span_id)
      end

      context 'when X-Trace-Id missing' do
        let(:trace_id) { nil }

        it 'returns nil' do
          expect(span_context).to eq(nil)
        end
      end

      context 'when X-Trace-Span-Id missing' do
        let(:span_id) { nil }

        it 'returns nil' do
          expect(span_context).to eq(nil)
        end
      end
    end
  end
end
