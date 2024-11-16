# frozen_string_literal: true

module DbValidator
  module Formatters
    class MessageFormatter
      def initialize(record)
        @record = record
      end

      def format_error_message(error, field_value, message)
        return enum_validation_message(error, field_value, message) if error.options[:in].present?
        return enum_field_message(error, field_value, message) if enum_field?(error)

        basic_validation_message(error, field_value, message)
      end

      private

      attr_reader :record

      def enum_validation_message(error, field_value, message)
        allowed = error.options[:in].join(", ")
        error_message = "#{error.attribute} #{message}"
        details = " (allowed values: #{allowed}, actual value: #{field_value.inspect})"

        "#{error_message} #{details}"
      end

      def enum_field_message(error, field_value, message)
        enum_values = record.class.defined_enums[error.attribute.to_s].keys
        error_message = "#{error.attribute} #{message}"
        details = " (allowed values: #{enum_values.join(', ')}, actual value: #{field_value.inspect})"

        "#{error_message} #{details}"
      end

      def enum_field?(error)
        record.class.defined_enums[error.attribute.to_s].present?
      end

      def basic_validation_message(error, field_value, message)
        "#{error.attribute} #{message} (actual value: #{format_value(field_value)})"
      end

      def format_value(value)
        case value
        when true, false, Symbol
          value.to_s
        when String
          "\"#{value}\""
        when nil
          "nil"
        else
          value
        end
      end
    end
  end
end
