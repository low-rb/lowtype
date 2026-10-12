# frozen_string_literal: true

require_relative '../../types/complex_types'

module LowType
  module CLI
    module RBS
      module TypeMapper
        COMPLEX_TYPE_MAP = {
          Low::Types::Boolean => 'bool',
          Low::Types::HTML => 'String',
          Low::Types::JSON => 'String',
          Low::Types::XML => 'String',
          Low::Types::Status => 'Integer',
          Low::Types::Headers => 'Hash[String, untyped]',
          Low::Types::Tuple => 'Array[untyped]'
        }.freeze

        class << self
          def map(type)
            return 'nil' if type == NilClass
            return 'bool' if [TrueClass, FalseClass].include?(type)
            return COMPLEX_TYPE_MAP[type] if COMPLEX_TYPE_MAP.key?(type)

            case type
            when ::Low::TypeExpression then map_expression(type)
            when Array then map_array(type)
            when Hash then map_hash(type)
            when Class then map_class(type)
            else 'untyped'
            end
          end

          private

          # A nested type expressio like "String | Integer" inside "Array[String | Integer]".
          def map_expression(expression)
            require_relative 'expression_mapper'
            ExpressionMapper.match(expression)
          end

          # When [T] then every element is type T. When [X, Y, Z] then each element is that type at that position.
          def map_array(type)
            return 'Array[untyped]' if type.empty?
            return "[#{type.map { |subtype| map(subtype) }.join(', ')}]" if type.length > 1

            "Array[#{map(type.first)}]"
          end

          def map_hash(type)
            return 'Hash[untyped, untyped]' if type.empty?

            "Hash[#{map(type.keys.first)}, #{map(type.values.first)}]"
          end

          def map_class(type)
            return 'untyped' if type.name.nil?

            "::#{type.name}"
          end
        end
      end
    end
  end
end
