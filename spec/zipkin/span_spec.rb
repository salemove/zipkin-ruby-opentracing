require 'spec_helper'

RSpec.describe Zipkin::Span do
  describe '.log_kv' do
    let(:span) do
      described_class.new(nil, 'operation_name', nil)
    end
    let(:feilds) { { key: 'value' } }

    it 'return nil' do
      expect(span.log_kv(feilds)).to be_nil
    end
  end
end
