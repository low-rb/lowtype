# frozen_string_literal: true

require 'lowkey'

require_relative '../interfaces/error_handling'
require_relative '../types/error_types'

module ::Lowkey
  class ParamProxy
    include ::Low::ErrorHandling

    def error_type
      ::Low::ArgumentTypeError
    end

    def error_message(value:)
      custom = custom_type_error_message(value:)
      return custom unless custom.nil?

      "Invalid argument type '#{output(value:)}' for parameter '#{@name}'. Valid types: '#{@expression.valid_types}'"
    end

    private

    def custom_type_error_message(value:)
      return unless @expression.respond_to?(:types)
      return unless @expression.types.length == 1

      type = @expression.types.first
      return unless type.respond_to?(:error_message_for)

      type.error_message_for(value:)
    end
  end
end
