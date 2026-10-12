# frozen_string_literal: true

require 'trees'

require_relative 'rbs/exporter'
require_relative 'type_stripper'

module LowType
  module CLI
    extend Trees

    line('rbs :src') do |src|
      s { 'Exports files from the source to type signatures in the sig directory' }
      e { 'lowtype rbs app' }
      x { RBS::Exporter.export(path: src) }

      line('--boot', '-b') do |src, boot|
        s { 'Runs a file before export and could be used to load constants outside your source directory' }
        e { 'lowtype rbs app --boot config/boot.rb' }
        x { RBS::Exporter.export(path: src, boot:) }
      end
    end

    line('strip!') do
      s { 'Strips files from the current directory of their types' }
      e { 'lowtype strip' }
      x { TypeStripper.export(src: '.', dest: '.') }
    end

    line('strip :src :dest') do |src, dest|
      s { 'Exports files from the source directory to a destination directory with types stripped' }
      e { 'lowtype strip src/app dest/app' }
      x { TypeStripper.export(src:, dest:) }
    end
  end
end
