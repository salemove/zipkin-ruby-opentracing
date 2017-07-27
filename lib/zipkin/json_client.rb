require 'net/http'
require 'uri'
require 'json'

module Zipkin
  class JsonClient
    def initialize(url:, collector:, flush_interval:)
      @collector = collector
      @flush_interval = flush_interval
      @spans_uri = URI.parse("#{url}/api/v1/spans")
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
      request = Net::HTTP::Post.new(@spans_uri.request_uri, {
        'Content-Type' => 'application/json'
      })
      request.body = JSON.dump(spans)
      response = http.request(request)

      if response.code != 202
        STDERR.puts(response.body)
      end
    end
  end
end
