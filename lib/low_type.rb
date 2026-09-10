# frozen_string_literal: true

require 'lowkey'

require_relative 'adapters/adapter_loader'
require_relative 'definitions/ractor_safety'
require_relative 'definitions/redefiner'
require_relative 'definitions/type_accessors'
require_relative 'expressions/expression_helpers'
require_relative 'queries/file_query'
require_relative 'syntax/syntax'
require_relative 'types/complex_types'

# Architecture:
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
#      │              │                 │                 │ Redefines     │
#      │              │                 │                 ├──────────────►│
#      │              │                 │                 │               │
#      │              │                 │ Validates       │               │
#      │              │                 │◄┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┤
#      │              │                 │                 │               │
module LowType
  # Defers evaluation and redefinition until after the class body finishes loading via TracePoint :end.
  def self.included(klass)
    file_path = Low::FileQuery.file_path(klass:)
    file_proxy = Lowkey.load(file_path)
    class_proxy = file_proxy[klass.name]

    klass.include Low::ExpressionHelpers
    klass.extend Low::ExpressionHelpers
    klass.extend Low::TypeAccessors
    klass.extend Low::Types
    klass.extend Low::RactorSafety

    # Use TracePoint :end to capture the class binding after the class body finishes loading.
    # At :end time, trace.self is the including class and trace.binding is the class body's binding,
    # stored on class_proxy.class_binding for use by LowType and other consumers.
    tp = TracePoint.new(:end) do |trace|
      next unless trace.self == klass

      class_proxy.class_binding = trace.binding

      Low::Evaluator.evaluate(method_proxies: class_proxy.keyed_methods, class_binding: class_proxy.class_binding)

      ractor_safe = klass.ractor_safe?
      klass.prepend Low::Redefiner.redefine(method_proxies: class_proxy.instance_methods, class_proxy:, ractor_safe:)
      klass.singleton_class.prepend Low::Redefiner.redefine(method_proxies: class_proxy.class_methods, class_proxy:, ractor_safe:)

      Low::Adapter::Loader.load(klass:, class_proxy:)

      tp.disable
    end

    tp.enable
  end

  Config = Struct.new(
    :type_checking,
    :error_mode,
    :output_mode,
    :output_size,
    :deep_type_check,
    :union_type_expressions
  )

  class << self
    def config
      @config ||= Config.new(true, :error, :type, 100, true, true)
    end

    def configure
      yield(config)
    end
  end
end
