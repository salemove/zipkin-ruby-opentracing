# frozen_string_literal: true

module Zipkin
  module TraceId
    TRACE_ID_UPPER_BOUND = 2**64

    # Random number generator for generating IDs. This is an object that can
    # respond to `#bytes` and uses the system PRNG. The current logic is
    # compatible with Ruby 2.5 (which does not implement the `Random.bytes`
    # class method) and with Ruby 3.0+ (which deprecates `Random::DEFAULT`).
    # When we drop support for Ruby 2.5, this can simply be replaced with
    # the class `Random`.
    #
    # @return [#bytes]
    RANDOM = Random.respond_to?(:bytes) ? Random : Random::DEFAULT

    # An invalid trace identifier, an 8-byte string with all zero bytes.
    INVALID_TRACE_ID = ("\0" * 8).b

    # Generates a valid trace identifier, an 8-byte string with at least one
    # non-zero byte.
    #
    # @return [String] a valid trace ID.
    def self.generate
      loop do
        id = RANDOM.bytes(8)
        return id.unpack1('H*') if id != INVALID_TRACE_ID
      end
    end
  end
end
