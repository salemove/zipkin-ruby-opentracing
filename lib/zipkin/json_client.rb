require 'faraday'
require 'faraday_middleware'

module Zipkin
  class JsonClient
    def initialize(url:, collector:, flush_interval:)
      @collector = collector
      @flush_interval = flush_interval
      @faraday = Faraday.new(url: url) do |faraday|
        faraday.request :json
        faraday.request :retry, max: 3, interval: 10, backoff_factor: 2
        faraday.adapter Faraday.default_adapter
      end
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

      response = @faraday.post '/api/v1/spans' do |req|
        req.body = spans
      end

      if response.status != 202
        STDERR.puts(response.body)
      end
    end
  end
end
