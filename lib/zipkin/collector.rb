# frozen_string_literal: true

require 'thread'

require_relative './collector/timestamp'
require_relative './collector/log_annotations'
require_relative './collector/buffer'

module Zipkin
  class Collector
    OT_KIND_TO_ZIPKIN_KIND = {
      'server' => 'SERVER',
      'client' => 'CLIENT',
      'producer' => 'PRODUCER',
      'consumer' => 'CONSUMER'
    }.freeze

    def initialize(local_endpoint)
      @buffer = Buffer.new
      @local_endpoint = local_endpoint
    end

    def retrieve
      @buffer.retrieve
    end

    def send_span(span, end_time)
      finish_ts = Timestamp.create(end_time)
      start_ts = Timestamp.create(span.start_time)
      duration = finish_ts - start_ts
      return unless span.context.sampled?

      @buffer << {
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
