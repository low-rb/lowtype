# frozen_string_literal: true

require_relative '../../lib/types/complex_types'
require_relative '../../lib/types/error_types'
require_relative '../../lib/expressions/type_expression'
require_relative '../../lib/syntax/union_types'

RSpec.describe 'Low::Types::Boolean and Low::Types::Enum' do
  DummyProxy = Class.new do
    def error_type
      Low::ArgumentTypeError
    end

    def error_message(value:)
      'type mismatch'
    end

    def backtrace(backtrace:, hidden_paths:)
      backtrace
    end
  end

  let(:proxy) { DummyProxy.new }

  describe Low::Types::Boolean do
    it 'matches only true/false' do
      expect(described_class.match?(value: true)).to eq(true)
      expect(described_class.match?(value: false)).to eq(true)

      expect(described_class.match?(value: 1)).to eq(false)
      expect(described_class.match?(value: 't')).to eq(false)
    end

    it 'provides a useful error message' do
      expect(described_class.error_message_for(value: :nope)).to eq('Expected true/false, got :nope')
    end
  end

  describe Low::Types::Enum do
    it 'validates membership and formats errors' do
      type = described_class.symbols(:draft, :published)

      expect(type.match?(value: :draft)).to eq(true)
      expect(type.match?(value: :deleted)).to eq(false)

      expect(type.error_message_for(value: :deleted)).to eq(
        'Expected one of [:draft, :published], got :deleted'
      )
    end

    it 'raises in strict mode for empty enums' do
      expect { described_class[strict: true] }.to raise_error(Low::ConfigError, /cannot be empty/i)
    end

    it 'supports union types with TypeExpression' do
      enum_a = described_class.symbols(:draft, :published)
      enum_b = described_class.symbols(:archived)

      type_expression = (enum_a | enum_b)

      expect { type_expression.validate!(value: :archived, proxy: proxy) }.not_to raise_error
    end
  end
end

