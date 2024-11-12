# frozen_string_literal: true

module DbValidator
  class ValidateTask
    def initialize(cli = DbValidator::CLI.new)
      @cli = cli
    end

    def execute
      configure_from_env_or_cli
      run_validation
    end

    private

    def configure_from_env_or_cli
      if env_args_present?
        configure_from_env
      else
        configure_from_cli
      end
    end

    def env_args_present?
      ENV["models"].present? || ENV["limit"].present? ||
        ENV["format"].present? || ENV["show_records"].present?
    end

    def configure_from_env
      if ENV["models"].present?
        models = ENV["models"].split(",").map(&:strip).map(&:classify)
        DbValidator.configuration.only_models = models
      end

      ConfigUpdater.update_from_env
    end

    def configure_from_cli
      @cli.display_progress("Loading models") { Rails.application.eager_load! }

      available_models = ActiveRecord::Base.descendants
                                           .reject(&:abstract_class?)
                                           .select(&:table_exists?)
                                           .map(&:name)
                                           .sort

      selected_models = @cli.select_models(available_models)
      options = @cli.configure_options

      DbValidator.configuration.only_models = selected_models
      ConfigUpdater.update_from_options(options)
    end

    def run_validation
      validator = DbValidator::Validator.new
      report = validator.validate_all
      puts report
    end
  end
end
