# frozen_string_literal: true

require_relative '../../lib/low_type'

RSpec.describe LowType do
  after { LowType.instance_variable_set(:@config, nil) }

  describe '.freeze_config!' do
    it 'freezes the config object' do
      LowType.freeze_config!

      expect(LowType.config).to be_frozen
    end

    it 'prevents further mutation via #configure' do
      LowType.freeze_config!

      expect { LowType.configure { |config| config.type_checking = false } }.to raise_error(FrozenError)
    end
  end
end
