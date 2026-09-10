# frozen_string_literal: true

module Low
  module Types
    class Boolean
      include Low::Types::MatchableType

      # LowType calls `.match?(value:)` for complex types.
      def self.match?(value:)
        value.equal?(true) || value.equal?(false)
      end

      # Optional helper for external call sites.
      def self.valid?(value)
        match?(value: value)
      end

      def self.error_message_for(value:)
        "Expected true/false, got #{value.inspect}"
      end

      def self.inspect
        'Low::Types::Boolean'
      end
    end
  end
end

