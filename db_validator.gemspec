# frozen_string_literal: true

require_relative "lib/db_validator/version"

Gem::Specification.new do |spec|
  spec.name = "db_validator"
  spec.version       = DbValidator::VERSION
  spec.authors       = ["Krzysztof Duda"]
  spec.email         = ["duda_krzysztof@outlook.com"]

  spec.summary       = "DbValidator helps identify invalid records in your Rails application that don't meet model validation requirements"
  spec.description   = "DbValidator helps identify invalid records in your Rails application that don't meet model validation requirements. It finds records that became invalid after validation rule changes, and validates imported or manually edited data. You can use it to audit records before deploying new validations and catch any data that bypassed validation checks."
  spec.homepage      = "https://github.com/krzysztoff1/db-validator"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata = {
    "homepage_uri" => "https://github.com/krzysztoff1/db-validator/",
    "source_code_uri" => "https://github.com/krzysztoff1/db-validator/",
    "documentation_uri" => "https://github.com/krzysztoff1/db-validator/blob/main/README.md",
    "changelog_uri" => "https://github.com/krzysztoff1/db-validator/blob/main/changelog.md",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", ">= 5.2"
  spec.add_development_dependency "database_cleaner-active_record", "~> 2.1"
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "sqlite3", "~> 1.4"
  spec.add_dependency "ruby-progressbar", "~> 1.11"
  spec.add_dependency "tty-box", "~> 0.7.0"
  spec.add_dependency "tty-prompt", "~> 0.23.1"
  spec.add_dependency "tty-spinner", "~> 0.9.3"
end
