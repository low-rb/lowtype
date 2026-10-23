# frozen_string_literal: true

require_relative '../../../lib/lowtype'
require_relative '../../../lib/syntax/union_types'

RSpec.describe Schema do
  using LowType::Syntax

  def mismatch(node) = { path: node.path, expected: node.expected, received: node.received }

  subject(:schema) { Schema[id: Integer, email: String | nil, address: { city: String }] }

  describe '.[]' do
    it 'turns nested hashes of named keys into schemas' do
      expect(schema.fields[:address]).to eq(Schema[city: String])
    end

    it 'keeps typed hashes as they are' do
      expect(Schema[counts: { String => Integer }].fields[:counts]).to eq({ String => Integer })
    end

    it 'requires at least one key' do
      expect { Schema[{}] }.to raise_error(Low::AllowedTypeError)
    end
  end

  describe '#match?' do
    it 'matches a hash with the named keys' do
      expect(schema.match?(value: { id: 1, email: 'a@b.c', address: { city: 'Paris' } })).to be(true)
    end

    it 'matches string keys, like parsed JSON' do
      expect(schema.match?(value: { 'id' => 1, 'address' => { 'city' => 'Paris' } })).to be(true)
    end

    it 'allows keys whose type allows nil to be missing' do
      expect(schema.match?(value: { id: 1, address: { city: 'Paris' } })).to be(true)
    end

    it 'allows other keys' do
      expect(schema.match?(value: { id: 1, address: { city: 'Paris' }, extra: true })).to be(true)
    end

    it 'does not match a missing required key, a wrong type or a value that is not a hash' do
      expect(schema.match?(value: { address: { city: 'Paris' } })).to be(false)
      expect(schema.match?(value: { id: '1', address: { city: 'Paris' } })).to be(false)
      expect(schema.match?(value: [1])).to be(false)
    end
  end

  describe '#errors' do
    it 'names the path of each mismatch' do
      errors = schema.errors({ id: '1', email: 3, address: {} }).map { |node| mismatch(node) }

      expect(errors).to eq([
                             { path: 'id', expected: 'Integer', received: '"1"' },
                             { path: 'email', expected: 'String | nil', received: '3' },
                             { path: 'address.city', expected: 'String', received: 'nil' }
                           ])
    end

    it 'expects a hash' do
      expect(schema.errors('x').map { |node| mismatch(node) }).to eq([{ path: '', expected: 'Hash', received: '"x"' }])
    end
  end

  describe '#display_name' do
    it 'displays the keys and their types' do
      expect(schema.display_name).to eq('Schema[id: Integer, email: String | nil, address: Schema[city: String]]')
    end
  end

  describe '#|' do
    it 'creates a type expression' do
      expect((Schema[id: Integer] | nil).default_value).to be_nil
    end
  end
end
