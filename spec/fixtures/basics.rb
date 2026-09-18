# frozen_string_literal: true

require_relative '../../lib/lowtype'

class Basics
  include LowType

  def initialize(greeting = String, name = String)
    @greeting = greeting
    @name = name
  end

  def typed_arg(greeting = String)
    greeting
  end

  def typed_arg_without_body(greeting = String)
    # LowType should still validate the param without erroring.
  end

  def typed_arg_and_default_value(greeting = String | 'Hello')
    greeting
  end

  def typed_arg_and_invalid_default_value(greeting = String | 123)
    greeting
  end
end
