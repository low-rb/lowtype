# frozen_string_literal: true

require_relative 'complex_type'
require_relative 'error_types'
require_relative 'type_definition'

module Low
  module Types
    # Status is an Integer for basic type checking...
    class Status < Integer
      extend ComplexType

      # ...but becomes an instance of StatusCode when called with "Status[:code]" for advanced type checking (status + code).
      def self.[](status_code)
        @status_code = StatusCode.new(status_code)
      end

      class StatusCode
        include TypeDefinition

        attr_reader :status_code

        STATUS_CODES = [
          # Info.
          100, 101, 102, 103,
          # Success.
          200, 201, 202, 203, 204, 205, 206, 207, 208, 226,
          # Redirect.
          300, 301, 302, 303, 304, 305, 306, 307, 308,
          # Client Error.
          400, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414,
          415, 416, 417, 418, 421, 422, 423, 424, 425, 426, 428, 429, 431, 451,
          # Server Error.
          500, 501, 502, 503, 504, 505, 506, 507, 508, 510, 511
        ].freeze

        def initialize(status_code)
          raise AllowedTypeError unless STATUS_CODES.include?(status_code)

          @status_code = status_code
        end

        def match?(value:)
          value == @status_code
        end

        def display_name
          "Status[#{@status_code}]"
        end

        def ==(other)
          other.class == self.class && other.status_code == @status_code
        end

        def eql?(other)
          self == other
        end

        def hash
          [self.class, @status_code].hash
        end
      end
    end
  end
end
