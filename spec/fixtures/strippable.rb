# frozen_string_literal: true

require_relative '../../lib/lowtype'

class Strippable
  include LowType
  using LowType::Syntax

  DEFAULT_TIMEOUT = 5

  type_accessor name: String, age: Integer | nil

  def typed_args(greeting = String, name = String | 'café', timeout = DEFAULT_TIMEOUT) -> { String }
    "#{greeting} #{name} #{timeout}"
  end

  def multiline_args(
    first = String,
    second: Integer | 2,
    third: 'untyped'
  ) -> { String }
    "#{first}#{second}#{third}"
  end

  def own_line_return_type(value)
    -> { Integer }
    value
  end

  def endless(states: Array[Symbol] | %i[draft published]) = states

  def self.class_method(value = Integer | value(Integer)) = value

  def local_type
    type String | 'Hello'
  end
end
