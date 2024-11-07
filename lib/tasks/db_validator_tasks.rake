# frozen_string_literal: true

namespace :db_validator do
  desc "Validate all records in the database"
  task validate: :environment do
    cli = DbValidator::CLI.new

    has_any_args = ENV["models"] || ENV["limit"] || ENV["batch_size"] || ENV["format"]

    if has_any_args
      models = ENV["models"].split(",").map(&:strip).map(&:downcase).map(&:singularize)

      DbValidator.configuration.only_models = models
      DbValidator.configuration.limit = ENV["limit"].to_i if ENV["limit"].present?
      DbValidator.configuration.batch_size = ENV["batch_size"].to_i if ENV["batch_size"].present?
      DbValidator.configuration.report_format = ENV["format"].to_sym if ENV["format"].present?
    else
      cli.display_progress("Loading models") do
        Rails.application.eager_load!
      end

      available_models = ActiveRecord::Base.descendants
        .reject(&:abstract_class?)
        .select(&:table_exists?)
        .map { |m| m.name }
        .sort

      selected_models = cli.select_models(available_models)
      options = cli.configure_options

      DbValidator.configuration.only_models = selected_models
      DbValidator.configuration.limit = options[:limit] if options[:limit].present?
      DbValidator.configuration.batch_size = options[:batch_size] if options[:batch_size].present?
      DbValidator.configuration.report_format = options[:format].to_sym if options[:format].present?
    end

    validator = DbValidator::Validator.new
    report = validator.validate_all
    puts "\n#{report}"
  end
end
