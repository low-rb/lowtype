# frozen_string_literal: true

require 'lowkey'
require 'prism'

require_relative '../expressions/type_expression'
require_relative '../types/complex_types'
require_relative '../types/error_types'

module Low
  # Builds a type expression from text like "String | nil" or "Array[Enum['admin', 'member']]", for types read from files.
  # Ruby parses the text and looks up its constants, but it's never run: only constants, values, "|", "{}" and "[]"
  # on the types below are allowed, since "[]" on other constants can do anything, like Dir['*'] or ENV['KEY'].
  # A value in the union is the default, like "String | 'Hello'", and nil makes the type optional.
  class TypeParser
    # The types allowed before "[]", and how they read what's inside: types, like Array[String], or values, like Enum[:a, :b].
    BRACKETS = { Array => :typed_array, Hash => :typed_hash, Types::Schema => :schema, Types::Enum => :values,
                 Types::Status => :values }.freeze

    # Constants are looked up in the namespace, then in Object. A namespace can hold schemas, like User,
    # and include Low::Types for Boolean, Enum and Schema.
    def self.parse(text, namespace: Types)
      new(text, namespace:).parse
    end

    def initialize(text, namespace: Types)
      @text = text
      @namespace = namespace
    end

    def parse
      result = Prism.parse(@text)
      raise_error(result.errors.first.message, result.errors.first.location) if result.errors.any?

      statements = result.value.statements.body
      raise_error('Expected one type', result.value.location) unless statements.one?

      expression(statements.first)
    end

    private

    # Terms between pipes: types, or values for the default.
    def expression(node)
      types = []
      default_value = :LOWTYPE_UNDEFINED

      terms(node).each do |term|
        Lowkey::ValueParser.value?(term) ? default_value = value(term) : types << type(term)
      end

      TypeExpression.new(default_value:).tap { |expression| expression.types.concat(types) }
    end

    def terms(node)
      return terms(node.body.body.first) if node.is_a?(Prism::ParenthesesNode) && node.body&.body&.one?
      return [node] unless call?(node, :|) && node.receiver

      [node.receiver, *arguments(node)].flat_map { |term| terms(term) }
    end

    def type(node)
      case node
      when Prism::ConstantReadNode, Prism::ConstantPathNode then constant(node)
      when Prism::HashNode then Types::Schema[fields(node.elements)]
      when Prism::CallNode then brackets(node)
      else raise_error("'#{node.slice}' isn't a type", node.location)
      end
    end

    def brackets(node)
      reader = BRACKETS[type(node.receiver)] if call?(node, :[]) && node.receiver
      raise_error("'#{node.slice}' isn't allowed in a type", node.location) unless reader

      send(reader, node, arguments(node))
    end

    def typed_array(_node, arguments)
      arguments.map { |argument| element(argument) }
    end

    def typed_hash(node, arguments)
      hash = fields(arguments.flat_map { |argument| pairs(argument) })
      raise_error("Expected 'Hash[K => V]'", node.location) unless hash.one? && hash.keys.first.instance_of?(Class)

      hash
    end

    def schema(node, arguments)
      fields = fields(arguments.flat_map { |argument| pairs(argument) })
      names = fields.keys.all? { |key| key.is_a?(String) || key.is_a?(Symbol) }
      raise_error('Schema keys are names, not types', node.location) unless fields.any? && names

      Types::Schema[fields]
    end

    def values(node, arguments)
      type(node.receiver)[*arguments.map { |argument| value(argument) }]
    end

    def arguments(node)
      node.arguments&.arguments || []
    end

    def pairs(argument)
      argument.is_a?(Prism::KeywordHashNode) ? argument.elements : [argument]
    end

    # Pairs like "id: Integer", "'id' => Integer" or "String => Integer", where a nested hash is a nested schema.
    def fields(pairs)
      pairs.to_h do |pair|
        raise_error("'#{pair.slice}' isn't a key and type", pair.location) unless pair.is_a?(Prism::AssocNode)

        [Lowkey::ValueParser.value?(pair.key) ? value(pair.key) : element(pair.key), element(pair.value)]
      end
    end

    # A single required class stays a class, like "Array[String]" does in Ruby. Anything else stays an expression.
    def element(node)
      expression = expression(node)
      single = expression.types.one? && expression.required? && expression.types.first.instance_of?(Class)
      single ? expression.types.first : expression
    end

    def constant(node)
      name = node.slice.delete_prefix('::')
      constant = node.slice.start_with?('::') ? Object.const_get(name) : @namespace.const_get(name)
      raise_error("'#{name}' isn't a type", node.location) unless constant.is_a?(Module) || constant.is_a?(TypeDefinition)

      constant
    rescue NameError
      raise_error("Unknown type '#{name}'", node.location)
    end

    def value(node)
      Lowkey::ValueParser.value(node) { raise_error("'#{node.slice}' isn't a value", node.location) }
    end

    def call?(node, name)
      node.is_a?(Prism::CallNode) && node.name == name && node.block.nil?
    end

    def raise_error(message, location)
      raise ParseError, "#{message} at #{location.start_offset} in '#{@text}'"
    end
  end
end
