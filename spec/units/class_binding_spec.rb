# frozen_string_literal: true

require_relative '../../lib/low_type'
require_relative '../fixtures/return_types'

RSpec.describe 'class_proxy.class_binding' do
  subject(:class_proxy) { Lowkey['spec/fixtures/return_types.rb']['ReturnTypes'] }

  it 'is cleared once the class has finished loading' do
    # class_binding's only job is evaluating default/type-expression values against the
    # class's own lexical scope, done once while the class body loads. A live Binding can
    # never be made Ractor-shareable (even frozen), so leaving one behind on class_proxy
    # would permanently block sharing Lowkey's registry across Ractors.
    expect(class_proxy.class_binding).to be_nil
  end
end
