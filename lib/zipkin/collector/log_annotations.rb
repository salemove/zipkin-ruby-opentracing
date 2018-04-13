module Zipkin
  class Collector
    module LogAnnotations
      def self.build(span)
        span.logs.map do |log|
          {
            timestamp: Timestamp.create(log.fetch(:timestamp)),
            value: format_log_value(log)
          }
        end
      end

      def self.format_log_value(log)
        if log.keys == %i[event timestamp]
          log.fetch(:event)
        else
          log
            .reject { |key, _value| key == :timestamp }
            .map { |key, value| "#{key}=#{value}" }
            .join(' ')
        end
      end
    end
  end
end
