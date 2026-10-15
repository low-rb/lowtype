# frozen_string_literal: true

require_relative '../expressions/type_expression'
require_relative '../types/type_definition'

module Low
  # TODO: Unit test.
  class TypeQuery
    class << self
      def type?(expression)
        basic_type?(expression:) || complex_type?(expression:) || typed_array?(expression:) || typed_hash?(expression:)
      end

      def typed_array?(expression:)
        expression.is_a?(Array) && (basic_type?(expression: expression.first) || expression.first.is_a?(TypeExpression))
      end

      def value?(value)
        !type?(value)
      end

      # Complex types and type definitions respond to "match?(value:)".
      def complex_type?(expression:)
        Low::Types::COMPLEX_TYPES.include?(expression) || typed_definition?(expression:)
      end

      # A parameterized type such as "Status[200]" or "Enum[:a, :b]".
      def typed_definition?(expression:)
        expression.is_a?(Low::TypeDefinition)
      end

      private

      def basic_type?(expression:)
        expression.instance_of?(Class)
      end

      def typed_hash?(expression:)
        expression.is_a?(Hash) && basic_type?(expression: expression.keys.first) && basic_type?(expression: expression.values.first)
      end
    end
  end
end
