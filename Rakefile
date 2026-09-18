# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

namespace :spec do
  desc 'Run specs with type_checking examples activated'
  task :type_checking do
    sh({ 'TYPE_CHECKING' => 'true' }, 'bundle exec rspec')
  end

  desc 'Run specs with type checking disabled via shim method'
  task :shim do
    sh({ 'TYPE_CHECKING' => 'false', 'DISABLE_MODE' => 'shim' }, 'bundle exec rspec')
  end

  desc 'Run specs with type checking disabled via strip method'
  task :strip do
    sh({ 'TYPE_CHECKING' => 'false', 'DISABLE_MODE' => 'strip' }, 'bundle exec rspec')
  end

  desc 'Run the full suite once per type_checking state'
  task all: %i[type_checking shim strip]
end

task default: 'spec:all'
