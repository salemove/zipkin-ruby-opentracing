require 'spec_helper'

RSpec.describe Zipkin::Encoders::ProtobufEncoder do
  let(:local_endpoint) do
    Zipkin::Endpoint.new(service_name: 'local', ipv4: '127.0.0.1')
  end
  let(:encoder) { described_class.new(local_endpoint) }

  describe '#content_type' do
    it 'returns application/x-protobuf' do
      expect(encoder.content_type).to eq('application/x-protobuf')
    end
  end
end
