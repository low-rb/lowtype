# frozen_string_literal: true

require_relative '../../lib/lowtype'
require_relative '../../lib/types/error_types'
require_relative '../fixtures/arrays'

RSpec.describe Arrays do
  subject(:subject) { described_class.new }

  describe '#typed_array_arg' do
    it 'passes through the argument' do
      expect(subject.typed_array_arg(%w[Hi Hey Howdy])).to eq(%w[Hi Hey Howdy])
    end

    context 'when no arg provided', type_checking: true do
      let(:error_message) { "Invalid argument type 'NilClass' for parameter 'greetings'. Valid types: '[String]'" }

      it 'raises an argument error' do
        expect { subject.typed_array_arg }.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end

    context 'when nil is the second element', type_checking: true do
      let(:error_message) { "Invalid argument type 'Array' for parameter 'greetings'. Valid types: '[String]'" }
      let(:greetings) { ['Hi', nil, 'Howdy'] }

      context 'without deep type check' do
        before { LowType.configure { |config| config.deep_type_check = false } }
        after { LowType.configure { |config| config.deep_type_check = true } }

        it 'passes through the argument' do
          expect(subject.typed_array_arg(greetings)).to eq(greetings)
        end
      end

      context 'with deep type check' do
        before { LowType.configure { |config| config.deep_type_check = true } }
        after { LowType.configure { |config| config.deep_type_check = false } }

        it 'raises an argument error' do
          expect { subject.typed_array_arg(greetings) }.to raise_error(Low::ArgumentTypeError, error_message)
        end
      end
    end
  end

  describe '#typed_nilable_array_arg' do
    it 'passes through the argument' do
      expect(subject.typed_nilable_array_arg([nil, 'Farwell', 'See ya'])).to eq([nil, 'Farwell', 'See ya'])
    end

    context 'when no arg provided', type_checking: true do
      let(:error_message) { "Invalid argument type 'NilClass' for parameter 'goodbyes'. Valid types: '[String | nil]'" }

      it 'raises an argument error' do
        expect { subject.typed_nilable_array_arg }.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end

    context 'when nil is not the first element', type_checking: true do
      let(:error_message) { "Invalid argument type 'Array' for parameter 'goodbyes'. Valid types: '[String]'" }
      let(:goodbyes) { ['Farewell', nil, 'See ya'] }

      context 'without deep type check' do
        it 'passes through the argument' do
          expect(subject.typed_nilable_array_arg(goodbyes)).to eq(goodbyes)
        end
      end

      context 'with deep type check' do
        before { LowType.configure { |config| config.deep_type_check = true } }
        after { LowType.configure { |config| config.deep_type_check = false } }

        it 'passes through the argument' do
          expect(subject.typed_nilable_array_arg(goodbyes)).to eq(goodbyes)
        end
      end
    end
  end

  describe '#typed_nilable_array_arg_and_default_nil' do
    let(:greetings) { ['Hi', nil, 'Howdy'] }

    it 'passes through the argument' do
      expect(subject.typed_nilable_array_arg_and_default_nil(greetings)).to eq(greetings)
    end

    context 'when no arg provided' do
      it 'provides the default nil' do
        expect(subject.typed_nilable_array_arg_and_default_nil).to eq(nil)
      end
    end
  end

  describe '#typed_array_arg_and_default_nil' do
    let(:greetings) { %w[Hi Hey Howdy] }

    it 'passes through the argument' do
      expect(subject.typed_array_arg_and_default_nil(greetings)).to eq(greetings)
    end

    context 'when no arg provided' do
      it 'provides the default nil' do
        expect(subject.typed_array_arg_and_default_nil).to eq(nil)
      end
    end
  end

  describe '#typed_array_arg_and_default_value' do
    let(:greetings) { %w[Hi Hey Howdy] }

    it 'passes through the argument' do
      expect(subject.typed_array_arg_and_default_value(greetings)).to eq(greetings)
    end

    context 'when no arg provided' do
      it 'provides the default value' do
        expect(subject.typed_array_arg_and_default_value).to eq(greetings)
      end
    end
  end
end
