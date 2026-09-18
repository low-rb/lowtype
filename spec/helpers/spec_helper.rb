# frozen_string_literal: true

require_relative '../../lib/lowtype'
require_relative '../../lib/types/complex_types'

# Access types in tests without requiring them.
include Low::Types # rubocop:disable Style/MixinUsage

TYPE_CHECKING = ENV['TYPE_CHECKING'] != 'false'

LowType.configure do |config|
  config.type_checking = TYPE_CHECKING
  config.disable_mode = :shim if ENV['DISABLE_MODE'] == 'shim'
  config.disable_mode = :strip if ENV['DISABLE_MODE'] == 'strip'
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
    # Large diff when expected objects don't match.
    expectations.max_formatted_output_length = 10_000
  end

  # Specs with no explicit `:type_checking` tag run in both processes (see Rakefile).
  # This configuration is a double negative; it essentially activates the flag.
  config.filter_run_excluding type_checking: !TYPE_CHECKING
end
