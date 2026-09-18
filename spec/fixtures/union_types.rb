# frozen_string_literal: true

class UnionTypes
  include LowType

  def multiple_typed_args(greeting = String | Integer)
    greeting
  end

  def multiple_typed_args_and_default_value(greeting = String | Integer | 'Salutations')
    greeting
  end
end
