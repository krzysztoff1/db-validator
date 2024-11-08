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
      models = get_models_to_validate
      total_count = 0
      invalid_count = 0

      models.each do |model|
        model_count = validate_model(model)
        invalid_count += model_count if model_count
      end

      if invalid_count.zero?
        puts "\nValidation passed! All records are valid."
      else
        total_records = models.sum { |model| model.count }
        puts "\nFound #{invalid_count} invalid records out of #{total_records} total records."
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
        puts "Error validating #{model.name}: #{e.message}"
      end

      if invalid_count.zero?
        puts "\nValidation rule passed! All records would be valid."
      else
        puts "\nFound #{invalid_count} records that would become invalid out of #{total_count} total records."
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
      config = DbValidator.configuration
      batch_size = config.batch_size || 100
      limit = config.limit

      scope = model.all
      scope = scope.limit(limit) if limit

      total_count = scope.count
      return 0 if total_count.zero?

      progress_bar = create_progress_bar(model.name, total_count)
      invalid_count = 0

      begin
        scope.find_in_batches(batch_size: batch_size) do |batch|
          batch.each do |record|
            invalid_count += 1 unless validate_record(record)
            progress_bar.increment
          end
        end
      rescue StandardError => e
        puts "Error validating #{model.name}: #{e.message}"
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

    def get_models_to_validate
      models = find_all_models
      models.select { |model| should_validate_model?(model) }
    end
  end
end
