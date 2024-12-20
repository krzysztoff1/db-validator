# frozen_string_literal: true

require "spec_helper"

RSpec.describe DbValidator do
  before(:all) do
    ActiveRecord::Schema.define do
      create_table :test_users do |t|
        t.string :name
        t.string :email
        t.timestamps
      end
    end

    TestUser = Class.new(ApplicationRecord) do
      self.table_name = "test_users"

      validates :name, presence: true
      validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
    end
  end

  after(:all) do
    TestUser.delete_all if Object.const_defined?(:TestUser)
  ensure
    Object.send(:remove_const, :TestUser) if Object.const_defined?(:TestUser)
    ActiveRecord::Base.connection.drop_table(:test_users) if ActiveRecord::Base.connection.table_exists?(:test_users)
  end

  let(:validator) { DbValidator::Validator.new }

  describe "full validation cycle" do
    before do
      TestUser.create!(name: "Valid User", email: "valid@example.com")
      invalid_user = TestUser.new(name: "", email: "invalid-email")
      invalid_user.save(validate: false)
    end

    after do
      TestUser.delete_all if Object.const_defined?(:TestUser)
    end

    it "identifies and reports invalid records" do
      validator.validate_all
      report = validator.reporter.generate_report
      clean_report = strip_color_codes(report)

      expect(clean_report).to include("Found 1 invalid record across 1 model")
    end
  end
end
