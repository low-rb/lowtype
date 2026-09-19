# frozen_string_literal: true

require_relative 'lib/version'

Gem::Specification.new do |spec|
  spec.name = 'lowtype'
  spec.version = Low::Type::VERSION
  spec.authors = ['maedi']
  spec.email = ['maediprichard@gmail.com']

  spec.summary = 'Elegant types in Ruby'
  spec.description = <<~TEXT
    LowType introduces the concept of "type expressions" in method arguments. 
    When an argument's default value resolves to a type instead of a value then it's treated as a type expression. 
    Now you can have types in Ruby in the simplest syntax possible
  TEXT
  spec.homepage = 'https://github.com/low-rb/lowtype'
  spec.required_ruby_version = '>= 3.3.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/low-rb/lowtype/src/branch/main'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('lib/**/*')
  end

  spec.require_paths = ['lib']
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }

  spec.add_dependency 'expressions', '~> 0.1'
  spec.add_dependency 'lowkey', '~> 0.4'
  spec.add_dependency 'trees'
end
