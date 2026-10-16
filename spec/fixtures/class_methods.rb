# frozen_string_literal: true

require_relative '../../lib/lowtype'

class ClassMethods
  include LowType

  def self.inline_class_typed_arg(goodbye = String)
    goodbye
  end

  def ClassMethods.named_class_typed_arg(goodbye = String) # rubocop:disable Style/ClassMethods
    goodbye
  end

  class << self
    def class_typed_arg(goodbye = String)
      goodbye
    end

    def class_typed_arg_and_default_value(goodbye = String | 'Bye')
      goodbye
    end
  end

  private

  def private_typed_arg(greeting = String)
    greeting
  end
end
