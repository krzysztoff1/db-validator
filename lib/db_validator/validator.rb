# frozen_string_literal: true

require "ruby-progressbar"

module DbValidator
  class Validator
    attr_reader :reporter

    def initialize(options = {})
      configure_from_options(options)
      @reporter = Reporter.new
    end

    def validate_all
      models = models_to_validate
      invalid_count = 0

      models.each do |model|
        model_count = validate_model(model)
        invalid_count += model_count if model_count
      end

      if invalid_count.zero?
        Rails.logger.debug "\nValidation passed! All records are valid."
      else
        total_records = models.sum(&:count)
        is_plural = invalid_count > 1
        Rails.logger.debug do
          "\nFound #{invalid_count} invalid #{is_plural ? 'records' : 'record'} out of #{total_records} total #{is_plural ? 'records' : 'record'}."
        end
      end

      @reporter.generate_report
    end

    def validate_test_model(model_name)
      model = model_name.constantize
      scope = model.all
      scope = scope.limit(DbValidator.configuration.limit) if DbValidator.configuration.limit

      total_count = scope.count
      progress_bar = create_progress_bar("Testing #{model.name}", total_count)
      invalid_count = 0

      begin
        scope.find_each(batch_size: DbValidator.configuration.batch_size) do |record|
          invalid_count += 1 unless validate_record(record)
          progress_bar.increment
        end
      rescue StandardError => e
        Rails.logger.debug { "Error validating #{model.name}: #{e.message}" }
      end

      if invalid_count.zero?
        Rails.logger.debug "\nValidation rule passed! All records would be valid."
      else
        Rails.logger.debug do
          "\nFound #{invalid_count} records that would become invalid out of #{total_count} total records."
        end
      end

      @reporter.generate_report
    end

    private

    def configure_from_options(options)
      return unless options.is_a?(Hash)

      DbValidator.configuration.only_models = Array(options[:only_models]) if options[:only_models]
      DbValidator.configuration.limit = options[:limit] if options[:limit]
      DbValidator.configuration.batch_size = options[:batch_size] if options[:batch_size]
      DbValidator.configuration.report_format = options[:report_format] if options[:report_format]
      DbValidator.configuration.show_records = options[:show_records] if options[:show_records]
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
        return config.only_models.map(&:downcase).include?(model_name) ||
               config.only_models.map(&:downcase).include?(model_name.singularize) ||
               config.only_models.map(&:downcase).include?(model_name.pluralize)
      end

      config.ignored_models.map(&:downcase).exclude?(model_name)
    end

    def validate_model(model)
      scope = build_scope(model)
      total_count = scope.count
      return 0 if total_count.zero?

      process_records(scope, model, total_count)
    end

    def build_scope(model)
      scope = model.all
      scope = scope.limit(DbValidator.configuration.limit) if DbValidator.configuration.limit
      scope
    end

    def process_records(scope, model, total_count)
      progress_bar = create_progress_bar(model.name, total_count)
      process_batches(scope, progress_bar, model)
    end

    def process_batches(scope, progress_bar, model)
      invalid_count = 0
      batch_size = DbValidator.configuration.batch_size || 100

      begin
        scope.find_in_batches(batch_size: batch_size) do |batch|
          invalid_count += process_batch(batch, progress_bar)
        end
      rescue StandardError => e
        Rails.logger.debug { "Error validating #{model.name}: #{e.message}" }
      end

      invalid_count
    end

    def process_batch(batch, progress_bar)
      invalid_count = 0
      batch.each do |record|
        invalid_count += 1 unless validate_record(record)
        progress_bar.increment
      end
      invalid_count
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
      return true if record.valid?

      @reporter.add_invalid_record(record)
      false
    end

    def models_to_validate
      models = find_all_models
      models.select { |model| should_validate_model?(model) }
    end
  end
end
