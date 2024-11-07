# frozen_string_literal: true

require "spec_helper"

RSpec.describe DbValidator::Reporter do
  let(:reporter) { described_class.new }

  describe "#add_invalid_record" do
    before do
      setup_test_table(:products) do |t|
        t.string :name
        t.string :product_type
        t.timestamps
      end

      create_test_model(:Product) do
        validates :name, presence: true
        validates :product_type, inclusion: { in: %w[physical digital service] }
      end

      @invalid_product = Product.new(name: "", product_type: "unknown")
      @invalid_product.save(validate: false)
      @invalid_product.valid?
    end

    after do
      Product.delete_all
      CustomHelpers.remove_test_model(:Product)
      ActiveRecord::Base.connection.drop_table(:products)
    end

    it "enhances inclusion errors with allowed values" do
      reporter.add_invalid_record(@invalid_product)
      report = reporter.generate_report
      clean_report = strip_color_codes(report)

      # Update expectations to match the new format
      expect(clean_report).to include("Product: 1 invalid records")
      expect(clean_report).to include("⚠️  name can't be blank (actual value: \"\")")
      expect(clean_report).to include("⚠️  product_type is not included in the list (actual value: \"unknown\")")
    end
  end

  describe "#generate_report" do
    before do
      setup_test_table(:users) do |t|
        t.string :name
        t.timestamps
      end

      create_test_model(:User) do
        validates :name, presence: true
      end

      invalid_user = User.new(name: "")
      invalid_user.save(validate: false)
      invalid_user.valid?

      reporter.add_invalid_record(invalid_user)
    end

    after do
      User.delete_all
      CustomHelpers.remove_test_model(:User)
      ActiveRecord::Base.connection.drop_table(:users)
    end

    context "with text format" do
      it "generates a text report" do
        report = reporter.generate_report
        clean_report = strip_color_codes(report)

        expect(clean_report).to include("Database Validation Report")
        expect(clean_report).to include("User: 1 invalid records")
        expect(clean_report).to include("⚠️  name can't be blank (actual value: \"\")")
      end
    end

    context "with json format" do
      before do
        allow(DbValidator.configuration).to receive(:report_format).and_return(:json)
      end

      it "generates a JSON report" do
        report = reporter.generate_report
        parsed_report = JSON.parse(report)
        expect(parsed_report).to be_an(Array)
        expect(parsed_report.first["model"]).to eq("User")
        expect(parsed_report.first["errors"]).to include("name can't be blank (actual value: \"\")")
      end
    end
  end
end
