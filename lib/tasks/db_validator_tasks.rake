# frozen_string_literal: true

namespace :db_validator do
  desc "Validate all records in the database"
  task validate: :environment do
    if ENV["models"]
      models = ENV["models"].split(",").map(&:strip).map(&:downcase).map(&:singularize)
      DbValidator.configuration.only_models = models
    end

    DbValidator.configuration.limit = ENV["limit"].to_i if ENV["limit"]

    DbValidator.configuration.report_format = ENV["format"].to_sym if ENV["format"]

    DbValidator.configuration.batch_size = ENV["batch_size"].to_i if ENV["batch_size"]

    validator = DbValidator::Validator.new
    report = validator.validate_all
    puts report
  end
end
