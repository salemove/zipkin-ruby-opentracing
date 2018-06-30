# frozen_string_literal: true

module Zipkin
  class Collector
    module Timestamp
      def self.create(time)
        (time.to_f * 1_000_000).to_i
      end
    end
  end
end
