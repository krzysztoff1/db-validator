# frozen_string_literal: true

require "spec_helper"
require "generators/db_validator/install_generator"
require "rails/generators/test_case"
require "rails/generators/testing/behavior"
require "rails/generators/testing/setup_and_teardown"
require "rails/generators/testing/assertions"
require "fileutils"

RSpec.describe DbValidator::Generators::InstallGenerator do
  include Rails::Generators::Testing::Behavior
  include Rails::Generators::Testing::SetupAndTeardown
  include FileUtils

  tests described_class
  destination File.expand_path("../../tmp", __dir__)

  before(:all) do
    prepare_destination
  end

  it "creates initializer file" do
    run_generator
    expect(File).to exist("#{destination_root}/config/initializers/db_validator.rb")
  end

  it "creates properly formatted initializer" do
    run_generator
    content = File.read("#{destination_root}/config/initializers/db_validator.rb")
    expect(content).to match(/DbValidator\.configure do \|config\|/)
    expect(content).to match(/# config\.ignored_models/)
    expect(content).to match(/# config\.batch_size = 100/)
  end
end
