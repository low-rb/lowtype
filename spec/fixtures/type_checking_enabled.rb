# frozen_string_literal: true

require_relative '../../lib/low_type'

class TypeCheckingEnabled
  include LowType

  def typed_arg(greeting = String)
    greeting
  end

  def typed_kwarg(greeting: String)
    greeting
  end
end
