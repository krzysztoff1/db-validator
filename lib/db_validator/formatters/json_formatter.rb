# frozen_string_literal: true

require "json"
require "fileutils"

module DbValidator
  module Formatters
    class JsonFormatter
      def initialize(invalid_records)
        @invalid_records = invalid_records
      end

      def format
        formatted_data = @invalid_records.group_by { |r| r[:model] }.transform_values do |records|
          {
            error_count: records.length,
            records: records.map { |r| format_record(r) }
          }
        end

        save_to_file(formatted_data)
        formatted_data.to_json
      end

      private

      def format_record(record)
        {
          id: record[:id],
          errors: record[:errors]
        }
      end

      def save_to_file(data)
        FileUtils.mkdir_p("db_validator_reports")
        timestamp = Time.zone.now.strftime("%Y%m%d_%H%M%S")
        filename = "db_validator_reports/validation_report_#{timestamp}.json"

        File.write(filename, JSON.pretty_generate(data))
        Rails.logger.info "JSON report saved to #{filename}"
      end
    end
  end
end
