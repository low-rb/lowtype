# frozen_string_literal: true

require_relative '../expressions/value_expression'
require_relative '../definitions/evaluator'

module Low
  # Redefine methods to have their arguments and return values type checked.
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
  #      │              │                 │ Evaluates       │               │
  #      │              │                 │◄────────────────┤               │
  #      │              │                 │                 │               │
  #      │              │                 │                 │ Redefines <-- YOU ARE HERE.
  #      │              │                 │                 ├──────────────►│
  #      │              │                 │                 │               │
  #      │              │                 │ Validates       │               │
  #      │              │                 │◄┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┤
  #      │              │                 │                 │               │
  class Redefiner
    class << self
      # TODO: Pass in "klass" and use it to class_eval/eval methods in the binding of the class that included LowType.
      def redefine(method_proxies:, class_proxy:)
        if LowType.config.type_checking
          typed_methods(method_proxies:, class_proxy:)
        else
          untyped_methods(method_proxies:, class_proxy:)
        end
      end

      def untyped_args(args:, kwargs:, method_proxy:) # rubocop:disable Metrics/AbcSize
        method_proxy.params_with_expressions.each do |param_proxy|
          positional = %i[pos_req pos_opt].include?(param_proxy.type)

          value = positional ? args[param_proxy.position] : kwargs[param_proxy.name]

          next unless value.nil?
          raise param_proxy.error_type, param_proxy.error_message(value:) if param_proxy.expression.required?

          value = param_proxy.expression.default_value # Default value can still be `nil`.
          value = value.value if value.is_a?(ValueExpression)
          positional ? args[param_proxy.position] = value : kwargs[param_proxy.name] = value
        end

        [args, kwargs]
      end

      private

      def typed_methods(method_proxies:, class_proxy:) # rubocop:disable Metrics
        Module.new do
          method_proxies.values.filter(&:expressions?).each do |method_proxy|
            define_method(method_proxy.name) do |*args, **kwargs|
              method_proxy.params_with_expressions.each do |param_proxy|
                positional = %i[pos_req pos_opt].include?(param_proxy.type)

                value = positional ? args[param_proxy.position] : kwargs[param_proxy.name]
                value = param_proxy.expression.default_value if value.nil? && !param_proxy.expression.required?

                param_proxy.expression.validate!(value:, proxy: param_proxy)
                value = value.value if value.is_a?(ValueExpression)

                positional ? args[param_proxy.position] = value : kwargs[param_proxy.name] = value
              end

              if (return_proxy = method_proxy.return_proxy)
                return_value = super(*args, **kwargs)
                return_proxy.expression.validate!(value: return_value, proxy: return_proxy)
                return return_value
              end

              super(*args, **kwargs)
            end

            private method_proxy.name if class_proxy.private_start_line && method_proxy.start_line > class_proxy.private_start_line
          end
        end
      end

      def untyped_methods(method_proxies:, class_proxy:)
        Module.new do
          method_proxies.values.filter(&:expressions?).each do |method_proxy|
            # You are now in the binding of the includer class.
            define_method(method_proxy.name) do |*args, **kwargs|
              # NOTE: Type checking is currently disabled. See 'config.type_checking'.
              method_proxy = Lowkey[class_proxy.file_path][class_proxy.namespace][__method__]

              args, kwargs = Low::Redefiner.untyped_args(args:, kwargs:, method_proxy:)
              super(*args, **kwargs)
            end

            private method_proxy.name if class_proxy.private_start_line && method_proxy.start_line > class_proxy.private_start_line
          end
        end
      end
    end
  end
end
