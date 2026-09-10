# frozen_string_literal: true

require_relative '../../lib/low_type'

RSpec.describe 'LowType.config.type_checking' do
  context 'when type checking is disabled' do
    subject(:type_checking) { TypeCheckingDisabled.new }

    LowType.configure { |config| config.type_checking = false }
    require_relative '../fixtures/type_checking_disabled'

    describe '#typed_arg' do
      it 'passes through the argument' do
        expect(type_checking.typed_arg('Hi')).to eq('Hi')
      end

      context 'when arg is correct type' do
        it 'accepts the typed arg' do
          expect { type_checking.typed_arg('Yo') }.not_to raise_error
        end
      end

      context 'when arg is wrong type' do
        it 'accepts the wrongly typed arg' do
          expect { type_checking.typed_arg(123) }.not_to raise_error
        end
      end
    end

    describe '#typed_kwarg' do
      it 'passes through the keyword argument' do
        expect(type_checking.typed_kwarg(greeting: 'Hi')).to eq('Hi')
      end

      context 'when kwarg is correct type' do
        it 'accepts the typed kwarg' do
          expect { type_checking.typed_kwarg(greeting: 'Yo') }.not_to raise_error
        end
      end

      context 'when kwarg is wrong type' do
        it 'accepts the wrongly typed kwarg' do
          expect { type_checking.typed_kwarg(greeting: 123) }.not_to raise_error
        end
      end
    end
  end

  context 'when type checking is enabled' do
    subject(:type_checking) { TypeCheckingEnabled.new }

    LowType.configure { |config| config.type_checking = true }
    require_relative '../fixtures/type_checking_enabled'

    describe '#typed_arg' do
      it 'passes through the argument' do
        expect(type_checking.typed_arg('Hi')).to eq('Hi')
      end

      context 'when arg is correct type' do
        it 'accepts the typed arg' do
          expect { type_checking.typed_arg('Yo') }.not_to raise_error
        end
      end

      context 'when arg is wrong type' do
        it 'raises an argument type error' do
          expect { type_checking.typed_arg(123) }.to raise_error(Low::ArgumentTypeError)
        end
      end
    end

    describe '#typed_kwarg' do
      it 'passes through the keyword argument' do
        expect(type_checking.typed_kwarg(greeting: 'Hi')).to eq('Hi')
      end

      context 'when kwarg is correct type' do
        it 'accepts the typed kwarg' do
          expect { type_checking.typed_kwarg(greeting: 'Yo') }.not_to raise_error
        end
      end

      context 'when kwarg is wrong type' do
        it 'raises an argument type error' do
          expect { type_checking.typed_kwarg(greeting: 123) }.to raise_error(Low::ArgumentTypeError)
        end
      end
    end
  end
end
