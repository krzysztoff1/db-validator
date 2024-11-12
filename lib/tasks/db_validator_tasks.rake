# frozen_string_literal: true

namespace :db_validator do
  desc "Validate records in the database"
  task validate: :environment do
    DbValidator::ValidateTask.new.execute
  end

  desc "Test validation rules on existing records"
  task test: :environment do
    unless ENV["model"] && ENV["rule"]
      puts "Usage: rake db_validator:test model=user rule='validates :field, presence: true' [show_records=false] [limit=1000] [format=json]"
      raise "No models found in the application. Please run this command from your Rails application root."
    end

    model_name = ENV.fetch("model").classify
    validation_rule = ENV.fetch("rule", nil)

    DbValidator.configuration.show_records = ENV["show_records"] != "false" if ENV["show_records"].present?
    DbValidator.configuration.limit = ENV["limit"].to_i if ENV["limit"].present?
    DbValidator.configuration.report_format = ENV["format"].to_sym if ENV["format"].present?

    DbValidator::TestTask.new(model_name, validation_rule).execute
  end
end
