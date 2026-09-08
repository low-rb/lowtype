# frozen_string_literal: true

require_relative '../../lib/low_type'

class RactorSafeUntyped
  include LowType
  ractor_safe!

  def greet(name = String)
    name
  end
end
