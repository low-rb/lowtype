# frozen_string_literal: true

require_relative '../../lib/types/error_types'
require_relative '../fixtures/union_types'

RSpec.describe UnionTypes do
  subject(:union_types) { described_class.new }

  describe '#multiple_typed_args' do
    it 'passes through both arguments' do
      expect(union_types.multiple_typed_args('Shalom')).to eq('Shalom')
      expect(union_types.multiple_typed_args(123)).to eq(123)
    end

    context 'when arg is wrong type' do
      let(:error_message) do
        "Invalid argument type 'TrueClass' for parameter 'greeting'. Valid types: 'String | Integer'"
      end

      it 'raises an invalid type error', type_checking: true do
        expect { union_types.multiple_typed_args(true) }.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end

    context 'when no arg is provided' do
      it 'raises an argument error' do
        # When shimmed the error message will be from LowType, when stripped standard Ruby.
        expect { union_types.multiple_typed_args }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#multiple_typed_args_and_default_value' do
    it 'passes through both arguments types' do
      expect(union_types.multiple_typed_args_and_default_value('Shalom')).to eq('Shalom')
      expect(union_types.multiple_typed_args_and_default_value(123)).to eq(123)
    end

    context 'when arg is wrong type' do
      let(:error_message) do
        "Invalid argument type 'TrueClass' for parameter 'greeting'. Valid types: 'String | Integer'"
      end

      it 'raises an argument type error', type_checking: true do
        expect do
          union_types.multiple_typed_args_and_default_value(true)
        end.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end

    context 'when no arg is provided' do
      it 'provides the default value' do
        expect(union_types.multiple_typed_args_and_default_value).to eq('Salutations')
      end
    end
  end
end
