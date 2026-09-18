# frozen_string_literal: true

module Low
  class ArgumentTypeError < ArgumentError; end
  class LocalTypeError < TypeError; end
  class ReturnTypeError < TypeError; end
  class AllowedTypeError < TypeError; end
  class ConfigError < TypeError; end
end
