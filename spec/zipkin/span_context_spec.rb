require 'spec_helper'

RSpec.describe Zipkin::SpanContext do
  describe '.create_from_parent_context' do
    let(:parent) do
      described_class.new(
        trace_id: trace_id,
        parent_id: nil,
        span_id: parent_span_id,
        sampled: sampled
      )
    end
    let(:trace_id) { 'trace-id' }
    let(:parent_span_id) { 'span-id' }
    let(:sampled) { true }

    it 'has same trace ID' do
      context = described_class.create_from_parent_context(parent)
      expect(context.trace_id).to eq(trace_id)
    end

    it 'has same parent span id as parent id' do
      context = described_class.create_from_parent_context(parent)
      expect(context.parent_id).to eq(parent_span_id)
    end

    it 'has same its own span id' do
      context = described_class.create_from_parent_context(parent)
      expect(context.span_id).not_to eq(parent_span_id)
    end

    context 'when sampler returns true' do
      let(:sampler) { Zipkin::Samplers::Const.new(true) }

      it 'marks context as sampled' do
        context = described_class.create_parent_context(sampler)
        expect(context).to be_sampled
      end
    end

    context 'when sampler returns false' do
      let(:sampler) { Zipkin::Samplers::Const.new(false) }

      it 'marks context as not sampled' do
        context = described_class.create_parent_context(sampler)
        expect(context).not_to be_sampled
      end
    end
  end

  describe '#to_h' do
    it 'returns information about the span context' do
      context = described_class.create_parent_context
      expect(context.to_h).to eq(
        span_id: context.span_id,
        parent_id: context.parent_id,
        trace_id: context.trace_id,
        sampled: context.sampled?
      )
    end
  end
end
