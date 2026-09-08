# frozen_string_literal: true

require_relative '../../lib/low_type'

RSpec.describe 'ractor_safe!' do
  # Lowkey.make_shareable! freezes the *entire shared* registry -- every other fixture
  # in the suite lives in it too. Proving cross-Ractor callability in-process would mean
  # either wiping that registry (breaking any later spec that expects an already-loaded
  # fixture still cached, without re-`Lowkey.load`ing it) or leaving it frozen (breaking
  # any later spec that loads a new fixture at all). Running the actual Ractor proof in
  # a subprocess sidesteps that entirely -- nothing about the shared suite process's
  # Lowkey.keys is touched.
  def run_in_subprocess(fixture_path, class_name)
    output = `bundle exec ruby -I lib -e "
      require_relative '#{fixture_path}'
      # Simulates low-rb/low_type#50 (clearing class_proxy.class_binding once a class has
      # finished loading) inline, rather than depending on that PR having landed here too --
      # a live Binding can never be made Ractor-shareable, even frozen, so without this
      # Lowkey.make_shareable! would raise for any class_proxy LowType has touched.
      Lowkey['#{fixture_path}.rb']['#{class_name}'].class_binding = nil
      Lowkey.make_shareable!
      ractor = Ractor.new { #{class_name}.new.greet('Hi') }
      puts ractor.take
    " 2>&1`
    output.lines.last&.strip
  end

  context 'with type checking enabled' do
    subject(:instance) { RactorSafeTyped.new }

    LowType.configure { |config| config.type_checking = true }
    require_relative '../fixtures/ractor_safe_typed'

    it 'still validates params like a normal typed method' do
      expect(instance.greet('Hi')).to eq('Hi')
      expect { instance.greet(123) }.to raise_error(Low::ArgumentTypeError)
    end

    it 'is callable from a worker Ractor once Lowkey is made shareable' do
      expect(run_in_subprocess('spec/fixtures/ractor_safe_typed', 'RactorSafeTyped')).to eq('Hi')
    end
  end

  context 'with type checking disabled' do
    subject(:instance) { RactorSafeUntyped.new }

    LowType.configure { |config| config.type_checking = false }
    require_relative '../fixtures/ractor_safe_untyped'
    LowType.configure { |config| config.type_checking = true }

    it 'still passes through untyped, unvalidated' do
      expect(instance.greet(123)).to eq(123)
    end

    it 'is callable from a worker Ractor once Lowkey is made shareable' do
      expect(run_in_subprocess('spec/fixtures/ractor_safe_untyped', 'RactorSafeUntyped')).to eq('Hi')
    end
  end
end
