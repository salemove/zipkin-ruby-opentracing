# frozen_string_literal: true

require 'zipkin/proto3.pb'

require_relative 'helpers/timestamp'
require_relative 'helpers/log_annotations'
require_relative 'protobuf_encoder/proto_span_builder'

module Zipkin
  module Encoders
    class ProtobufEncoder
      CONTENT_TYPE = 'application/x-protobuf'.freeze

      def initialize(local_endpoint)
        @proto_span_builder = ProtoSpanBuilder.new(local_endpoint)
      end

      def content_type
        CONTENT_TYPE
      end

      def encode(spans)
        Proto3::ListOfSpans.new(
          spans: spans.map(&@proto_span_builder.method(:build))
        ).encode
      end
    end
  end
end
