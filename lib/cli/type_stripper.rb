# frozen_string_literal: true

require 'fileutils'
require 'lowkey'

require_relative '../definitions/type_accessors'
require_relative '../queries/file_query'

module LowType
  # Removes LowType from source files, leaving plain Ruby:
  #   method: def greet(name = String | 'World') -> { String }  =>  def greet(name = 'World')
  #   variable: greeting = type String | 'Hello'                =>  greeting = 'Hello'
  #   accessor: type_accessor name: String                      =>  attr_accessor :name
  #
  # Files are loaded into Ruby to evaluate args and decide a type from a default value. Slim syntax may reduce this need.
  # Lowkey then rewrites the method signatures and method calls.
  module TypeStripper
    LOWTYPE_PATTERN = /^\s*include\s+LowType\b/
    REQUIRE_PATTERN = /\A['"][^'"]*(?:lowtype|low_type)['"]\z/
    ACCESSOR_METHODS = { type_reader: 'attr_reader', type_writer: 'attr_writer', type_accessor: 'attr_accessor' }.freeze
    TYPE_METHODS = %i[type low_type].freeze

    module_function

    def export(src:, dest:)
      src = File.expand_path(src)
      dest = File.expand_path(dest)

      # Stripping reads method calls from their Prism nodes, which Lowkey releases once a file loads by default.
      keeping_nodes do
        file_paths(src:, dest:).each do |file_path|
          dest_path = File.file?(src) ? dest : File.join(dest, file_path.delete_prefix(src))
          next copy(file_path:, dest_path:) unless file_path.end_with?('.rb') && File.read(file_path).match?(LOWTYPE_PATTERN)

          export_file(file_path:, dest_path:)
        end
      end
    end

    def keeping_nodes
      release_nodes = ::Lowkey.config.release_nodes
      ::Lowkey.config.release_nodes = false
      yield
    ensure
      ::Lowkey.config.release_nodes = release_nodes
    end

    def export_file(file_path:, dest_path:)
      stripped = strip(file_path:)
      write(path: dest_path, content: stripped)

      puts "Stripped #{dest_path}"
      warn "lowtype: Kept LowType in #{dest_path} as some type accessors have default values" if stripped.match?(LOWTYPE_PATTERN)
    rescue ScriptError, StandardError => e
      warn "lowtype: Skipped #{file_path} as it could not be loaded (#{e.class}: #{e.message.lines.first&.strip})"
      copy(file_path:, dest_path:)
    end

    # Excludes the destination when it's inside the source, so that a previous export isn't exported again.
    def file_paths(src:, dest: nil)
      return [src] if File.file?(src)

      Dir.glob('**/*', File::FNM_DOTMATCH, base: src).filter_map do |path|
        file_path = File.join(src, path)
        next if path.split('/').intersect?(%w[. .. .git]) || (dest != src && file_path.start_with?("#{dest}/"))

        file_path if File.file?(file_path)
      end
    end

    def strip(file_path:)
      require file_path
      raise ::Low::MissingFileError, "LowType did not load #{file_path}" unless (file_proxy = ::Lowkey[file_path])

      # Method calls first, as a method call can be on the same line as a signature: "def method(arg = Type) = type(...)".
      rewrite_method_calls(method_calls: file_proxy.definitions.values.flat_map(&:method_calls), file_path:)
      method_proxies(file_proxy:).each { |method_proxy| method_proxy.rewrite_signature if method_proxy.expressions? }

      file_proxy.lines.join
    end

    # Instance and class methods with the same name share a key in "keyed_methods".
    def method_proxies(file_proxy:)
      file_proxy.definitions.values.flat_map { |proxy| [*proxy.keyed_methods.values, *proxy.class_methods.values] }.uniq
    end

    # Method calls on the same line are rewritten from last to first so that their offsets stay valid.
    # Type accessors with default values keep LowType included.
    def rewrite_method_calls(method_calls:, file_path:)
      # Filter before sorting, so that only the method calls being rewritten build their source.
      method_calls = method_calls.filter { |method_call| rewritable?(method_call:) }

      accessors = method_calls.filter { |method_call| accessor?(method_call:) }
      attributes = accessors.filter { |method_call| attribute?(method_call:, file_path:) }
      keep_lowtype = attributes.count < accessors.count

      method_calls.sort_by { |method_call| -method_call.start_offset }.each do |method_call|
        rewrite_method_call(method_call:, attribute: attributes.include?(method_call), keep_lowtype:)
      end
    end

    def rewritable?(method_call:)
      local_type?(method_call:) || accessor?(method_call:) || lowtype?(method_call:)
    end

    def rewrite_method_call(method_call:, attribute:, keep_lowtype:)
      if local_type?(method_call:)
        method_call.rewrite(method_call.default)
      elsif attribute
        method_call.rewrite("#{ACCESSOR_METHODS[method_call.name]} #{method_call.keywords.map(&:inspect).join(', ')}")
      elsif !keep_lowtype && lowtype?(method_call:)
        method_call.remove
      end
    end

    # "type String | 'Hello'" becomes "'Hello'".
    def local_type?(method_call:)
      !method_call.receiver? && TYPE_METHODS.include?(method_call.name) && !method_call.default.nil?
    end

    # Only symbol keys can become attribute names. A double splat like "**expressions" can't be converted.
    def accessor?(method_call:)
      !method_call.receiver? && ACCESSOR_METHODS.key?(method_call.name)
    end

    # Type accessors are attributes when they have no default value. Their expressions are evaluated on class load.
    def attribute?(method_call:, file_path:)
      return false unless method_call.arguments.one? && method_call.keywords
      return false unless (expressions = ::Low::TypeAccessors.expressions[[file_path, method_call.start_line]])

      expressions.values.all? { |expression| expression.required? || expression.default_value.nil? }
    end

    # "include LowType", "using LowType::Syntax" and "require 'lowtype'".
    def lowtype?(method_call:)
      return false if method_call.receiver?

      case method_call.name
      when :include then method_call.arguments == ['LowType']
      when :using then method_call.arguments == ['LowType::Syntax']
      when :require, :require_relative then method_call.arguments.one? && method_call.arguments.first.match?(REQUIRE_PATTERN)
      else false
      end
    end

    def write(path:, content:)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
    end

    def copy(file_path:, dest_path:)
      return if dest_path == file_path

      FileUtils.mkdir_p(File.dirname(dest_path))
      FileUtils.cp(file_path, dest_path, preserve: true)
    end
  end
end
