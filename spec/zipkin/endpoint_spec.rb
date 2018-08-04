require 'spec_helper'

RSpec.describe Zipkin::Endpoint do
  let(:span) { Zipkin::Span.new(nil, 'operation_name', nil) }

  shared_examples 'a rpc endpoint' do
    it 'returns nil if no peer info' do
      expect(remote_endpoint(span)).to eq(nil)
    end

    it 'includes service name' do
      service_name = 'service-name'
      span.set_tag('peer.service', service_name)
      expect(remote_endpoint(span).service_name).to eq(service_name)
    end

    it 'includes ipv4 address' do
      ipv4 = '8.7.6.5'
      span.set_tag('peer.ipv4', ipv4)
      expect(remote_endpoint(span).ipv4).to eq(ipv4)
    end

    it 'includes ipv6 address' do
      ipv6 = '2001:0db8:85a3:0000:0000:8a2e:0370:7334'
      span.set_tag('peer.ipv6', ipv6)
      expect(remote_endpoint(span).ipv6).to eq(ipv6)
    end

    it 'includes port' do
      port = 3000
      span.set_tag('peer.port', port)
      expect(remote_endpoint(span).port).to eq(port)
    end
  end

  describe '.remote_endpoint' do
    context 'when span kind is undefined' do
      it_behaves_like 'a rpc endpoint'
    end

    context 'when span kind is server' do
      before { span.set_tag('span.kind', 'server') }

      it_behaves_like 'a rpc endpoint'
    end

    context 'when span kind is client' do
      before { span.set_tag('span.kind', 'client') }

      it_behaves_like 'a rpc endpoint'
    end

    context 'when span kind is producer' do
      before { span.set_tag('span.kind', 'producer') }

      it 'returns broker as service name' do
        expect(remote_endpoint(span).service_name).to eq('broker')
      end
    end

    context 'when span kind is consumer' do
      before { span.set_tag('span.kind', 'consumer') }

      it 'returns broker as service name' do
        expect(remote_endpoint(span).service_name).to eq('broker')
      end
    end

    context 'when unknown span kind' do
      before { span.set_tag('span.kind', 'something-else') }

      it 'returns nil' do
        expect(remote_endpoint(span)).to eq(nil)
      end
    end
  end

  def remote_endpoint(span)
    described_class.remote_endpoint(span)
  end
end
