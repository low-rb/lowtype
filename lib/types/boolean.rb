# frozen_string_literal: true

module Low
  module Types
    class Boolean
      class << self
        def match?(value:)
          value.equal?(true) || value.equal?(false)
        end

        def display_name
          'Boolean'
        end
      end
    end
  end
end
