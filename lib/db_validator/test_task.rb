# frozen_string_literal: true

module DbValidator
  class TestTask
    def initialize(model_name, validation_rule)
      @model_name = model_name
      @validation_rule = validation_rule
    end

    def execute
      validate_and_test_model
    rescue NameError
      puts "Model '#{@model_name}' not found"
      raise "Model '#{@model_name}' not found"
    rescue SyntaxError
      puts "Invalid validation rule syntax"
      raise "Invalid validation rule syntax"
    ensure
      cleanup_temporary_model
    end

    private

    def validate_and_test_model
      base_model = @model_name.constantize
      validate_attribute(base_model)

      temp_model = create_temporary_model(base_model)
      Object.const_set("Temporary#{@model_name}", temp_model)

      validator = DbValidator::Validator.new
      report = validator.validate_test_model("Temporary#{@model_name}")
      puts report
    end

    def validate_attribute(base_model)
      attribute_match = @validation_rule.match(/validates\s+:(\w+)/)
      return unless attribute_match

      attribute_name = attribute_match[1]
      return if base_model.column_names.include?(attribute_name) || base_model.method_defined?(attribute_name)

      puts "Attribute '#{attribute_name}' does not exist for model '#{@model_name}'"
      raise "Attribute '#{attribute_name}' does not exist for model '#{@model_name}'"
    end

    def create_temporary_model(base_model)
      Class.new(base_model) do
        self.table_name = base_model.table_name
        class_eval(@validation_rule)
      end
    end

    def cleanup_temporary_model
      temp_const_name = "Temporary#{@model_name}"
      Object.send(:remove_const, temp_const_name) if Object.const_defined?(temp_const_name)
    end
  end
end
