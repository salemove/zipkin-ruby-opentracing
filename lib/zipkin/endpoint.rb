module Zipkin
  class Endpoint
    LOCAL_IP = Socket.ip_address_list.detect(&:ipv4_private?).ip_address

    def self.local_endpoint(service_name)
      {
        serviceName: service_name,
        ipv4: LOCAL_IP
      }
    end
  end
end
