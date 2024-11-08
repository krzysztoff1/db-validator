# frozen_string_literal: true

namespace :db_validator do
  desc "Validate records in the database"
  task validate: :environment do
    cli = DbValidator::CLI.new

    has_any_args = ENV["models"].present? || ENV["limit"].present? || ENV["format"].present?

    if has_any_args
      if ENV["models"].present?
        models = ENV["models"].split(",").map(&:strip).map(&:classify)
        DbValidator.configuration.only_models = models
      end

      DbValidator.configuration.limit = ENV["limit"].to_i if ENV["limit"].present?
      DbValidator.configuration.report_format = ENV["format"].to_sym if ENV["format"].present?
    else
      cli.display_progress("Loading models") do
        Rails.application.eager_load!
      end

      available_models = ActiveRecord::Base.descendants
                                           .reject(&:abstract_class?)
                                           .select(&:table_exists?)
                                           .map(&:name)
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
