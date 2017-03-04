require 'spec_helper'

describe Zipkin::Tracer do
  let(:tracer) { described_class.new(client) }

  let(:client) { double('client') }

  describe '#start_span' do
    let(:operation_name) { 'operator-name' }

    context 'when a root span' do
      let(:span) { tracer.start_span(operation_name) }

      it 'has operation name' do
        expect(span.operation_name).to eq(operation_name)
      end

      it 'has context' do
        expect(span.context).to eq(Zipkin::SpanContext::NOOP_INSTANCE)
      end
    end

    context 'when a child span' do
      let(:root_span) { tracer.start_span(root_operation_name) }
      let(:span) { tracer.start_span(operation_name, child_of: root_span) }
      let(:root_operation_name) { 'root-operation-name' }

      it 'has operation name' do
        expect(span.operation_name).to eq(operation_name)
      end

      it 'has child context' do
        expect(span.context).to eq(root_span.context)
      end
    end
  end
end
