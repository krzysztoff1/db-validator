# frozen_string_literal: true

RSpec.describe DbValidator::Validator do
  let(:validator) { described_class.new }

  describe "#validate_all" do
    before(:all) do
      setup_test_table(:users) do |t|
        t.string :name
        t.string :email
        t.timestamps
      end

      create_test_model(:User) do
        validates :name, presence: true
        validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
      end
    end

    after(:all) do
      User.delete_all if Object.const_defined?(:User)
    ensure
      CustomHelpers.remove_test_model(:User)
      ActiveRecord::Base.connection.drop_table(:users) if ActiveRecord::Base.connection.table_exists?(:users)
    end

    before do
      User.create!(name: "Valid User", email: "valid@example.com")
      # Create invalid record by bypassing validations
      invalid_user = User.new(name: "", email: "invalid-email")
      invalid_user.save(validate: false)
    end

    after do
      User.delete_all if Object.const_defined?(:User)
    end

    it "identifies invalid records" do
      validator.validate_all
      report = validator.reporter.generate_report
      clean_report = strip_color_codes(report)

      expect(clean_report).to include("Found 3 invalid records across 1 models")
      expect(clean_report).to include("User: 3 invalid records")
    end
  end
end
