# frozen_string_literal: true

require_relative '../../lib/types/error_types'
require_relative '../fixtures/class_methods'

RSpec.describe ClassMethods do
  subject(:class_methods) { described_class }

  describe '.inline_class_typed_arg' do
    it 'passes through the argument' do
      expect(class_methods.inline_class_typed_arg('Hi')).to eq('Hi')
    end

    context 'when no arg provided' do
      it 'raises an argument error' do
        # When shimmed the error message will be from LowType, when stripped standard Ruby.
        expect { class_methods.inline_class_typed_arg }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.class_typed_arg' do
    it 'passes through the argument' do
      expect(class_methods.class_typed_arg('Hi')).to eq('Hi')
    end

    context 'when no arg provided' do
      it 'raises an argument error' do
        # When shimmed the error message will be from LowType, when stripped standard Ruby.
        expect { class_methods.class_typed_arg }.to raise_error(ArgumentError)
      end
    end

    context 'with type checking disabled', type_checking: false do
      it 'accepts wrong type' do
        expect { class_methods.class_typed_arg(123) }.not_to raise_error
      end
    end

    context 'with type checking enabled', type_checking: true do
      it 'rejects wrong type' do
        expect { class_methods.class_typed_arg(123) }.to raise_error
      end
    end
  end

  describe '.class_typed_arg_and_default_value' do
    it 'passes through the argument' do
      expect(class_methods.class_typed_arg_and_default_value('Goodbye')).to eq('Goodbye')
    end

    context 'when no arg provided' do
      it 'provides the default value' do
        expect(class_methods.class_typed_arg_and_default_value).to eq('Bye')
      end
    end
  end
end
