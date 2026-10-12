# frozen_string_literal: true

require_relative '../../lib/expressions/type_expression'

RSpec.describe Low::TypeExpression do
  subject(:type_expression) { described_class.new(default_value: nil) }

  describe '#initialize' do
    it 'instantiates a class' do
      expect { type_expression }.not_to raise_error
    end
  end

  describe 'HIDDEN_PATHS' do
    it 'hides adapters' do
      adapters = Dir[File.expand_path('../../lib/adapters/*.rb', __dir__)]

      expect(adapters).not_to be_empty
      expect(Low::HIDDEN_PATHS).to include(*adapters)
    end

    it 'hides modules' do
      modules = %w[expressions/expression_helpers definitions/type_accessors definitions/redefiner]
      expect(Low::HIDDEN_PATHS).to include(*modules.map { |path| File.expand_path("../../lib/#{path}.rb", __dir__) })
    end

    it 'only hides files that exist' do
      expect(Low::HIDDEN_PATHS).to all(satisfy { |path| File.file?(path) })
    end
  end
end
