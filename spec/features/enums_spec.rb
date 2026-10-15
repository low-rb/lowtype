# frozen_string_literal: true

require_relative '../../lib/types/error_types'
require_relative '../fixtures/enums'

RSpec.describe Enums do
  subject(:enums) { described_class.new }

  describe '#typed_arg' do
    it 'passes through an allowed value' do
      expect(enums.typed_arg('orange')).to eq('orange')
    end

    context 'when arg is not an allowed value', type_checking: true do
      let(:error_message) do
        "Invalid argument type 'String' for parameter 'color'. Valid types: 'Enum[\"red\", \"orange\", \"yellow\"]'"
      end

      it 'raises an argument type error' do
        expect { enums.typed_arg('blue') }.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end
  end

  describe '#typed_arg_and_default_value' do
    it 'passes through the argument' do
      expect(enums.typed_arg_and_default_value(state: :published)).to eq(:published)
    end

    it 'provides the default value' do
      expect(enums.typed_arg_and_default_value).to eq(:draft)
    end

    context 'when arg is not an allowed value', type_checking: true do
      let(:error_message) do
        "Invalid argument type 'Symbol' for parameter 'state'. Valid types: 'Enum[:draft, :published]'"
      end

      it 'raises an argument type error' do
        expect { enums.typed_arg_and_default_value(state: :archived) }.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end
  end

  describe '#mixed_values' do
    it 'passes through allowed values of any type' do
      expect(enums.mixed_values(:ok)).to eq(:ok)
      expect(enums.mixed_values('not found')).to eq('not found')
      expect(enums.mixed_values(404)).to eq(404)
    end

    it 'raises an argument type error', type_checking: true do
      expect { enums.mixed_values(500) }.to raise_error(Low::ArgumentTypeError)
    end
  end

  describe '#enum_and_type' do
    it 'provides the default value allowed by the union type' do
      expect(enums.enum_and_type).to eq(200)
    end

    it 'passes through the enum value' do
      expect(enums.enum_and_type(code: :ok)).to eq(:ok)
    end

    context 'when arg is neither type', type_checking: true do
      let(:error_message) do
        "Invalid argument type 'Symbol' for parameter 'code'. Valid types: 'Enum[:ok] | Integer'"
      end

      it 'raises an argument type error' do
        expect { enums.enum_and_type(code: :error) }.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end
  end

  describe '#typed_arg_and_nil' do
    it 'allows nil' do
      expect(enums.typed_arg_and_nil).to be_nil
    end
  end

  describe '#typed_array' do
    it 'passes through an array of allowed values' do
      expect(enums.typed_array(%i[draft published])).to eq(%i[draft published])
    end

    context 'when an element is not an allowed value', type_checking: true do
      let(:error_message) do
        "Invalid argument type 'Array' for parameter 'states'. Valid types: '[Enum[:draft, :published]]'"
      end

      it 'raises an argument type error' do
        expect { enums.typed_array(%i[draft archived]) }.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end
  end

  describe '#typed_return' do
    it 'returns an allowed value' do
      expect(enums.typed_return(:draft)).to eq(:draft)
    end

    context 'when return value is not an allowed value', type_checking: true do
      let(:error_message) do
        "Invalid return type 'Symbol' for method 'typed_return'. Valid types: 'Enum[:draft, :published]'"
      end

      it 'raises a return type error' do
        expect { enums.typed_return(:archived) }.to raise_error(Low::ReturnTypeError, error_message)
      end
    end
  end

  context 'when enum default value is not an allowed value' do
    let(:error_message) do
      /Invalid default value "blue" for parameter 'color' at .+_default\.rb:8\. Valid types: 'Enum\["red", "orange", "yellow"\]'/
    end

    it 'raises an allowed type error on class load' do
      expect do
        load File.expand_path('../fixtures/enum_invalid_default.rb', __dir__)
      end.to raise_error(Low::AllowedTypeError, error_message)
    end
  end
end
