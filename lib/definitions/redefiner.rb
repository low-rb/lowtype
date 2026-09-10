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
      #
      # ractor_safe: false (default) defines methods via define_method blocks, closing over
      # method_proxy directly -- fast, but the resulting method is backed by a Proc, and Ruby
      # refuses to call a Proc-backed method from any Ractor other than the one that defined
      # it, even with zero closure captures and even if everything captured is frozen. true
      # instead compiles each method from a source string via class_eval, producing a real
      # method with no Ractor affinity, at the cost of re-deriving method_proxy from Lowkey's
      # registry on every call instead of closing over it once. Only useful once that registry
      # has actually been made shareable (see Lowkey.make_shareable!) -- opt in per class via
      # `ractor_safe!`, not globally, since most classes never run inside a worker Ractor and
      # shouldn't pay for a per-call registry lookup they don't need.
      def redefine(method_proxies:, class_proxy:, ractor_safe: false)
        if LowType.config.type_checking
          typed_methods(method_proxies:, class_proxy:, ractor_safe:)
        else
          untyped_methods(method_proxies:, class_proxy:, ractor_safe:)
        end
      end

      def untyped_args(args:, kwargs:, method_proxy:) # rubocop:disable Metrics/AbcSize
        method_proxy.params_with_expressions.each do |param_proxy|
          value = param_proxy.position ? args[param_proxy.position] : kwargs[param_proxy.name]

          next unless value.nil?
          raise param_proxy.error_type, param_proxy.error_message(value:) if param_proxy.expression.required?

          value = param_proxy.expression.default_value # Default value can still be `nil`.
          value = value.value if value.is_a?(ValueExpression)
          param_proxy.position ? args[param_proxy.position] = value : kwargs[param_proxy.name] = value
        end

        [args, kwargs]
      end

      private

      def typed_methods(method_proxies:, class_proxy:, ractor_safe: false) # rubocop:disable Metrics
        Module.new do
          method_proxies.values.filter(&:expressions?).each do |method_proxy|
            if ractor_safe
              Low::Redefiner.define_ractor_safe_typed_method(mod: self, method_proxy:, class_proxy:)
            else
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
            end

            private method_proxy.name if class_proxy.private_start_line && method_proxy.start_line > class_proxy.private_start_line
          end
        end
      end

      def untyped_methods(method_proxies:, class_proxy:, ractor_safe: false) # rubocop:disable Metrics/AbcSize
        Module.new do
          method_proxies.values.filter(&:expressions?).each do |method_proxy|
            if ractor_safe
              Low::Redefiner.define_ractor_safe_untyped_method(mod: self, method_proxy:, class_proxy:)
            else
              # You are now in the binding of the includer class.
              define_method(method_proxy.name) do |*args, **kwargs|
                # NOTE: Type checking is currently disabled. See 'config.type_checking'.
                method_proxy = Lowkey[class_proxy.file_path][class_proxy.namespace][__method__]

                args, kwargs = Low::Redefiner.untyped_args(args:, kwargs:, method_proxy:)
                super(*args, **kwargs)
              end
            end

            private method_proxy.name if class_proxy.private_start_line && method_proxy.start_line > class_proxy.private_start_line
          end
        end
      end

      public

      # Compiled from a source string (not define_method) so the result is a real method with
      # no Ractor affinity -- see the comment on .redefine. method_proxy is re-derived from
      # Lowkey's registry every call rather than closed over, since a string can't capture a
      # local variable the way a block can.
      # rubocop:disable Style/EvalWithLocation -- attributing these to the fixture/app's own
      # file and line, not redefiner.rb's __FILE__, is the point: it's what makes a
      # validation error's backtrace point at the user's actual method definition.
      def define_ractor_safe_typed_method(mod:, method_proxy:, class_proxy:)
        mod.class_eval(<<~RUBY, class_proxy.file_path, method_proxy.start_line)
          def #{method_proxy.name}(*args, **kwargs)
            method_proxy = Lowkey[#{class_proxy.file_path.inspect}][#{class_proxy.namespace.inspect}][__method__]

            method_proxy.params_with_expressions.each do |param_proxy|
              positional = %i[pos_req pos_opt].include?(param_proxy.type)

              value = positional ? args[param_proxy.position] : kwargs[param_proxy.name]
              value = param_proxy.expression.default_value if value.nil? && !param_proxy.expression.required?

              param_proxy.expression.validate!(value:, proxy: param_proxy)
              value = value.value if value.is_a?(Low::ValueExpression)

              positional ? args[param_proxy.position] = value : kwargs[param_proxy.name] = value
            end

            if (return_proxy = method_proxy.return_proxy)
              return_value = super(*args, **kwargs)
              return_proxy.expression.validate!(value: return_value, proxy: return_proxy)
              return return_value
            end

            super(*args, **kwargs)
          end
        RUBY
      end

      def define_ractor_safe_untyped_method(mod:, method_proxy:, class_proxy:)
        mod.class_eval(<<~RUBY, class_proxy.file_path, method_proxy.start_line)
          def #{method_proxy.name}(*args, **kwargs)
            method_proxy = Lowkey[#{class_proxy.file_path.inspect}][#{class_proxy.namespace.inspect}][__method__]

            args, kwargs = Low::Redefiner.untyped_args(args:, kwargs:, method_proxy:)
            super(*args, **kwargs)
          end
        RUBY
      end
      # rubocop:enable Style/EvalWithLocation
    end
  end
end
