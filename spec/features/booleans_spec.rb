# frozen_string_literal: true

require_relative '../../lib/types/error_types'
require_relative '../fixtures/booleans'

RSpec.describe Booleans do
  subject(:booleans) { described_class.new }

  describe '#typed_arg' do
    it 'passes through true and false' do
      expect(booleans.typed_arg(true)).to be(true)
      expect(booleans.typed_arg(false)).to be(false)
    end

    context 'when arg is truthy but not a boolean', type_checking: true do
      let(:error_message) { "Invalid argument type 'String' for parameter 'flag'. Valid types: 'Boolean'" }

      it 'raises an argument type error' do
        expect { booleans.typed_arg('true') }.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end

    context 'when arg is nil', type_checking: true do
      let(:error_message) { "Invalid argument type 'NilClass' for parameter 'flag'. Valid types: 'Boolean'" }

      it 'raises an argument type error' do
        expect { booleans.typed_arg(nil) }.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end
  end

  describe '#typed_arg_and_default_value' do
    it 'passes through the argument' do
      expect(booleans.typed_arg_and_default_value(flag: true)).to be(true)
    end

    it 'provides the false default value' do
      expect(booleans.typed_arg_and_default_value).to be(false)
    end
  end

  describe '#typed_arg_and_nil' do
    it 'allows nil' do
      expect(booleans.typed_arg_and_nil).to be_nil
    end

    context 'when arg is not a boolean', type_checking: true do
      let(:error_message) { "Invalid argument type 'Integer' for parameter 'flag'. Valid types: 'Boolean | nil'" }

      it 'raises an argument type error' do
        expect { booleans.typed_arg_and_nil(flag: 1) }.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end
  end

  describe '#typed_array' do
    it 'passes through an array of booleans' do
      expect(booleans.typed_array([true, false, true])).to eq([true, false, true])
    end

    context 'when an element is not a boolean', type_checking: true do
      let(:error_message) { "Invalid argument type 'Array' for parameter 'flags'. Valid types: '[Boolean]'" }

      it 'raises an argument type error' do
        expect { booleans.typed_array([true, 'false']) }.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end
  end

  describe '#typed_return' do
    it 'returns a boolean' do
      expect(booleans.typed_return(false)).to be(false)
    end

    context 'when return value is not a boolean', type_checking: true do
      let(:error_message) { "Invalid return type 'Integer' for method 'typed_return'. Valid types: 'Boolean'" }

      it 'raises a return type error' do
        expect { booleans.typed_return(0) }.to raise_error(Low::ReturnTypeError, error_message)
      end
    end
  end
end
