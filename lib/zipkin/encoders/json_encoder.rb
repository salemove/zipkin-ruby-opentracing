# frozen_string_literal: true

require 'json'

require_relative 'json_encoder/timestamp'
require_relative 'json_encoder/log_annotations'

module Zipkin
  module Encoders
    class JsonEncoder
      OT_KIND_TO_ZIPKIN_KIND = {
        'server' => 'SERVER',
        'client' => 'CLIENT',
        'producer' => 'PRODUCER',
        'consumer' => 'CONSUMER'
      }.freeze

      CONTENT_TYPE = 'application/json'.freeze

      module Fields
        TRACE_ID = 'traceId'.freeze
        SPAN_ID = 'id'.freeze
        PARENT_ID = 'parentId'.freeze
        OPERATION_NAME = 'name'.freeze
        KIND = 'kind'.freeze
        TIMESTAMP = 'timestamp'.freeze
        DURATION = 'duration'.freeze
        DEBUG = 'debug'.freeze
        SHARED = 'shared'.freeze
        LOCAL_ENDPOINT = 'localEndpoint'.freeze
        REMOTE_ENDPOINT = 'remoteEndpoint'.freeze
        ANNOTATIONS = 'annotations'.freeze
        TAGS = 'tags'.freeze

        module Endpoint
          SERVICE_NAME = 'serviceName'.freeze
          IPV4 = 'ipv4'.freeze
          IPV6 = 'ipv6'.freeze
          PORT = 'port'.freeze
        end
      end

      def initialize(local_endpoint)
        @local_endpoint = serialize_endpoint(local_endpoint)
      end

      def content_type
        CONTENT_TYPE
      end

      def encode(spans)
        JSON.dump(spans.map(&method(:serialize)))
      end

      private

      def serialize(span)
        finish_ts = Timestamp.create(span.end_time)
        start_ts = Timestamp.create(span.start_time)
        duration = finish_ts - start_ts

        {
          Fields::TRACE_ID => span.context.trace_id,
          Fields::SPAN_ID => span.context.span_id,
          Fields::PARENT_ID => span.context.parent_id,
          Fields::OPERATION_NAME => span.operation_name,
          Fields::KIND => OT_KIND_TO_ZIPKIN_KIND[span.tags[:'span.kind'] || 'server'],
          Fields::TIMESTAMP => start_ts,
          Fields::DURATION => duration,
          Fields::DEBUG => false,
          Fields::SHARED => false,
          Fields::LOCAL_ENDPOINT => @local_endpoint,
          Fields::REMOTE_ENDPOINT => serialize_endpoint(Endpoint.remote_endpoint(span)),
          Fields::ANNOTATIONS => LogAnnotations.build(span),
          Fields::TAGS => span.tags
        }
      end

      def serialize_endpoint(endpoint)
        return nil unless endpoint

        {
          Fields::Endpoint::SERVICE_NAME => endpoint.service_name,
          Fields::Endpoint::IPV4 => endpoint.ipv4,
          Fields::Endpoint::IPV6 => endpoint.ipv6,
          Fields::Endpoint::PORT => endpoint.port
        }
      end
    end
  end
end
