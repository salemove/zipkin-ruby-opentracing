require 'socket'

module Zipkin
  class Endpoint
    LOCAL_IP = (
      Socket.ip_address_list.detect(&:ipv4_private?) ||
      Socket.ip_address_list.reverse.detect(&:ipv4?)
    ).ip_address

    module SpanKind
      SERVER = 'server'.freeze
      CLIENT = 'client'.freeze
      PRODUCER = 'producer'.freeze
      CONSUMER = 'consumer'.freeze
    end

    module PeerInfo
      SERVICE = 'peer.service'.freeze
      IPV4 = 'peer.ipv4'.freeze
      IPV6 = 'peer.ipv6'.freeze
      PORT = 'peer.port'.freeze

      def self.keys
        [SERVICE, IPV4, IPV6, PORT]
      end
    end

    def self.local_endpoint(service_name)
      {
        serviceName: service_name,
        ipv4: LOCAL_IP
      }
    end

    def self.remote_endpoint(span)
      tags = span.tags
      kind = tags['span.kind'] || SpanKind::SERVER

      case kind
      when SpanKind::SERVER, SpanKind::CLIENT
        return nil if (tags.keys & PeerInfo.keys).empty?

        {
          serviceName: tags[PeerInfo::SERVICE],
          ipv4: tags[PeerInfo::IPV4],
          ipv6: tags[PeerInfo::IPV6],
          port: tags[PeerInfo::PORT]
        }
      when SpanKind::PRODUCER, SpanKind::CONSUMER
        {
          serviceName: 'broker'
        }
      else
        warn "Unkown span kind: #{kind}"
        nil
      end
    end
  end
end
