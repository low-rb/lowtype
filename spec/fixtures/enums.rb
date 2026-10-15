# frozen_string_literal: true

require_relative '../../lib/lowtype'

class Enums
  include LowType

  def typed_arg(color = Enum['red', 'orange', 'yellow'])
    color
  end

  def typed_arg_and_default_value(state: Enum[:draft, :published] | :draft)
    state
  end

  def mixed_values(code = Enum[:ok, 'not found', 404])
    code
  end

  def enum_and_type(code: Enum[:ok] | Integer | 200)
    code
  end

  def typed_arg_and_nil(state: Enum[:draft, :published] | nil)
    state
  end

  def typed_array(states = Array[Enum[:draft, :published]])
    states
  end

  def typed_return(state) -> { Enum[:draft, :published] }
    state
  end
end
