# frozen_string_literal: true

require "ruby-progressbar"
require "colorize"

module DbValidator
  class Validator
    attr_reader :reporter

    def initialize(options = {})
      @options = options
      @reporter = Reporter.new
      configure_from_options(options)
    end

    def validate_all
      Rails.application.eager_load! if defined?(Rails)

      models = find_all_models
      models_to_validate = models.select { |model| should_validate_model?(model) }
      total_models = models_to_validate.size

      if models_to_validate.empty?
        Rails.logger.debug "No models selected for validation.".colorize(:yellow)
        return @reporter.generate_report
      end

      models_to_validate.each_with_index do |model, index|
        Rails.logger.debug "Validating model #{index + 1}/#{total_models}: #{model.name}".colorize(:cyan)
        validate_model(model)
      end

      @reporter.generate_report
    end

    private

    def configure_from_options(options)
      return unless options.is_a?(Hash)

      if options[:only_models]
        DbValidator.configuration.only_models = Array(options[:only_models])
      end
      
      DbValidator.configuration.limit = options[:limit] if options[:limit]
      DbValidator.configuration.batch_size = options[:batch_size] if options[:batch_size]
      DbValidator.configuration.report_format = options[:report_format] if options[:report_format]
    end

    def find_all_models
      ObjectSpace.each_object(Class).select do |klass|
        klass < ActiveRecord::Base
      end
    end

    def should_validate_model?(model)
      return false if model.abstract_class?
      return false unless model.table_exists?

      config = DbValidator.configuration
      model_name = model.name.downcase
      
      if config.only_models.any?
        return config.only_models.map(&:downcase).include?(model_name)
      end

      !config.ignored_models.map(&:downcase).include?(model_name)
    end

    def validate_model(model)
      config = DbValidator.configuration
      batch_size = config.batch_size || 1000
      limit = config.limit

      scope = model.all
      scope = scope.limit(limit) if limit

      total_count = scope.count
      return if total_count.zero?

      progress_bar = create_progress_bar(model.name, total_count)

      begin
        scope.find_in_batches(batch_size: batch_size) do |batch|
          batch.each do |record|
            validate_record(record)
            progress_bar.increment
          end
        end
      rescue StandardError => e
        Rails.logger.debug "Error validating #{model.name}: #{e.message}".colorize(:red)
      end
    end

    def create_progress_bar(model_name, total)
      ProgressBar.create(
        title: "Validating #{model_name}",
        total: total,
        format: "%t: |%B| %p%% %e",
        output: $stderr
      )
    end

    def validate_record(record)
      return if record.valid?
      @reporter.add_invalid_record(record)
    end
  end
end
