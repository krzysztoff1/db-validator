# frozen_string_literal: true

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
          "#{error.attribute} #{message} (actual value: #{field_value.inspect})"
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

    def generate_text_report
      report = StringIO.new
      report.puts "DbValidator Report"
      report.puts "=================="
      report.puts

      if @invalid_records.empty?
        report.puts "No invalid records found."
      else
        report.puts "Found invalid records:"
        report.puts

        @invalid_records.group_by { |r| r[:model] }.each do |model, records|
          report.puts "#{model}: #{records.count} invalid records"
          records.each do |record|
            report.puts "  ID: #{record[:id]}"
            record[:errors].each do |error|
              report.puts "    - #{error}"
            end
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
