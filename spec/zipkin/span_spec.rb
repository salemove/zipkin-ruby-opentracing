require 'spec_helper'

RSpec.describe Zipkin::Span do
  describe '.log_kv' do
    let(:span) do
      described_class.new(nil, 'operation_name', nil)
    end
    let(:fields) { { key1: 'value1', key2: 'value2' } }

    it 'return self' do
      expect(span.log_kv(fields)).to eq(span)
    end

    subject do
      span.log_kv(args)
      span.logs.first
    end

    context 'when args includes timestamp' do
      let(:timestamp) { Time.now }
      let(:args) { fields.merge(timestamp: timestamp) }

      it 'sets fields in log' do
        expect(subject).to include({ fields: fields })
      end
      it 'sets timestamp in log' do
        expect(subject).to include({ timestamp: timestamp })
      end
    end

    context 'when args dose not include timestamp' do
      let(:args) { fields }

      it 'sets fields in log' do
        expect(subject).to include({ fields: fields })
      end

      it 'sets timestamp in log' do
        expect(subject).to have_key(:timestamp)
        expect(subject[:timestamp]).to be_kind_of(Time)
      end
    end
  end
end
