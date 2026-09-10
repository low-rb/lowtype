# frozen_string_literal: true

require_relative '../factories/type_factory'
require_relative 'matchable_type'
require_relative 'boolean'
require_relative 'enum'
require_relative 'status'

module Low
  module Types
    COMPLEX_TYPES = [
      Boolean,
      Headers = TypeFactory.complex_type(Hash),
      HTML = TypeFactory.complex_type(String),
      JSON = TypeFactory.complex_type(String),
      Status,
      Tuple = TypeFactory.complex_type(Array),
      XML = TypeFactory.complex_type(String)
    ].freeze
  end
end
