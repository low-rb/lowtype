# frozen_string_literal: true

require 'expressions'

require_relative 'value_expression'
require_relative '../proxies/param_proxy'
require_relative '../queries/type_query'

module Low
  root_path = File.expand_path(__dir__)
  adapter_paths = Dir.chdir(root_path) { Dir.glob('adapters/*') }.map { |path| File.join(root_path, path) }
  module_paths = %w[expressions/expressions instance_types redefiner].map { |path| File.join(root_path, "#{path}.rb") }

  HIDDEN_PATHS = [File.expand_path(__FILE__), *adapter_paths, *module_paths].freeze

  # Represent types and default values as a series of chainable expressions.
  class TypeExpression < ::Expressions::Expression
    attr_reader :types, :default_value

    # @param type - A literal type or an instance representation of a typed structure.
    def initialize(type: nil, default_value: :LOWTYPE_UNDEFINED)
      @types = []
      @types << type unless type.nil?
      @default_value = default_value
      # TODO: Override per type expression with a config expression.
      @deep_type_check = nil
    end

    def required?
      @default_value == :LOWTYPE_UNDEFINED
    end

    # TODO: Might need to accept error class here so that type accessors can be disabled and supply ArgumentError.
    def validate!(value:, proxy:) # rubocop:disable Metrics
      if value.nil?
        return true if @default_value.nil?
        raise proxy.error_type, proxy.error_message(value:) if required?
      end

      @types.each do |type|
        return true if type_matches_value?(type:, value:, proxy:)
        return true if type.is_a?(Array) && value.is_a?(Array) && array_types_match_values?(types: type, values: value, proxy:)
        return true if type.is_a?(Hash) && value.is_a?(Hash) && hash_types_match_values?(types: type, values: value)
      end

      raise proxy.error_type, proxy.error_message(value:)
    rescue proxy.error_type => e
      raise proxy.error_type, e.message, proxy.backtrace(backtrace: e.backtrace, hidden_paths: HIDDEN_PATHS)
    end

    def valid_types
      types = @types.map do |type|
        if type.is_a?(Array)
          "[#{type.map { |subtype| valid_subtype(subtype:) }.join(', ')}]"
        else
          type.inspect.to_s.delete_prefix('Low::Types::')
        end
      end

      types << 'nil' if @default_value.nil?
      types.join(' | ')
    end

    private

    def union_expression(expression)
      @types += expression.types
      @default_value = expression.default_value
    end

    def union_type(type)
      @types << type
    end

    def union_value(value)
      @default_value = value
    end

    # Override Expressions as LowType supports complex types which are implemented as values.
    def value?(expression)
      TypeQuery.value?(expression) || expression.nil?
    end

    def valid_subtype(subtype:)
      if subtype.is_a?(TypeExpression)
        types = subtype.types
        types << 'nil' if subtype.default_value.nil?
        types.join(' | ')
      else
        subtype.to_s.delete_prefix('Low::Types::')
      end
    end

    def array_types_match_values?(types:, values:, proxy:)
      # [X, Y, Z] An arbitrary amount of elements are arbitrary types in an arbitrary order.
      if types.length > 1
        return multiple_types_match_values?(types:, values:, proxy:)
      # [T] All elements are the same type.
      elsif types.length == 1
        return single_type_matches_values?(type: types.first, values:, proxy:)
      end

      # [] Misconfigured empty Array[] type.
      true
    end

    def multiple_types_match_values?(types:, values:, proxy:)
      types.each_with_index do |type, index|
        return false unless type_matches_value?(type:, value: values[index], proxy:)
      end

      true
    end

    def single_type_matches_values?(type:, values:, proxy:)
      # [V, ...] Type check all elements.
      if deep_type_check?
        return false if values.any? { |value| !type_matches_value?(type:, value:, proxy:) }
      # [V] Type check the first element.
      else
        return false unless type_matches_value?(type:, value: values.first, proxy:)
      end

      true
    end

    def hash_types_match_values?(types:, values:)
      return true if values.empty? && empty_hash_default_value?
      return values.empty? if types.empty?
      return false if values.empty?

      # TODO: Shallow validation of hash could be made deeper with user config.
      types.keys[0] == values.keys[0].class && types.values[0] == values.values[0].class
    end

    def type_matches_value?(type:, value:, proxy:)
      if type.instance_of?(Class)
        return type.match?(value:) if Low::TypeQuery.complex_type?(expression: type)
        return value.value <= type if value.instance_of?(ValueExpression)

        return value.is_a?(type)
      elsif type.instance_of?(Low::TypeExpression)
        type.validate!(value:, proxy:)
        return true
      end

      false
    end

    def deep_type_check?
      return @deep_type_check unless @deep_type_check.nil?

      LowType.config.deep_type_check
    end

    def empty_hash_default_value?
      @default_value.is_a?(Hash) && @default_value.empty?
    end
  end
end
