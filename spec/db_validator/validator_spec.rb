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

      expect(clean_report).to include("Found 1 invalid records across 1 models")
      expect(clean_report).to include("User: 1 invalid records")
      expect(clean_report).to include("name can't be blank")
      expect(clean_report).to include("email is invalid")
    end
  end

  describe "#validate_test_model" do
    before(:all) do
      setup_test_table(:users) do |t|
        t.string :name
        t.string :email
        t.timestamps
      end
    end

    after(:all) do
      ActiveRecord::Base.connection.drop_table(:users) if ActiveRecord::Base.connection.table_exists?(:users)
    end

    before do
      create_test_model(:User)

      5.times do |i|
        user = User.new(name: "User #{i}", email: "user#{i}@example.com")
        user.save(validate: false)
      end
    end

    after do
      User.delete_all if Object.const_defined?(:User)
      CustomHelpers.remove_test_model(:User)
      DbValidator.configuration.limit = nil
    end

    context "with limit" do
      it "respects the record limit" do
        DbValidator.configuration.limit = 2
        
        temp_model = Class.new(User) do
          validates :email, presence: true
        end
        Object.const_set("TemporaryUser", temp_model)

        User.delete_all

        3.times do |i|
          user = User.new(name: "No Email User #{i}")
          user.save(validate: false)
        end

        validator.validate_test_model("TemporaryUser")
        report = validator.reporter.generate_report
        clean_report = strip_color_codes(report)

        expect(clean_report).to include("Found 2 invalid records across 1 models")
        expect(clean_report).to include("TemporaryUser: 2 invalid records")
        expect(clean_report).to include("email can't be blank")
      ensure
        Object.send(:remove_const, "TemporaryUser") if Object.const_defined?("TemporaryUser")
      end
    end

    context "with email validation" do
      it "identifies invalid email formats" do
        User.delete_all

        3.times do |i|
          user = User.new(name: "User #{i}", email: "invalid-email")
          user.save(validate: false)
        end

        temp_model = Class.new(User) do
          validates :email, format: { with: /@/, message: "must contain @" }
        end
        Object.const_set("TemporaryUser", temp_model)

        validator.validate_test_model("TemporaryUser")
        report = validator.reporter.generate_report
        clean_report = strip_color_codes(report)

        expect(clean_report).to include("Found 3 invalid records across 1 models")
        expect(clean_report).to include("TemporaryUser: 3 invalid records")
        expect(clean_report).to include("email must contain @")
      ensure
        Object.send(:remove_const, "TemporaryUser") if Object.const_defined?("TemporaryUser")
      end
    end

    context "with presence validation" do
      it "identifies records with missing required fields" do
        User.delete_all

        user = User.new(email: "test@example.com")
        user.save(validate: false)

        temp_model = Class.new(User) do
          validates :name, presence: true
        end
        Object.const_set("TemporaryUser", temp_model)

        validator.validate_test_model("TemporaryUser")
        report = validator.reporter.generate_report
        clean_report = strip_color_codes(report)

        expect(clean_report).to include("Found 1 invalid records across 1 models")
        expect(clean_report).to include("TemporaryUser: 1 invalid records")
        expect(clean_report).to include("name can't be blank")
      ensure
        Object.send(:remove_const, "TemporaryUser") if Object.const_defined?("TemporaryUser")
      end
    end
  end
end
