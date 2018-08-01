# frozen_string_literal: true

require 'net/http'
require 'uri'

module Zipkin
  class HTTPClient
    def initialize(url:, encoder:, logger:)
      @encoder = encoder
      @spans_uri = URI.parse("#{url}/api/v2/spans")
      @logger = logger
    end

    def send_spans(spans)
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
