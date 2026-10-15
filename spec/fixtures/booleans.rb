# frozen_string_literal: true

require_relative '../../lib/lowtype'

class Booleans
  include LowType

  def typed_arg(flag = Boolean)
    flag
  end

  def typed_arg_and_default_value(flag: Boolean | false)
    flag
  end

  def typed_arg_and_nil(flag: Boolean | nil)
    flag
  end

  def typed_array(flags = Array[Boolean])
    flags
  end

  def typed_return(flag) -> { Boolean }
    flag
  end
end
