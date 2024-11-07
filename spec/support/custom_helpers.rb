# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

module CustomHelpers
  def self.remove_test_model(name)
    model_name = name.to_s.camelize
    return unless Object.const_defined?(model_name)

    model_class = Object.const_get(model_name)
    model_class.reset_column_information if model_class.respond_to?(:reset_column_information)
    Object.send(:remove_const, model_name)
  rescue NameError
    # Ignore if the constant is already removed
  end

  def create_test_model(name, &block)
    model_name = name.to_s.camelize

    # Remove existing constant if defined
    CustomHelpers.remove_test_model(name)

    model_class = Class.new(ApplicationRecord) do
      self.table_name = name.to_s.downcase.pluralize
      class_eval(&block) if block_given?
    end

    Object.const_set(model_name, model_class)
    model_class
  end

  def setup_test_table(name, &block)
    table_name = name.to_s.downcase.pluralize
    ActiveRecord::Base.connection.drop_table(table_name) if ActiveRecord::Base.connection.table_exists?(table_name)
    
    ActiveRecord::Schema.define do
      create_table table_name, force: true do |t|
        block.call(t)
      end
    end
  end
end

RSpec.configure do |config|
  config.include CustomHelpers

  config.after(:each) do
    # Clean up any test models after each example
    [:User, :Product, :TestUser].each do |model_name|
      CustomHelpers.remove_test_model(model_name)
    end
  end
end
