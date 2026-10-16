# frozen_string_literal: true

require 'rack/test'
require_relative '../fixtures/union_types'
require_relative '../fixtures/sinatra_app'

RSpec.describe 'Lowkey.clear' do
  include Rack::Test::Methods

  let(:app) { SinatraApp.new }

  # Other specs look up the evaluated proxies of fixtures in Lowkey's cache, so restore it afterwards.
  around do |example|
    keys = Lowkey.keys.transform_values { |value| value.is_a?(Array) ? value.dup : value }
    kept = Lowkey.kept.dup
    Lowkey.clear(keep: false)

    example.run
  ensure
    Lowkey.keys.replace(keys)
    Lowkey.kept.replace(kept)
  end

  it 'does not need Lowkey to type check methods' do
    expect(UnionTypes.new.multiple_typed_args('Shalom')).to eq('Shalom')
  end

  it 'does not need Lowkey to type check Sinatra routes', type_checking: true do
    expect(Lowkey).not_to receive(:[])

    get '/!string'
    expect(last_response.body).to include('Invalid return type')
  end
end
