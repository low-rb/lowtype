# frozen_string_literal: true

require 'tmpdir'

require_relative '../../lib/cli/type_stripper'

RSpec.describe LowType::TypeStripper, type_checking: true do
  let(:fixtures_path) { File.expand_path('../fixtures', __dir__) }

  describe '.strip' do
    let(:stripped) do
      <<~RUBY
        # frozen_string_literal: true

        class Strippable
          DEFAULT_TIMEOUT = 5

          attr_accessor :name, :age

          def typed_args(greeting, name = 'café', timeout = DEFAULT_TIMEOUT)
            "\#{greeting} \#{name} \#{timeout}"
          end

          def multiline_args(
            first,
            second: 2,
            third: 'untyped'
          )
            "\#{first}\#{second}\#{third}"
          end

          def own_line_return_type(value)
            value
          end

          def endless(states: %i[draft published]) = states

          def self.class_method(value = Integer) = value

          def local_type
            'Hello'
          end
        end
      RUBY
    end

    it 'strips types and LowType from a file' do
      expect(described_class.strip(file_path: File.join(fixtures_path, 'strippable.rb'))).to eq(stripped)
    end

    it 'strips every class in a file' do
      output = described_class.strip(file_path: File.join(fixtures_path, 'type_helper.rb'))

      expect(output).not_to include('LowType', 'type ')
      expect(output).to include("def subtype_array\n    [1, 2, 3]\n  end").twice
    end

    it 'resolves injected dependencies with providers' do
      output = described_class.strip(file_path: File.join(fixtures_path, 'dependency_injection.rb'))

      expect(output).to include('def dependency(dependency: Providers[:dependency])')
      expect(output).to include('def symbol_dependency(dependency: Providers[:symbol])')
    end

    context 'with type accessors' do
      let(:output) { described_class.strip(file_path: File.join(fixtures_path, 'type_accessors.rb')) }

      it 'converts type accessors without default values to attributes' do
        expect(output).to include('attr_reader :name', 'attr_writer :name', 'attr_accessor :name')
      end

      it 'keeps type accessors and LowType when there are default values' do
        expect(output).to include("type_reader name: String | 'Cher'", 'type_accessor tags: Array[String] | []', 'include LowType')
      end
    end
  end

  describe '.export' do
    around do |example|
      Dir.mktmpdir do |dir|
        @dir = dir
        example.run
      end
    end

    let(:src) { File.join(@dir, 'src') }
    let(:dest) { File.join(@dir, 'dest') }
    # A class can only be defined in one file, so each example's file needs its own class.
    let(:class_name) { "Exported#{File.basename(@dir).delete('^a-zA-Z0-9')}" }

    before do
      FileUtils.mkdir_p(File.join(src, 'nested'))
      File.write(File.join(src, 'README.md'), '# Untouched')
      File.write(File.join(src, 'nested', 'exported.rb'), <<~RUBY)
        require '#{File.expand_path('../../lib/lowtype', __dir__)}'

        class #{class_name}
          include LowType

          def greet(name = String | 'World') -> { String }
            name
          end
        end
      RUBY
    end

    it 'exports stripped files and copies other files to the destination' do
      expect { described_class.export(src:, dest:) }.to output(/Stripped/).to_stdout

      expect(File.read(File.join(dest, 'README.md'))).to eq('# Untouched')
      expect(File.read(File.join(dest, 'nested', 'exported.rb'))).to eq(<<~RUBY)
        class #{class_name}
          def greet(name = 'World')
            name
          end
        end
      RUBY
    end

    context 'when Lowkey releases nodes' do
      before { Lowkey.configure { |config| config.release_nodes = true } }
      after { Lowkey.configure { |config| config.release_nodes = false } }

      it 'keeps nodes while exporting so that method calls can be stripped' do
        expect { described_class.export(src:, dest:) }.to output(/Stripped/).to_stdout.and output('').to_stderr

        expect(File.read(File.join(dest, 'nested', 'exported.rb'))).not_to include('LowType')
        expect(Lowkey.config.release_nodes).to be(true)
      end
    end

    it 'strips files in place when the source is the destination' do
      expect { described_class.export(src:, dest: src) }.to output(/Stripped/).to_stdout

      expect(File.read(File.join(src, 'nested', 'exported.rb'))).not_to include('LowType')
    end
  end
end
