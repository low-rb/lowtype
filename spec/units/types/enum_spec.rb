# frozen_string_literal: true

require_relative '../../../lib/types/enum'

RSpec.describe Enum do
  subject(:enum) { Enum[:draft, 'published', 200] }

  describe '.[]' do
    it 'creates an enum definition' do
      expect(enum.values).to eq([:draft, 'published', 200])
    end

    it 'requires at least one value' do
      expect { Enum[] }.to raise_error(Low::AllowedTypeError)
    end
  end

  describe '#match?' do
    it 'matches allowed values' do
      expect(enum.match?(value: :draft)).to be(true)
      expect(enum.match?(value: 'published')).to be(true)
      expect(enum.match?(value: 200)).to be(true)
    end

    it 'does not match other values' do
      expect(enum.match?(value: 'draft')).to be(false)
      expect(enum.match?(value: nil)).to be(false)
    end
  end

  describe '#display_name' do
    it 'displays the allowed values' do
      expect(enum.display_name).to eq('Enum[:draft, "published", 200]')
    end
  end

  describe '#==' do
    it 'does value comparison' do
      expect(Enum[:a, :b]).to eq(Enum[:a, :b])
      expect(Enum[:a, :b]).not_to eq(Enum[:b, :a])
    end
  end

  describe '#|' do
    it 'creates a type expression' do
      expression = Enum[:a, :b] | :a

      expect(expression.types).to eq([Enum[:a, :b]])
      expect(expression.default_value).to eq(:a)
    end
  end
end
