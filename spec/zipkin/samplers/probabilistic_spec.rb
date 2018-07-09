require 'spec_helper'

RSpec.describe Zipkin::Samplers::Probabilistic do
  let(:sampler) { described_class.new(rate: rate) }

  context 'when rate is set to 0' do
    let(:rate) { 0 }

    it 'returns false for every trace' do
      trace_id = Zipkin::TraceId.generate
      expect(sampler.sample?(trace_id: trace_id)).to eq(false)
    end
  end

  context 'when rate is set to 0.5' do
    let(:rate) { 0.5 }

    it 'returns false for traces over the boundary' do
      trace_id = (Zipkin::TraceId::TRACE_ID_UPPER_BOUND / 2 + 1).to_s(16)
      expect(sampler.sample?(trace_id: trace_id)).to eq(false)
    end

    it 'returns true for traces under the boundary' do
      trace_id = (Zipkin::TraceId::TRACE_ID_UPPER_BOUND / 2 - 1).to_s(16)
      expect(sampler.sample?(trace_id: trace_id)).to eq(true)
    end
  end

  context 'when rate is set to 1' do
    let(:rate) { 1 }

    it 'returns true for every trace' do
      trace_id = Zipkin::TraceId.generate
      expect(sampler.sample?(trace_id: trace_id)).to eq(true)
    end
  end
end
