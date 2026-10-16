# frozen_string_literal: true

require_relative 'sinatra_adapter'

module Low
  module Adapter
    class Loader
      class << self
        def load(klass:, class_proxy:)
          ancestors = klass.ancestors.map(&:to_s)

          return unless ancestors.include?('Sinatra::Base')

          klass.prepend SinatraAdapter.new.module(class_proxy:)
        end
      end
    end
  end
end
