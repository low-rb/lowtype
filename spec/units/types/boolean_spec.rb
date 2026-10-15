# frozen_string_literal: true

require_relative '../../../lib/types/boolean'

RSpec.describe Boolean do
  describe '.match?' do
    it 'matches true and false' do
      expect(described_class.match?(value: true)).to be(true)
      expect(described_class.match?(value: false)).to be(true)
    end

    it 'does not match truthy or falsy values' do
      expect(described_class.match?(value: nil)).to be(false)
      expect(described_class.match?(value: 0)).to be(false)
      expect(described_class.match?(value: 'true')).to be(false)
    end
  end

  describe '.display_name' do
    it 'displays the type name' do
      expect(described_class.display_name).to eq('Boolean')
    end
  end
end
