# frozen_string_literal: true

require_relative '../../lib/lowtype'
require_relative '../../lib/syntax/union_types'

RSpec.describe Low::TypeErrors do
  using LowType::Syntax

  def mismatch(node) = { path: node.path, expected: node.expected, received: node.received }

  def errors(expression, value)
    expression.errors(value).map { |node| mismatch(node) }
  end

  it 'has no errors for a match' do
    expect(errors(String | nil, 'a')).to eq([])
    expect(errors(String | nil, nil)).to eq([])
  end

  it 'describes a mismatch with the types and the value' do
    expect((String | Integer).errors(1.5))
      .to contain_exactly(have_attributes(path: '', value: 1.5, expected: 'String | Integer', received: '1.5'))
  end

  it 'matches modules as well as classes' do
    expect(described_class.error_nodes(type: Comparable, value: 'a')).to eq([])
    expect(described_class.error_nodes(type: Enumerable, value: 1).map { |node| mismatch(node) })
      .to eq([{ path: '', expected: 'Enumerable', received: '1' }])
  end

  it 'allows nil when the expression has a default' do
    expect(errors(String | 'Hello', nil)).to eq([])
  end

  it 'checks every element of an array' do
    expect(errors(Array[String], ['a', 'b', 3])).to eq([{ path: '[2]', expected: 'String', received: '3' }])
  end

  it 'checks each element of an array against the type in its position' do
    expect(errors(Array[String, Integer], [1, 2])).to eq([{ path: '[0]', expected: 'String', received: '1' }])
  end

  it 'checks every key and value of a typed hash' do
    expect(errors(Hash[String => Integer], { 'a' => 1, 'b' => 'x' })).to eq([{ path: 'b', expected: 'Integer', received: '"x"' }])
  end

  it 'describes what is wrong inside a schema in a union' do
    expect(errors(Schema[id: Integer] | String, { id: 'x' })).to eq([{ path: 'id', expected: 'Integer', received: '"x"' }])
  end

  it 'gives paths through arrays of schemas' do
    expect(errors(Array[Schema[tags: Array[String]]], [{ tags: [] }, { tags: [1] }]))
      .to eq([{ path: '[1].tags[0]', expected: 'String', received: '1' }])
  end

  it 'checks complex types' do
    expect(errors(Boolean | nil, 'yes')).to eq([{ path: '', expected: 'Boolean | nil', received: '"yes"' }])
    expect(errors(Enum[:a, :b] | nil, :c)).to eq([{ path: '', expected: 'Enum[:a, :b] | nil', received: ':c' }])
  end

  it 'names containers and shortens long values' do
    expect(errors(String | nil, [1])).to eq([{ path: '', expected: 'String | nil', received: 'Array' }])
    expect(errors(Integer | nil, 'x' * 50).first[:received]).to eq("\"#{'x' * 36}...")
  end
end
