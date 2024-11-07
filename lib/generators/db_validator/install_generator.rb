# frozen_string_literal: true

require "rails/generators"
require "rails/generators/base"

module DbValidator
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def create_initializer
        template "initializer.rb", "config/initializers/db_validator.rb"
      end
    end
  end
end
