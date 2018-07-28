# frozen_string_literal: true

require 'thread'

require_relative './collector/buffer'

module Zipkin
  class Collector
    def initialize
      @buffer = Buffer.new
    end

    def retrieve
      @buffer.retrieve
    end

    def send_span(span)
      return unless span.context.sampled?
      @buffer << span
    end
  end
end
