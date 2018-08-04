require 'spec_helper'

RSpec.describe Zipkin::Encoders::JsonEncoder::LogAnnotations do
  let(:span) { Zipkin::Span.new(nil, 'operation_name', nil) }

  context 'when log includes only event and timestamp' do
    it 'uses event as the annotation value' do
      message = 'some message'
      span.log_kv(event: message)
      expect(described_class.build(span)).to include(
        'timestamp' => instance_of(Integer),
        'value' => message
      )
    end
  end

  context 'when log includes multiple fields' do
    it 'converts fields into string form' do
      span.log_kv(foo: 'bar', baz: 'buz')
      expect(described_class.build(span)).to include(
        'timestamp' => instance_of(Integer),
        'value' => 'foo=bar baz=buz'
      )
    end
  end
end
