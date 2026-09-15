# frozen_string_literal: true

require_relative '../../lib/types/error_types'
require_relative '../fixtures/basics'

RSpec.describe Basics do
  subject(:basics) { described_class.new(greeting, name) }

  let(:greeting) { 'Hey' }
  let(:name) { 'Mate' }

  describe '#initialize' do
    it 'instantiates a typed class' do
      expect { basics }.not_to raise_error
    end

    context 'when the arg type is incorrect' do
      let(:greeting) { 123 }
      let(:error_message) { "Invalid argument type 'Integer' for parameter 'greeting'. Valid types: 'String'" }

      it 'raises an invalid type error', type_checking: true do
        expect { basics }.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end
  end

  describe '#typed_arg' do
    it 'passes through the argument' do
      expect(basics.typed_arg('Hi')).to eq('Hi')
    end

    context 'when no arg provided with type checking', type_checking: true do
      let(:error_message) { "Invalid argument type 'NilClass' for parameter 'greeting'. Valid types: 'String'" }

      it 'raises an argument error' do
        expect { basics.typed_arg }.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end

    context 'when no arg provided without type checking', type_checking: false do
      it 'raises an argument error' do
        # When shimmed the error message will be from LowType, when stripped standard Ruby.
        expect { basics.typed_arg }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#typed_arg_without_body' do
    it 'returns nil' do
      expect(basics.typed_arg_without_body('Hola')).to eq(nil)
    end

    context 'when no arg provided', type_checking: true do
      let(:error_message) { "Invalid argument type 'NilClass' for parameter 'greeting'. Valid types: 'String'" }

      it 'raises an argument error' do
        expect { basics.typed_arg_without_body }.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end
  end

  describe '#typed_arg_and_default_value' do
    it 'passes through the argument' do
      expect(basics.typed_arg_and_default_value('Howdy')).to eq('Howdy')
    end

    context 'when no arg provided' do
      it 'provides the default value' do
        expect(basics.typed_arg_and_default_value).to eq('Hello')
      end
    end
  end

  describe '#typed_arg_and_invalid_default_value' do
    it 'passes through the argument' do
      expect(basics.typed_arg_and_invalid_default_value('Howdy')).to eq('Howdy')
    end

    context 'when no arg provided' do
      let(:error_message) { "Invalid argument type 'Integer' for parameter 'greeting'. Valid types: 'String'" }

      # A default value that is not nil still has to be an allowed type.
      it 'raises an argument type error', type_checking: true do
        expect { basics.typed_arg_and_invalid_default_value }.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end
  end
end
