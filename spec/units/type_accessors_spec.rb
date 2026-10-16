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

  describe 'default values' do
    subject { LowDefaults.new }

    it 'returns the default value when the value is nil' do
      expect(subject.name).to eq('Cher')
    end

    it 'returns the value when the value is set' do
      subject.instance_variable_set(:@name, 'Tim')
      expect(subject.name).to eq('Tim')
    end

    it 'returns nil when the default value is nil' do
      expect(subject.nickname).to be_nil
    end

    it 'does not share a mutable default value' do
      subject.tags << 'singer'

      expect(subject.tags).to eq([])
      expect(LowDefaults.new.tags).to eq([])
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

      it 'points the error to the type accessor' do
        expect { subject.name }.to raise_error do |error|
          expect(error.backtrace.first).to start_with("#{File.expand_path('../fixtures/type_accessors.rb', __dir__)}:28")
        end
      end
    end
  end
end
