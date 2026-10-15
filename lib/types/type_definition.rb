# frozen_string_literal: true

module Low
  # A complex type with params, created via the "Type[params]" syntax.
  module TypeDefinition
    # For "Type[params] | [type_expression/type/value]" situations, convert definition into a type expression.
    def |(other)
      ::Low::TypeExpression.new(type: self) | other
    end

    def match?(value:)
      raise NotImplementedError
    end

    def display_name
      raise NotImplementedError
    end
  end
end
