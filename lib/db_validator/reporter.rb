# frozen_string_literal: true

require "tty-box"
require "tty-spinner"
require "db_validator/formatters/json_formatter"
require "db_validator/formatters/message_formatter"

module DbValidator
  class Reporter
    def initialize
      @invalid_records = []
    end

    def add_invalid_record(record)
      formatter = Formatters::MessageFormatter.new(record)
      enhanced_errors = record.errors.map do |error|
        field_value = record.send(error.attribute)
        message = error.message
        formatter.format_error_message(error, field_value, message)
      end

      @invalid_records << {
        model: record.class.name,
        id: record.id,
        errors: enhanced_errors
      }
    end

    def generate_report_message(error, field_value, message)
      formatter = Formatters::MessageFormatter.new(record)
      formatter.format_error_message(error, field_value, message)
    end

    def generate_report
      case DbValidator.configuration.report_format
      when :json
        Formatters::JsonFormatter.new(@invalid_records).format
      else
        generate_text_report
      end
    end

    private

    def generate_text_report
      print_title

      report = StringIO.new

      if @invalid_records.empty?
        report.puts "No invalid records found."
        return report.string
      end

      report.puts print_summary
      report.puts

      @invalid_records.group_by { |r| r[:model] }.each do |model, records|
        report.puts generate_model_report(model, records)
      end

      report.string
    end

    def print_summary
      report = StringIO.new
      is_plural = @invalid_records.count > 1
      record_word = is_plural ? "records" : "record"
      model_word = is_plural ? "models" : "model"

      report.puts "Found #{@invalid_records.count} invalid #{record_word} across #{@invalid_records.group_by do |r|
        r[:model]
      end.keys.count} #{model_word}"

      report.string
    end

    def generate_model_report(model, records)
      report = StringIO.new
      report.puts
      report.puts "#{model}: #{records.count} invalid #{records.count == 1 ? 'record' : 'records'}"
      report.puts

      records.each_with_index do |record, index|
        report.puts generate_record_report(record, index)
      end

      report.string
    end

    def generate_record_report(record, index)
      report = StringIO.new
      record_obj = fetch_record_object(record)
      info = collect_record_info(record_obj, record, index)

      report.puts "  #{info.join(', ')}"
      add_error_messages(report, record[:errors])

      report.string
    end

    def fetch_record_object(record)
      record[:model].constantize.find_by(id: record[:id])
    end

    def collect_record_info(record_obj, record, index)
      info = []
      info << "Record ##{index + 1}"
      info << "ID: #{record[:id]}"

      add_timestamp_info(info, record_obj)
      add_identifying_fields(info, record_obj)

      info
    end

    def add_timestamp_info(info, record_obj)
      if record_obj.respond_to?(:created_at)
        info << "Created: #{record_obj.created_at.strftime('%b %d, %Y at %I:%M %p')}"
      end
      return unless record_obj.respond_to?(:updated_at)

      info << "Updated: #{record_obj.updated_at.strftime('%b %d, %Y at %I:%M %p')}"
    end

    def add_identifying_fields(info, record_obj)
      info << "Name: #{record_obj.name}" if record_obj.respond_to?(:name) && record_obj.name.present?
      info << "Title: #{record_obj.title}" if record_obj.respond_to?(:title) && record_obj.title.present?
    end

    def add_error_messages(report, errors)
      errors.each do |error|
        report.puts "    \e[31m- #{error}\e[0m"
      end
    end

    def print_title
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

      puts
      puts title_box
      puts
    end
  end
end
