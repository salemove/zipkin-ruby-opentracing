require 'net/http'
require 'uri'
require 'json'

module Zipkin
  class JsonClient
    def initialize(url:, collector:, flush_interval:, logger: Logger.new(STDOUT))
      @collector = collector
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
      response = Faraday.post(@spans_uri) do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = spans
      end

      if response.code != '202'
        @logger.error("Received bad response from Zipkin. status: #{response.code}, body: #{response.body.inspect}")
      end
    rescue StandardError => e
      @logger.error("Error emitting spans batch: #{e.message}\n#{e.backtrace.join("\n")}")
    end
  end
end
