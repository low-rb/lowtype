# frozen_string_literal: true

require_relative 'error_types'
require_relative 'type_definition'

module Low
  module Types
    # A set of allowed values like "Enum[:value, 'value', 123]".
    class Enum
      def self.[](*values)
        Definition.new(values:)
      end

      class Definition
        include TypeDefinition

        attr_reader :values

        def initialize(values:)
          raise AllowedTypeError, 'Enum requires at least one allowed value' if values.empty?

          @values = values.freeze
        end

        def match?(value:)
          @values.any? { |allowed| allowed == value }
        end

        def display_name
          "Enum[#{@values.map(&:inspect).join(', ')}]"
        end

        def ==(other)
          other.class == self.class && other.values == @values
        end

        def eql?(other)
          self == other
        end

        def hash
          [self.class, @values].hash
        end
      end
    end
  end
end
