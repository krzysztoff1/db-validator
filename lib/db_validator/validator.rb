# frozen_string_literal: true

require "ruby-progressbar"
require "colorize"

module DbValidator
  class Validator
    def initialize(options = {})
      @options = options
      @reporter = Reporter.new
      @fixer = Fixer.new if DbValidator.configuration.auto_fix
    end

    def validate_all
      Rails.application.eager_load! if defined?(Rails)

      models = find_all_models

      models_to_validate = models.select { |model| should_validate_model?(model) }
      total_models = models_to_validate.size

      models_to_validate.each_with_index do |model, index|
        Rails.logger.debug "Validating model #{index + 1}/#{total_models}: #{model.name}".colorize(:cyan)
        validate_model(model)
      end

      @reporter.generate_report
    end

    private

    def find_all_models
      # Include all classes inheriting from ActiveRecord::Base
      ObjectSpace.each_object(Class).select do |klass|
        klass < ActiveRecord::Base
      end
    end

    def should_validate_model?(model)
      return false if model.abstract_class?
      return false unless model.table_exists?

      config = DbValidator.configuration
      model_name = model.name.downcase
      return config.only_models.include?(model_name) if config.only_models.any?

      config.ignored_models.exclude?(model_name)
    end

    def validate_model(model)
      limit = DbValidator.configuration.limit
      total_records = limit || model.count

      if total_records.zero?
        Rails.logger.debug { "No records to validate for model #{model.name}." }
        return
      end

      processed_records = 0

      query = model.all
      query = query.limit(limit) if limit

      query.find_in_batches(batch_size: DbValidator.configuration.batch_size) do |batch|
        batch.each do |record|
          validate_record(record)
          processed_records += 1
          if (processed_records % 100).zero? || processed_records == total_records
            Rails.logger.debug "Validated #{processed_records}/#{total_records} records for model #{model.name}".colorize(:green)
          end
        end
      rescue StandardError => e
        Rails.logger.debug "Error validating #{model.name}: #{e.message}".colorize(:red)
      end
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.debug { "Skipping validation for #{model.name}: #{e.message}" }
    end

    def validate_record(record)
      return if record.valid?

      @reporter.add_invalid_record(record)
      @fixer&.attempt_fix(record)
    end
  end
end
