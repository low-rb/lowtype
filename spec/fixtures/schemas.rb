# frozen_string_literal: true

require_relative '../../lib/lowtype'

class Schemas
  include LowType

  def typed_arg(user = Schema[name: String, age: Integer | nil])
    user
  end

  def typed_return(user) -> { Schema[name: String] }
    user
  end
end
