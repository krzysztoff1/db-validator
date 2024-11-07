# frozen_string_literal: true

module DbValidator
  class Railtie < Rails::Railtie
    railtie_name :db_validator

    rake_tasks do
      load "tasks/db_validator_tasks.rake"
    end

    generators do
      require "generators/db_validator/install_generator"
    end
  end
end
