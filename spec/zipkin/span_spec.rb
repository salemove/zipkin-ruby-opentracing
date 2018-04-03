require 'spec_helper'

RSpec.describe Zipkin::Span do
  describe '#log_kv' do
    let(:span) { described_class.new(nil, 'operation_name', nil) }

    it 'return nil' do
      expect(span.log_kv(key: 'value')).to be_nil
    end
  end
end
