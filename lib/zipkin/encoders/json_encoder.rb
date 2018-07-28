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

      def initialize(local_endpoint)
        @local_endpoint = local_endpoint
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
          traceId: span.context.trace_id,
          id: span.context.span_id,
          parentId: span.context.parent_id,
          name: span.operation_name,
          kind: OT_KIND_TO_ZIPKIN_KIND[span.tags[:'span.kind'] || 'server'],
          timestamp: start_ts,
          duration: duration,
          debug: false,
          shared: false,
          localEndpoint: @local_endpoint,
          remoteEndpoint: Endpoint.remote_endpoint(span),
          annotations: LogAnnotations.build(span),
          tags: span.tags
        }
      end
    end
  end
end
