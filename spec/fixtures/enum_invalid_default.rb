# frozen_string_literal: true

require_relative '../../lib/lowtype'

class EnumInvalidDefault
  include LowType

  def paint(color: Enum['red', 'orange', 'yellow'] | 'blue')
    color
  end
end
