# frozen_string_literal: true

module Zipkin
  module Encoders
    class ProtobufEncoder
      class ProtoSpanBuilder
        OT_KIND_TO_ZIPKIN_KIND = {
          'server' => Proto3::Span::Kind::SERVER,
          'client' => Proto3::Span::Kind::CLIENT,
          'producer' => Proto3::Span::Kind::PRODUCER,
          'consumer' => Proto3::Span::Kind::CONSUMER
        }.freeze

        module Fields
          TRACE_ID = 'trace_id'.freeze
          SPAN_ID = 'id'.freeze
          PARENT_ID = 'parent_id'.freeze
          OPERATION_NAME = 'name'.freeze
          KIND = 'kind'.freeze
          TIMESTAMP = 'timestamp'.freeze
          DURATION = 'duration'.freeze
          DEBUG = 'debug'.freeze
          SHARED = 'shared'.freeze
          LOCAL_ENDPOINT = 'local_endpoint'.freeze
          REMOTE_ENDPOINT = 'remote_endpoint'.freeze
          ANNOTATIONS = 'annotations'.freeze
          TAGS = 'tags'.freeze

          module Endpoint
            SERVICE_NAME = 'service_name'.freeze
            IPV4 = 'ipv4'.freeze
            IPV6 = 'ipv6'.freeze
            PORT = 'port'.freeze
          end
        end

        def initialize(local_endpoint)
          @local_endpoint = to_proto_endpoint(local_endpoint)
        end

        def build(span)
          finish_ts = Helpers::Timestamp.create(span.end_time)
          start_ts = Helpers::Timestamp.create(span.start_time)
          duration = finish_ts - start_ts

          Proto3::Span.new(
            Fields::TRACE_ID => id_bytes(span.context.trace_id),
            Fields::PARENT_ID => id_bytes(span.context.parent_id),
            Fields::SPAN_ID => id_bytes(span.context.span_id),
            Fields::KIND => OT_KIND_TO_ZIPKIN_KIND[span.tags[:'span.kind'] || 'server'],
            Fields::OPERATION_NAME => span.operation_name,
            Fields::TIMESTAMP => start_ts,
            Fields::DURATION => duration,
            Fields::LOCAL_ENDPOINT => @local_endpoint,
            Fields::REMOTE_ENDPOINT => to_proto_endpoint(Endpoint.remote_endpoint(span)),
            Fields::ANNOTATIONS => Helpers::LogAnnotations.build(span).map(&Proto3::Annotation.method(:new)),
            Fields::TAGS => to_proto_tags(span.tags),
            Fields::DEBUG => false,
            Fields::SHARED => false
          )
        end

        private

        def to_proto_endpoint(endpoint)
          return unless endpoint

          Proto3::Endpoint.new(
            Fields::Endpoint::SERVICE_NAME => endpoint.service_name,
            Fields::Endpoint::IPV4 => ipv4_to_bytes(endpoint.ipv4),
            Fields::Endpoint::PORT => endpoint.port
          )
        end

        def to_proto_tags(tags)
          Hash[tags.map { |key, value| [key, value.to_s] }]
        end

        def ipv4_to_bytes(ipv4)
          ipv4 ? ipv4.split('.').map(&:to_i).pack('C*') : nil
        end

        def id_bytes(id)
          id ? [id].pack('H*') : ''
        end
      end
    end
  end
end
