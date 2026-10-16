# frozen_string_literal: true

require_relative '../expressions/type_expression'
require_relative '../proxies/return_proxy'
require_relative '../queries/type_query'

module Low
  # Usage:
  #
  # type_accessor name: String # => @name getter and @name=() setter
  # type_accessor name: String | 'Cher'
  #
  # type_reader name: String
  # type_reader name: String | 'Cher' # defaults to 'Cher' if nil
  #
  # type_writer name: String
  # type_writer name: String | nil # accepts String or nil
  #
  module TypeAccessors
    class << self
      # Expressions by file path and line, so that tools like TypeStripper can find the expressions of a type accessor.
      def expressions
        @expressions ||= {}
      end

      # A default value is returned when the instance variable is nil. Mutable defaults are new copies each time.
      def default_value(expression:)
        return nil if expression.required?

        value = expression.default_value
        value.is_a?(ValueExpression) ? value : value.dup
      end
    end

    def type_reader(named_expressions)
      location = caller_locations(1, 1).first
      named_expressions.each { |name, expression| define_type_reader(name:, expression:, location:) }
    end

    def type_writer(named_expressions)
      location = caller_locations(1, 1).first
      named_expressions.each { |name, expression| define_type_writer(name:, expression:, location:) }
    end

    def type_accessor(named_expressions)
      location = caller_locations(1, 1).first

      named_expressions.each do |name, expression|
        define_type_reader(name:, expression:, location:)
        define_type_writer(name:, expression:, location:)
      end
    end

    private

    def define_type_reader(name:, expression:, location:)
      expression = register(name:, expression:, location:)
      proxy = ::Lowkey::ReturnProxy.new(name:, source: accessor_source(name:, location:), expression:)

      define_method(name) do
        value = instance_variable_get("@#{name}")
        value = TypeAccessors.default_value(expression:) if value.nil?

        expression.validate!(value:, proxy:)
        value.is_a?(ValueExpression) ? value.value : value
      end
    end

    def define_type_writer(name:, expression:, location:)
      expression = register(name:, expression:, location:)
      proxy = ::Lowkey::ParamProxy.new(name:, source: accessor_source(name:, location:), type: :pos_req, position: nil, expression:)

      define_method("#{name}=") do |value|
        expression.validate!(value:, proxy:)
        instance_variable_set("@#{name}", value)
      end
    end

    def register(name:, expression:, location:)
      expression = cast_type_expression(expression)
      expressions = TypeAccessors.expressions[[location.path, location.lineno]] ||= {}
      expressions[name] = expression
    end

    # Type accessors are defined on class load (not file load) so Source needs to be simulated.
    def accessor_source(name:, location:)
      line = location.lineno
      ::Lowkey::Source.new(file_path: location.path, scope: "#{self}##{name}", lines: [], start_line: line, end_line: line)
    end

    def cast_type_expression(expression)
      if expression.is_a?(::Expressions::Expression)
        expression
      elsif TypeQuery.type?(expression)
        TypeExpression.new(type: expression)
      end
    end
  end
end
