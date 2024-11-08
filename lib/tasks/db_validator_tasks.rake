# frozen_string_literal: true

namespace :db_validator do
  desc "Validate records in the database"
  task validate: :environment do
    cli = DbValidator::CLI.new

    has_any_args = ENV["models"].present? || ENV["limit"].present? || ENV["format"].present? || ENV["show_records"].present?

    if has_any_args
      if ENV["models"].present?
        models = ENV["models"].split(",").map(&:strip).map(&:classify)
        DbValidator.configuration.only_models = models
      end

      DbValidator.configuration.limit = ENV["limit"].to_i if ENV["limit"].present?
      DbValidator.configuration.report_format = ENV["format"].to_sym if ENV["format"].present?
      DbValidator.configuration.show_records = ENV["show_records"] != "false" if ENV["show_records"].present?
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
      DbValidator.configuration.show_records = options[:show_records] if options[:show_records].present?
    end

    validator = DbValidator::Validator.new
    report = validator.validate_all
    puts "\n#{report}"
  end

  desc "Test validation rules on existing records"
  task test: :environment do
    unless ENV["model"] && ENV["rule"]
      puts "Usage: rake db_validator:test model=user rule='validates :field, presence: true' [show_records=false] [limit=1000]"
      exit 1
    end

    model_name = ENV["model"].classify
    validation_rule = ENV["rule"]
    
    # Configure options
    DbValidator.configuration.show_records = ENV["show_records"] != "false" if ENV["show_records"].present?
    DbValidator.configuration.limit = ENV["limit"].to_i if ENV["limit"].present?
    
    begin
      base_model = model_name.constantize
      # Extract attribute name from validation rule
      attribute_match = validation_rule.match(/validates\s+:(\w+)/)
      if attribute_match
        attribute_name = attribute_match[1]
        unless base_model.column_names.include?(attribute_name) || base_model.method_defined?(attribute_name)
          puts "\n❌ Error: Attribute '#{attribute_name}' does not exist for model '#{model_name}'"
          puts "Available columns: #{base_model.column_names.join(', ')}"
          exit 1
        end
      end

      # Create temporary subclass with new validation
      temp_model = Class.new(base_model) do
        self.table_name = base_model.table_name
        class_eval(validation_rule)
      end

      Object.const_set("Temporary#{model_name}", temp_model)

      validator = DbValidator::Validator.new
      report = validator.validate_test_model("Temporary#{model_name}")
      puts "\n#{report}"
    rescue NameError => e
      puts "\n❌ Error: Model '#{model_name}' not found"
      exit 1
    rescue SyntaxError => e
      puts "\n❌ Error: Invalid validation rule syntax"
      puts e.message
      exit 1
    ensure
      Object.send(:remove_const, "Temporary#{model_name}") if Object.const_defined?("Temporary#{model_name}")
    end
  end
end
