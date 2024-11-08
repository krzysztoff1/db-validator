# frozen_string_literal: true

require "tty-box"
require "tty-spinner"

module DbValidator
  class Reporter
    def initialize
      @invalid_records = []
    end

    def add_invalid_record(record)
      enhanced_errors = record.errors.map do |error|
        field_value = record.send(error.attribute)
        message = error.message

        if error.options[:in].present?
          "#{error.attribute} #{message} (allowed values: #{error.options[:in].join(', ')}, actual value: #{field_value.inspect})"
        else
          "#{error.attribute} #{message} (actual value: #{format_value(field_value)})"
        end
      end

      @invalid_records << {
        model: record.class.name,
        id: record.id,
        errors: enhanced_errors
      }
    end

    def generate_report
      case DbValidator.configuration.report_format
      when :json
        generate_json_report
      else
        generate_text_report
      end
    end

    private

    def format_value(value)
      case value
      when true, false
      when Symbol
        value.to_s
      when String
        "\"#{value}\""
      when nil
        "nil"
      else
        value
      end
    end

    def generate_text_report
      report = StringIO.new

      title_box = TTY::Box.frame(
        width: 50,
        align: :center,
        padding: [1, 2],
        title: { top_left: "DbValidator" },
        style: {
          fg: :cyan,
          border: {
            fg: :cyan
          }
        }
      ) do
        "Database Validation Report"
      end

      report.puts title_box
      report.puts

      if @invalid_records.empty?
        report.puts "No invalid records found."
      else
        report.puts "Found #{@invalid_records.count} invalid records across #{@invalid_records.group_by do |r|
          r[:model]
        end.keys.count} models"
        report.puts

        @invalid_records.group_by { |r| r[:model] }.each do |model, records|
          report.puts "#{model}: #{records.count} invalid records"
          report.puts

          records.each do |record|
            record_obj = record[:model].constantize.find_by(id: record[:id])
            next unless record_obj

            info = ["ID: #{record[:id]}"]
            if record_obj.respond_to?(:created_at)
              info << "Created: #{record_obj.created_at.strftime('%Y-%m-%d %H:%M:%S')}"
            end
            if record_obj.respond_to?(:updated_at)
              info << "Updated: #{record_obj.updated_at.strftime('%Y-%m-%d %H:%M:%S')}"
            end
            info << "Name: #{record_obj.name}" if record_obj.respond_to?(:name)
            info << "Title: #{record_obj.title}" if record_obj.respond_to?(:title)

            report.puts "  #{info.join(' | ')}"
            record[:errors].each do |error|
              report.puts "    ⚠️  #{error}"
            end
            report.puts
          end

          report.puts
        end
      end

      report.string
    end

    def generate_json_report
      @invalid_records.to_json
    end
  end
end
