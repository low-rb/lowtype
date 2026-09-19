# frozen_string_literal: true

require 'lowkey'

require_relative 'method_sig'

module LowType
  module CLI
    module RBS
      module ClassSig
        class << self
          def build(class_proxy:, file_proxy:)
            body = method_lines(class_proxy)
            wrap_namespace(namespace: class_proxy.namespace, name: class_proxy.name, body:, file_proxy:).join("\n")
          end

          private

          def method_lines(class_proxy)
            instance_lines = class_proxy.instance_methods.each_value.map do |method_proxy|
              MethodSig.build(method_proxy:)
            end

            class_lines = class_proxy.class_methods.each_value.map do |method_proxy|
              MethodSig.build(method_proxy:, class_method: true)
            end

            instance_lines + class_lines
          end

          def wrap_namespace(namespace:, name:, body:, file_proxy:)
            lines = wrap("class #{name}", body)

            segments(namespace).reverse_each do |segment|
              lines = wrap("#{namespace_type(segment:, file_proxy:)} #{segment}", lines)
            end

            lines
          end

          def wrap(header, body_lines)
            [header, *body_lines.map { |line| "  #{line}" }, 'end']
          end

          # Lowkey's "namespace" includes the class's own name.
          def segments(namespace)
            namespace.split('::')[0..-2]
          end

          def namespace_type(segment:, file_proxy:)
            file_proxy.definitions[segment].is_a?(::Lowkey::ClassProxy) ? 'class' : 'module'
          end
        end
      end
    end
  end
end
