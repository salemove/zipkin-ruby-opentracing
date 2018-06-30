module Zipkin
  class ScopeManager
    # @api private
    class ScopeStack
      def initialize
        # Generate a random identifier to use as the Thread.current key. This is
        # needed so that it would be possible to create multiple tracers in one
        # thread (mostly useful for testing purposes)
        @scope_identifier = ScopeIdentifier.generate
        Thread.current[@scope_identifier] = []
      end

      def push(scope)
        Thread.current[@scope_identifier] << scope
      end

      def pop
        Thread.current[@scope_identifier].pop
      end

      def peek
        Thread.current[@scope_identifier].last
      end
    end
  end
end
