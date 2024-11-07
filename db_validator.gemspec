# frozen_string_literal: true

require_relative "lib/db_validator/version"

Gem::Specification.new do |spec|
  spec.name = "db_validator"
  spec.version       = DbValidator::VERSION
  spec.authors       = ["Krzysztof Duda"]
  spec.email         = ["duda_krzysztof@outlook.com"]

  spec.summary       = "Database-wide validation for Rails applications"
  spec.description   = "A comprehensive solution for validating existing database records in Rails applications"
  spec.homepage      = "https://github.com/yourusername/db_validator"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.7.0"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_runtime_dependency "rails", ">= 5.2"
  spec.add_development_dependency "database_cleaner-active_record", "~> 2.1"
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "sqlite3", "~> 1.4"
  spec.add_dependency "colorize", "~> 0.8.1"
  spec.add_dependency "ruby-progressbar", "~> 1.11"
  spec.metadata["rubygems_mfa_required"] = "true"
end
