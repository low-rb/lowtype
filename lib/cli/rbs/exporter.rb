# frozen_string_literal: true

require 'fileutils'
require 'lowkey'
require 'lowload'

require_relative 'class_sig'

module LowType
  module CLI
    module RBS
      class MissingPathError < StandardError; end

      # Exports .rbs files for every class in `path` (a file or directory) that includes LowType.
      # Uses LowLoad to autoload missing constants from files within the same directory.
      module Exporter
        class << self
          def export(path:, boot: nil)
            LowLoad.dirload(path).loaded_paths.each do |file_path, adapter|
              next unless file_path.end_with?('.rb') || file_path.end_with?('.rbx')

              export_file(file_path:)
            end
          end

          private

          def export_file(file_path:)
            return unless file_proxy = ::Lowkey[file_path]

            class_proxies = typed_class_proxies(file_proxy)
            return if class_proxies.empty?

            content = class_proxies.map do |class_proxy|
              ClassSig.build(class_proxy:, file_proxy:)
            end.join("\n\n")

            save_file(file_path:, content:)
          end

          def typed_class_proxies(file_proxy)
            file_proxy.definitions.values.filter do |proxy|
              includes_lowtype = proxy.lines[proxy.start_line..proxy.end_line].find do |line|
                line.include?('include LowType')
              end

              proxy.is_a?(::Lowkey::ClassProxy) && includes_lowtype
            end
          end

          def save_file(file_path:, content:)
            sig_path = sig_path(file_path:)
            FileUtils.mkdir_p(File.dirname(sig_path))
            File.write(sig_path, "#{content}\n")

            puts "Exported #{sig_path}"
          end

          def sig_path(file_path:)
            relative = file_path.delete_prefix("#{Dir.pwd}/").delete_prefix('lib/')
            File.join('sig', relative.sub(/\.rb\z/, '.rbs'))
          end
        end
      end
    end
  end
end
