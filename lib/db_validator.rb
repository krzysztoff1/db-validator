# frozen_string_literal: true

require "rails"
require "db_validator/version"
require "db_validator/configuration"
require "db_validator/validator"
require "db_validator/reporter"
require "db_validator/cli"

module DbValidator
  class Error < StandardError; end

  class << self
    def validate(options = {})
      validator = Validator.new(options)
      validator.validate_all
    end
  end
end

require "db_validator/railtie" if defined?(Rails)
