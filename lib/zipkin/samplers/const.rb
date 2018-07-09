# frozen_string_literal: true

module Zipkin
  module Samplers
    # Const sampler
    #
    # A sampler that always makes the same decision for new traces depending
    # on the initialization value. Use `Zipkin::Samplers::Const.new(true)`
    # to mark all new traces as sampled.
    class Const
      def initialize(decision)
        @decision = decision
      end

      def sample?(*)
        @decision
      end
    end
  end
end
