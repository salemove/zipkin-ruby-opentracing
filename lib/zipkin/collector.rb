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
      is_server = %w[server consumer].include?(span.tags['span.kind'] || 'server')

      @buffer << {
        traceId: span.context.trace_id,
        id: span.context.span_id,
        parentId: span.context.parent_id,
        name: span.operation_name,
        timestamp: start_ts,
        duration: duration,
        annotations: LogAnnotations.build(span, @local_endpoint) + [
          {
            timestamp: start_ts,
            value: is_server ? 'sr' : 'cs',
            endpoint: @local_endpoint
          },
          {
            timestamp: finish_ts,
            value: is_server ? 'ss' : 'cr',
            endpoint: @local_endpoint
          }
        ],
        binaryAnnotations: build_binary_annotations(span)
      }
    end

    private

    def build_binary_annotations(span)
      span.tags.map do |name, value|
        { key: name, value: value.to_s }
      end
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
