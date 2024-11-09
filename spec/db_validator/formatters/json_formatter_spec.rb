# frozen_string_literal: true

require "spec_helper"

RSpec.describe DbValidator::Formatters::JsonFormatter do
  describe "#format" do
    let(:invalid_records) do
      [
        { model: "Skill", id: 1, errors: ["name can't be blank"] },
        { model: "Skill", id: 2, errors: ["name can't be blank"] },
        { model: "User", id: 1, errors: ["email is invalid"] }
      ]
    end

    before do
      # Clean up any existing reports
      FileUtils.rm_rf("db_validator_reports")
    end

    after do
      # Clean up after tests
      FileUtils.rm_rf("db_validator_reports")
    end

    it "formats invalid records into grouped JSON with error counts" do
      formatter = described_class.new(invalid_records)
      result = JSON.parse(formatter.format)

      expect(result["Skill"]["error_count"]).to eq(2)
      expect(result["Skill"]["records"].length).to eq(2)
      expect(result["User"]["error_count"]).to eq(1)
      expect(result["User"]["records"].length).to eq(1)
    end

    it "saves the report to a file in the working directory" do
      formatter = described_class.new(invalid_records)
      formatter.format

      # Check if reports directory was created
      expect(Dir.exist?("db_validator_reports")).to be true

      # Check if a report file was created
      report_files = Dir["db_validator_reports/validation_report_*.json"]
      expect(report_files).not_to be_empty

      # Verify file content
      file_content = JSON.parse(File.read(report_files.first))
      expect(file_content["Skill"]["error_count"]).to eq(2)
      expect(file_content["User"]["error_count"]).to eq(1)
    end
  end
end
