# frozen_string_literal: true

require_relative 'type_mapper'

module LowType
  module CLI
    module RBS
      # Maps a TypeExpression to an RBS type.
      module ExpressionMapper
        class << self
          def match(expression)
            return 'untyped' if expression.nil?

            types = expression.types.map { |type| TypeMapper.map(type) }.uniq
            types = ['untyped'] if types.empty?

            union = types.join(' | ')
            nilable?(expression) ? nilable(union:, multiple: types.length > 1) : union
          end

          private

          def nilable?(expression)
            expression.default_value.nil?
          end

          def nilable(union:, multiple:)
            multiple ? "(#{union})?" : "#{union}?"
          end
        end
      end
    end
  end
end
