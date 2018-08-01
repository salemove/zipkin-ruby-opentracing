# frozen_string_literal: true

module Zipkin
  module Encoders
    module Helpers
      module LogAnnotations
        module Fields
          TIMESTAMP = 'timestamp'.freeze
          VALUE = 'value'.freeze
        end

        def self.build(span)
          span.logs.map do |log|
            {
              Fields::TIMESTAMP => Timestamp.create(log.fetch(:timestamp)),
              Fields::VALUE => format_log_value(log)
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
end
