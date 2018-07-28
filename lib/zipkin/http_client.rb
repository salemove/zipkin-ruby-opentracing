# frozen_string_literal: true

require 'net/http'
require 'uri'

module Zipkin
  class HTTPClient
    def initialize(url:, collector:, encoder:, flush_interval:, logger: Logger.new(STDOUT))
      @collector = collector
      @encoder = encoder
      @flush_interval = flush_interval
      @spans_uri = URI.parse("#{url}/api/v2/spans")
      @logger = logger
    end

    def start
      @thread = Thread.new do
        loop do
          emit_batch(@collector.retrieve)
          sleep @flush_interval
        end
      end
    end

    def stop
      @thread.terminate if @thread
      emit_batch(@collector.retrieve)
    end

    private

    def emit_batch(spans)
      return if spans.empty?

      http = Net::HTTP.new(@spans_uri.host, @spans_uri.port)
      http.use_ssl = @spans_uri.scheme == 'https'
      request = Net::HTTP::Post.new(
        @spans_uri.request_uri,
        'Content-Type' => @encoder.content_type
      )
      request.body = @encoder.encode(spans)
      response = http.request(request)

      if response.code != '202'
        @logger.error("Received bad response from Zipkin. status: #{response.code}, body: #{response.body.inspect}")
      end
    rescue StandardError => e
      @logger.error("Error emitting spans batch: #{e.message}\n#{e.backtrace.join("\n")}")
    end
  end
end
