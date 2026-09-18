# frozen_string_literal: true

require 'lowkey'

require_relative '../interfaces/error_handling'
require_relative '../types/error_types'

module ::Lowkey
  class ParamProxy
    include ::Low::ErrorHandling

    # Error type should be an ArgumentError when type checking disabled via shim methods.
    def error_type
      return ::Low::ArgumentTypeError if LowType.config.type_checking

      ArgumentError
    end

    # When shimmed the error message will be from LowType, when stripped standard Ruby.
    def error_message(value:)
      "Invalid argument type '#{output(value:)}' for parameter '#{@name}'. Valid types: '#{@expression.valid_types}'"
    end
  end
end
