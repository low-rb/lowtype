# frozen_string_literal: true

require_relative 'error_types'
require_relative 'type_definition'
require_relative '../expressions/type_errors'

module Low
  module Types
    # A hash with named keys, each with its own type, like "Schema[id: Integer, email: String | nil]".
    # A key whose type allows nil may be missing. Keys the schema doesn't name are allowed.
    # A nested hash of named keys is a nested schema, like "Schema[address: { city: String }]".
    class Schema
      def self.[](fields)
        Definition.new(fields:)
      end

      class Definition
        include TypeDefinition

        attr_reader :fields

        def initialize(fields:)
          raise AllowedTypeError, 'Schema requires at least one key' if fields.empty?

          @fields = fields.transform_values { |type| schema?(type) ? Definition.new(fields: type) : type }.freeze
        end

        def match?(value:)
          errors(value).empty?
        end

        def errors(value)
          TypeErrors.error_nodes(type: self, value:)
        end

        def display_name
          "Schema[#{@fields.map { |key, type| "#{key}: #{TypeErrors.display(type)}" }.join(', ')}]"
        end

        def ==(other)
          other.class == self.class && other.fields == @fields
        end

        def eql?(other)
          self == other
        end

        def hash
          [self.class, @fields].hash
        end

        private

        # A hash with class keys, like "{ String => Integer }", is a typed hash rather than a schema.
        def schema?(type)
          type.is_a?(::Hash) && !type.empty? && type.keys.none? { |key| key.instance_of?(Class) }
        end
      end
    end
  end
end
