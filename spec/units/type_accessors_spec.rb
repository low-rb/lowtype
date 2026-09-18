# frozen_string_literal: true

require_relative '../../lib/types/error_types'
require_relative '../fixtures/type_accessors'

# TODO: Add tests for type_checking: false.
RSpec.describe 'TypeAccessors' do
  describe '#type_reader' do
    subject { LowReader.new }

    it 'creates a getter' do
      expect(subject.name).to eq('Cher')
    end

    context 'when the value is set via another method', type_checking: true do
      before do
        subject.instance_variable_set(:@name, 123)
      end

      it 'raises a return type error' do
        expect { subject.name }.to raise_error(Low::ReturnTypeError)
      end
    end
  end

  describe '#type_writer' do
    subject { LowWriter.new }

    it 'creates a setter' do
      subject.name = 'Tim'
      expect(subject.instance_variable_get(:@name)).to eq('Tim')
    end

    context 'when the setter receives an invalid type', type_checking: true do
      it 'raises an argument type error' do
        expect { subject.name = 123 }.to raise_error(Low::ArgumentTypeError)
      end
    end
  end

  describe '#type_accessor' do
    subject { LowAccessor.new }

    it 'creates a getter' do
      expect(subject.name).to eq('Cher')
    end

    it 'creates a setter' do
      subject.name = 'Tim'
      expect(subject.name).to eq('Tim')
    end

    context 'when the setter receives an invalid type', type_checking: true do
      it 'raises an argument type error' do
        expect { subject.name = 123 }.to raise_error(Low::ArgumentTypeError)
      end
    end

    context 'when the value is set via another method', type_checking: true do
      before do
        subject.instance_variable_set(:@name, 123)
      end

      it 'raises a return type error' do
        expect { subject.name }.to raise_error(Low::ReturnTypeError)
      end
    end
  end
end
