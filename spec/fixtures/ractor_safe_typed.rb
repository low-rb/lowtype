# frozen_string_literal: true

require_relative '../../lib/low_type'

class RactorSafeTyped
  include LowType
  ractor_safe!

  def greet(name = String)
    name
  end
end
