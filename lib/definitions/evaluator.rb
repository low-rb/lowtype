# frozen_string_literal: true

require 'expressions'
require 'lowkey'

require_relative '../expressions/expression_helpers'
require_relative '../expressions/type_expression'
require_relative '../syntax/syntax'
require_relative '../types/complex_types'
require_relative '../types/status'

module Low
  # Evaluate code stored in strings into constants and values.
  # ┌────────┐     ┌─────────┐     ┌─────────────┐     ┌─────────┐     ┌─────────┐
  # │ Lowkey │     │ Proxies │     │ Expressions │     │ LowType │     │ Methods │
  # └────┬───┘     └────┬────┘     └──────┬──────┘     └────┬────┘     └────┬────┘
  #      │              │                 │                 │               │
  #      │ Parses AST   │                 │                 │               │
  #      ├─────────────►│                 │                 │               │
  #      │              │                 │                 │               │
  #      │              │ Stores          │                 │               │
  #      │              ├────────────────►│                 │               │
  #      │              │                 │                 │               │
  #      │              │                 │ Evaluates <-- YOU ARE HERE.     |
  #      │              │                 │◄────────────────┤               │
  #      │              │                 │                 │               │
  #      │              │                 │                 │ Redefines     │
  #      │              │                 │                 ├──────────────►│
  #      │              │                 │                 │               │
  #      │              │                 │ Validates       │               │
  #      │              │                 │◄┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┤
  #      │              │                 │                 │               │
  class Evaluator
    include ExpressionHelpers
    include Types
    using LowType::Syntax

    def low_evaluate(proxy:)
      # Not a security risk because the code comes from a trusted source; the file that included lowtype.
      eval(proxy.value, binding, proxy.file_path, proxy.start_line) # rubocop:disable Security/Eval
    end

    def class_evaluate(proxy:, class_binding:)
      # Not a security risk because the code comes from a trusted source; the file that included lowtype.
      eval(proxy.value, class_binding, proxy.file_path, proxy.start_line) # rubocop:disable Security/Eval
    end

    class << self
      def evaluate(method_proxies:, class_binding: nil)
        require_relative '../syntax/union_types' if LowType.config.union_type_expressions

        method_proxies.each_value do |method_proxy|
          evaluate_param_proxy_expressions(method_proxy:, class_binding:)
          evaluate_return_proxy_expression(return_proxy: method_proxy.return_proxy) if method_proxy.return_proxy
        end
      end

      def evaluate_param_proxy_expressions(method_proxy:, class_binding: nil)
        begin # rubocop:disable Style/RedundantBegin
          method_proxy.tagged_params(:value).each do |param_proxy|
            expression = begin
              new.low_evaluate(proxy: param_proxy)
            rescue NameError
              raise unless class_binding

              new.class_evaluate(proxy: param_proxy, class_binding:)
            end
            param_proxy.expression = cast_type_expression(expression:, param_proxy:)

            polyfill_default(param_proxy:)
            validate_default!(param_proxy:)
          end
        rescue NameError => e
          mp = method_proxy
          raise NameError, "Unknown type '#{e.name}' for #{mp.scope} at #{mp.file_path}:#{mp.start_line}"
        end
      end

      def evaluate_return_proxy_expression(return_proxy:)
        begin
          expression = new.low_evaluate(proxy: return_proxy)
        rescue NameError
          rp = return_proxy
          raise NameError, "Unknown return type '#{rp.value}' for #{rp.scope} at #{rp.file_path}:#{rp.start_line}"
        end

        expression = TypeExpression.new(type: expression) unless expression.is_a?(TypeExpression)

        return_proxy.expression = expression
      end

      private

      def cast_type_expression(expression:, param_proxy:)
        if expression.is_a?(::Expressions::Expression)
          return expression
        elsif expression.instance_of?(Class) && expression.name == 'Low::Dependency'
          return expression.new(provider_key: param_proxy.name)
        elsif TypeQuery.type?(expression)
          return TypeExpression.new(type: expression)
        end

        nil
      end

      def polyfill_default(param_proxy:)
        expression = param_proxy.expression

        case expression.class.name
        when 'Low::Dependency'
          # Remap dependency expression to providers hash lookup method.
          param_proxy.default = "Providers[#{expression.provider_key.inspect}]"
        end
      end

      # Fail early on class load rather than on method call.
      def validate_default!(param_proxy:)
        expression = param_proxy.expression
        return unless expression.is_a?(TypeExpression) && !expression.required?

        # When an enum's default value isn't an allowed value.
        if expression.types.any? { |type| type.is_a?(Types::Enum::Definition) }
          expression.validate!(value: expression.default_value, proxy: param_proxy)
        end
      rescue ArgumentError
        raise AllowedTypeError, "Invalid default value #{expression.display_default} for parameter '#{param_proxy.name}' " \
                                "at #{param_proxy.file_path}:#{param_proxy.start_line}. Valid types: '#{expression.valid_types}'"
      end
    end
  end
end
