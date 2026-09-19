# frozen_string_literal: true

require_relative 'expression_mapper'

module LowType
  module CLI
    module RBS
      # Builds an RBS method signature line from a Lowkey::MethodProxy.
      # TODO: Support positional args, keyword args and blocks.
      module MethodSig
        POSITIONAL_TYPES = %i[pos_req pos_opt].freeze
        KEYWORD_TYPES = %i[key_req key_opt].freeze

        class << self
          def build(method_proxy:, class_method: false)
            scope = class_method ? 'self.' : ''
            "def #{scope}#{method_proxy.name}: (#{params(method_proxy)}) -> #{return_type(method_proxy)}"
          end

          private

          def params(method_proxy)
            positional = method_proxy.params.select { |param| POSITIONAL_TYPES.include?(param.type) }
            keyword = method_proxy.params.select { |param| KEYWORD_TYPES.include?(param.type) }

            (positional.map { |param| positional_fragment(param) } + keyword.map { |param| keyword_fragment(param) }).join(', ')
          end

          def positional_fragment(param_proxy)
            type = ExpressionMapper.map(param_proxy.expression)
            optional?(param_proxy) ? "?#{type} #{param_proxy.name}" : "#{type} #{param_proxy.name}"
          end

          def keyword_fragment(param_proxy)
            type = ExpressionMapper.map(param_proxy.expression)
            optional?(param_proxy) ? "?#{param_proxy.name}: #{type}" : "#{param_proxy.name}: #{type}"
          end

          def optional?(param_proxy)
            return !param_proxy.expression.required? if param_proxy.expression

            %i[pos_opt key_opt].include?(param_proxy.type)
          end

          def return_type(method_proxy)
            ExpressionMapper.map(method_proxy.return_proxy&.expression)
          end
        end
      end
    end
  end
end
