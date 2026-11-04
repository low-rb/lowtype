# frozen_string_literal: true

module Low
  # Checks a JSON/Hash and returns every place a value doesn't match a type.
  module TypeErrors
    module_function

    # A value in the data and the type it should be. error_nodes returns the ones that don't match.
    SchemaNode = Data.define(
      :path, # A nested path: 'address.postcode' or 'ids[2]'
      :type, # The type the value should be: String | nil
      :value # The value at that path: 42
    ) do
      # The type for a message: 'String | nil'
      def expected = TypeErrors.expected(type)

      # The value for a message: '42'
      def received = TypeErrors.value_received(value)
    end

    # @returns: Array of SchemaNode objects with errors
    def error_nodes(type:, value:, path: '')
      check(SchemaNode.new(path:, type:, value:))
    end

    # The node itself when it doesn't match, or the error nodes inside it when it does.
    def check(node)
      return check_expression(node) if node.type.is_a?(TypeExpression)
      return child_nodes(node).flat_map { |child| check(child) } if outer_match?(node)

      [node]
    end

    # 1. Matching any one of the types is enough
    # 2. If none match, the errors are the ones inside the first type the value matches on the outside, like a bad hash value in a Schema.
    # 3. If none match even on the outside, the node itself is the error.
    def check_expression(node)
      return [] if node.value.nil? && node.type.optional?

      matched = node.type.types.map { |type| node.with(type:) }.select { |option| outer_match?(option) }
      return [node] if matched.empty?

      results = matched.map { |option| check(option) }
      results.find(&:empty?) || results.first
    end

    # A Schema or { K => V } needs a Hash, and [T] an Array. Any other type matches the value as a whole.
    def outer_match?(node)
      node => { type:, value: }

      case type
      when Types::Schema::Definition, ::Hash then value.is_a?(::Hash)
      when ::Array then value.is_a?(::Array)
      else
        return type.match?(value:) if TypeQuery.complex_type?(expression: type)

        type.is_a?(Module) && value.is_a?(type)
      end
    end

    # A SchemaNode for each value inside a value:
    #   Schema[id: T] - Each field, where a missing key is nil
    #   [T]           - Each element is the same type
    #   [X, Y]        - Each element at that position is that type
    #   { K => V }    - Every key and value
    def child_nodes(node)
      node => { path:, type:, value: }

      case type
      when Types::Schema::Definition
        type.fields.map { |key, field_type| SchemaNode.new(path: join(path, key), type: field_type, value: field(value, key)) }
      when ::Array
        element_types(type, value).each_with_index.map do |element_type, index|
          SchemaNode.new(path: "#{path}[#{index}]", type: element_type, value: value[index])
        end
      when ::Hash
        key_type, value_type = type.first
        value.flat_map do |key, element|
          key_path = join(path, key)
          [SchemaNode.new(path: key_path, type: key_type, value: key), SchemaNode.new(path: key_path, type: value_type, value: element)]
        end
      else []
      end
    end

    def element_types(types, value)
      return Array.new(value.length, types.first) if types.one?

      types
    end

    # Keys can be strings, like parsed JSON's, or symbols.
    def field(value, key)
      return value[key] if value.key?(key)
      return value[key.to_s] if key.is_a?(Symbol)

      value[key.to_s.to_sym]
    end

    def join(path, key)
      return key.to_s if path.empty?

      "#{path}.#{key}"
    end

    # A schema's full definition is too long to read in a message, and the value isn't even a Hash.
    def expected(type)
      return 'Hash' if type.is_a?(Types::Schema::Definition)

      display(type)
    end

    def display(type)
      return type.valid_types if type.is_a?(TypeExpression)

      TypeExpression.new(type:).valid_types
    end

    def value_received(value)
      case value
      when ::Hash then 'Hash'
      when ::Array then 'Array'
      else trim(value.inspect)
      end
    end

    def trim(text)
      return text if text.length <= 40

      "#{text[0, 37]}..."
    end
  end
end
