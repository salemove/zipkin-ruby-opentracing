require 'faraday'
require 'faraday_middleware'
require 'sucker_punch'

module Zipkin
  class JsonClient
    def initialize(url)
      @faraday = Faraday.new(url: url) do |faraday|
        faraday.request :json
        faraday.request :retry, max: 3, interval: 10, backoff_factor: 2
        faraday.adapter Faraday.default_adapter
      end
    end

    def send_span(payload)
      SpanSender.perform_async(payload: payload, faraday: @faraday)
    end

    class SpanSender
      include SuckerPunch::Job
      workers 4

      def perform(payload:, faraday:)
        response = faraday.post '/api/v1/spans' do |req|
          req.body = [payload]
        end

        if response.status != 202
          STDERR.puts(response.body)
        end
      end
    end
  end
end
