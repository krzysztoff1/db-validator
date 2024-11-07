# frozen_string_literal: true

require "bundler/setup"
require "rails"
require "active_record"
require "database_cleaner-active_record"

# Create a minimal Rails application for testing
class TestApp < Rails::Application
  config.root = File.dirname(__FILE__)
  config.eager_load = false
end
Rails.application.initialize!

require "db_validator"

# Define ApplicationRecord for testing
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

# Set up a test database
ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:"
)

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Database Cleaner configuration
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end

def strip_color_codes(text)
  text.gsub(/\e\[\d+(;\d+)*m/, "")
end
