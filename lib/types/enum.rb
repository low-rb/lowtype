# frozen_string_literal: true

require 'set'
require_relative 'error_types'

module Low
  module Types
    class Enum
      # Holds the normalized enum definition and provides validation logic.
      class Definition
        def initialize(values:, strict:)
          @strict = strict
          @ordered = normalize_values(values)
          @allowed = Set.new(@ordered)

          validate!
        end

        # @return [Boolean]
        def match?(value:)
          @allowed.include?(value)
        end

        def valid?(value)
          match?(value: value)
        end

        def expected_values
          @ordered
        end

        def error_message_for(value:)
          "Expected one of #{expected_values.inspect}, got #{value.inspect}"
        end

        def inspect
          core = "Low::Types::Enum[#{expected_values.map(&:inspect).join(', ')}]"
          return core unless @strict

          "#{core}{strict: true}"
        end

        private

        def normalize_values(values)
          # Preserve first-seen order but ensure uniqueness.
          values.each_with_object([]) { |v, acc| acc << v unless acc.include?(v) }
        end

        def validate!
          return unless @strict && @allowed.empty?

          raise Low::ConfigError, 'Enum[...] cannot be empty in strict mode'
        end
      end

      # Creates an Enum type class that responds to `.match?(value:)` so it can be used by LowType.
      #
      # @example
      #   type = Low::Types::Enum[:draft, :published]
      #   type.match?(value: :draft) # => true
      def self.[](*values, strict: false)
        definition = Definition.new(values: values, strict: strict)
        build_enum_type(definition)
      end

      # Convenience helper for symbol-only enums.
      def self.symbols(*symbols, strict: false)
        non_symbols = symbols.reject { |v| v.is_a?(Symbol) }
        return self[*symbols, strict: strict] if non_symbols.empty?

        raise Low::ConfigError, "Enum.symbols expects only symbols, got #{non_symbols.map(&:inspect).join(', ')}"
      end

      private_class_method

      def self.build_enum_type(definition)
        Class.new do
          include Low::Types::MatchableType

          @definition = definition

          def self.match?(value:)
            @definition.match?(value: value)
          end

          def self.valid?(value)
            @definition.valid?(value)
          end

          def self.error_message_for(value:)
            @definition.error_message_for(value: value)
          end

          def self.expected_values
            @definition.expected_values
          end

          def self.inspect
            @definition.inspect
          end
        end
      end
    end
  end
end

