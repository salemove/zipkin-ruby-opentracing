module Zipkin
  module TraceId
    TRACE_ID_UPPER_BOUND = 2 ** 64

    def self.generate
      rand(TRACE_ID_UPPER_BOUND)
    end
  end
end
