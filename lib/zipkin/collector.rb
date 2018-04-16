require 'thread'

require_relative './collector/timestamp'
require_relative './collector/log_annotations'

module Zipkin
  class Collector
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

      @buffer << {
        traceId: span.context.trace_id,
        id: span.context.span_id,
        parentId: span.context.parent_id,
        name: span.operation_name,
        kind: (span.tags['span.kind'] || 'SERVER').upcase,
        timestamp: start_ts,
        duration: duration,
        debug: false,
        shared: false,
        localEndpoint: @local_endpoint,
        remoteEndpoint: Endpoint.remote_endpoint(span),
        annotations: LogAnnotations.build(span),
        tags: build_tags(span)
      }
    end

    private

    def build_tags(span)
      span.tags.map { |key, value| [key.to_s, value.to_s] }.to_h
    end

    class Buffer
      def initialize
        @buffer = []
        @mutex = Mutex.new
      end

      def <<(element)
        @mutex.synchronize do
          @buffer << element
          true
        end
      end

      def retrieve
        @mutex.synchronize do
          elements = @buffer.dup
          @buffer.clear
          elements
        end
      end
    end
  end
end
