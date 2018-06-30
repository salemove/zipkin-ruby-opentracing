# frozen_string_literal: true

module Zipkin
  module TraceId
    TRACE_ID_UPPER_BOUND = 2**64

    def self.generate
      rand(TRACE_ID_UPPER_BOUND).to_s(16)
    end
  end
end
