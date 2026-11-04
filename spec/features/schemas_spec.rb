# frozen_string_literal: true

require_relative '../../lib/types/error_types'
require_relative '../fixtures/schemas'

RSpec.describe Schemas do
  subject(:schemas) { described_class.new }

  describe '#typed_arg' do
    it 'passes through a matching hash' do
      expect(schemas.typed_arg({ name: 'Ann' })).to eq({ name: 'Ann' })
    end

    context 'when the hash does not match', type_checking: true do
      it 'raises an argument type error' do
        expect { schemas.typed_arg({ name: 'Ann', age: 'old' }) }
          .to raise_error(Low::ArgumentTypeError, /Schema\[name: String, age: Integer \| nil\]/)
      end
    end
  end

  describe '#typed_return' do
    it 'passes through a matching hash' do
      expect(schemas.typed_return({ name: 'Ann' })).to eq({ name: 'Ann' })
    end

    context 'when the hash does not match', type_checking: true do
      it 'raises a return type error' do
        expect { schemas.typed_return({}) }.to raise_error(Low::ReturnTypeError)
      end
    end
  end
end
