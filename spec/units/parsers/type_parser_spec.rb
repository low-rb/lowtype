# frozen_string_literal: true

require_relative '../../../lib/lowtype'

RSpec.describe Low::TypeParser do
  def mismatch(node) = { path: node.path, expected: node.expected, received: node.received }

  def parse(text, **)
    described_class.parse(text, **)
  end

  describe '.parse' do
    it 'parses a type' do
      expect(parse('String').types).to eq([String])
      expect(parse('String')).to be_required
    end

    it 'parses unions with nil' do
      expression = parse('String | Integer | nil')

      expect(expression.types).to eq([String, Integer])
      expect(expression.default_value).to be_nil
    end

    it 'parses default values' do
      expect(parse("String | 'Hello'").default_value).to eq('Hello')
      expect(parse('Integer | 3').default_value).to eq(3)
      expect(parse('Float | -1.5').default_value).to eq(-1.5)
      expect(parse('Symbol | :draft').default_value).to eq(:draft)
      expect(parse('Boolean | false').default_value).to be(false)
    end

    it 'parses arrays' do
      expect(parse('Array[String]').types).to eq([[String]])
      expect(parse('Array[String, Integer]').types).to eq([[String, Integer]])
      expect(parse('Array').types).to eq([Array])
    end

    it 'keeps expressions in arrays' do
      element = parse('Array[String | nil]').types.first.first

      expect(element.types).to eq([String])
      expect(element.default_value).to be_nil
    end

    it 'parses typed hashes' do
      expect(parse('Hash[String => Integer]').types).to eq([{ String => Integer }])
      expect(parse('Hash').types).to eq([Hash])
    end

    it 'parses enums and statuses' do
      expect(parse(%q(Enum['admin', "member", 1, :x, true, nil])).types).to eq([Enum['admin', 'member', 1, :x, true, nil]])
      expect(parse("Array[Enum['a', 'b']]").types.first.first.types).to eq([Enum['a', 'b']])
      expect(parse('Status[404]').types).to eq([Status[404]])
    end

    it 'parses schemas, with nested hashes as nested schemas' do
      schema = parse("Schema[id: Integer, 'email' => String | nil, address: { city: String }]").types.first

      expect(schema.errors({ id: 1, address: { city: 'Paris' } })).to eq([])
      expect(schema.errors({ id: 1, email: 2, address: {} }).map(&:path)).to eq(%w[email address.city])
    end

    it 'parses a hash as a schema' do
      expect(parse('Array[{ id: Integer }]').errors([{ id: 'x' }]).map { |node| mismatch(node) })
        .to eq([{ path: '[0].id', expected: 'Integer', received: '"x"' }])
    end

    it 'parses Boolean, parentheses and namespaced constants' do
      expect(parse('Boolean').types).to eq([Boolean])
      expect(parse('Array[(String | nil)]').types.first.first.default_value).to be_nil
      expect(parse('Low::Types::Boolean | ::String').types).to eq([Boolean, String])
    end

    it 'unescapes quotes' do
      expect(parse(%q(String | 'it\'s')).default_value).to eq("it's")
    end

    it 'checks values like the expression it builds' do
      expect(parse('Array[Integer] | nil').errors([1, 'x']).map { |node| mismatch(node) })
        .to eq([{ path: '[1]', expected: 'Integer', received: '"x"' }])
    end

    it 'looks up constants in the namespace first' do
      namespace = Module.new { include Low::Types }
      namespace.const_set(:User, Schema[id: Integer])

      expect(parse('Array[User] | Boolean', namespace:).errors([{ id: 'x' }]).map { |node| mismatch(node) })
        .to eq([{ path: '[0].id', expected: 'Integer', received: '"x"' }])
    end

    it 'never runs code' do
      ['Kernel.exit', 'String.new', '`ls`', 'system("ls")', "Dir['*']", "ENV['HOME']", "\"\#{1}\"", 'x = 1', 'String; exit',
       '-> { exit }', 'String.tap { exit }', 'Array[exit]', 'Hash[exit => 1]', 'Enum[exit]', '{ id: exit }', '()', '(exit)'].each do |text|
        expect { parse(text) }.to raise_error(Low::ParseError)
      end
    end

    it 'only allows constants that are types' do
      expect { parse('RUBY_VERSION') }.to raise_error(Low::ParseError, /'RUBY_VERSION' isn't a type/)
    end

    it 'raises with the position for invalid text' do
      expect { parse('Strng | nil') }.to raise_error(Low::ParseError, "Unknown type 'Strng' at 0 in 'Strng | nil'")
      expect { parse('String |') }.to raise_error(Low::ParseError, /at 8/)
      expect { parse('Hash[String]') }.to raise_error(Low::ParseError, /'String' isn't a key and type/)
      expect { parse('Hash[a: String]') }.to raise_error(Low::ParseError, /Expected 'Hash\[K => V\]'/)
      expect { parse('Schema[String => Integer]') }.to raise_error(Low::ParseError, /Schema keys are names/)
      expect { parse('Enum[String]') }.to raise_error(Low::ParseError, /'String' isn't a value/)
      expect { parse('String[Integer]') }.to raise_error(Low::ParseError, /isn't allowed in a type/)
      expect { parse('') }.to raise_error(Low::ParseError, /Expected one type/)
    end
  end
end
