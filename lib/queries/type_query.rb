# frozen_string_literal: true

require_relative '../expressions/type_expression'

module Low
  # TODO: Unit test.
  class TypeQuery
    class << self
      def type?(expression)
        basic_type?(expression:) || complex_type?(expression:)
      end

      def typed_array?(expression:)
        expression.is_a?(Array) && (basic_type?(expression: expression.first) || expression.first.is_a?(TypeExpression))
      end

      def value?(value)
        !basic_type?(expression: value) && !complex_type?(expression: value)
      end

      def complex_type?(expression:)
        Low::Types::COMPLEX_TYPES.include?(expression) ||
          matchable_type?(expression:) ||
          typed_array?(expression:) ||
          typed_hash?(expression:)
      end

      private

      def basic_type?(expression:)
        expression.instance_of?(Class)
      end

      def matchable_type?(expression:)
        expression.is_a?(Class) &&
          expression.respond_to?(:match?) &&
          expression.ancestors.include?(Low::Types::MatchableType)
      end

      def typed_hash?(expression:)
        expression.is_a?(Hash) && basic_type?(expression: expression.keys.first) && basic_type?(expression: expression.values.first)
      end
    end
  end
end
