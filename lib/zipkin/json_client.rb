require 'net/http'
require 'uri'
require 'json'

module Zipkin
  class JsonClient
    def initialize(url:, collector:, flush_interval:, logger: Logger.new(STDOUT))
      @collector = collector
      @flush_interval = flush_interval
      @spans_uri = URI.parse("#{url}/api/v1/spans")
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
        'Content-Type' => 'application/json'
      )
      request.body = JSON.dump(spans)
      response = http.request(request)

      if response.code.to_s != '202'
        @logger.error("Received bad response from Zipkin. status: #{response.code}, body: #{response.body.inspect}")
      end
    rescue StandardError => e
      @logger.error("Error emitting spans batch: #{e.message}\n#{e.backtrace.join("\n")}")
    end
  end
end
