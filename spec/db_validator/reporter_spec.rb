# frozen_string_literal: true

require "spec_helper"

RSpec.describe DbValidator::Reporter do
  let(:reporter) { described_class.new }

  describe "#add_invalid_record" do
    let(:invalid_product) do
      product = Product.new(name: "", product_type: "unknown")
      product.save(validate: false)
      product.valid?
      product
    end

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
    end

    after do
      Product.delete_all
      CustomHelpers.remove_test_model(:Product)
      ActiveRecord::Base.connection.drop_table(:products)
    end

    context "when adding an invalid product" do
      let(:report) do
        reporter.add_invalid_record(invalid_product)
        strip_color_codes(reporter.generate_report)
      end

      it "shows the model name and invalid record count" do
        expect(report).to include("Product: 1 invalid record")
      end

      it "shows the name validation error" do
        expect(report).to include("name can't be blank (actual value: \"\")")
      end

      it "shows the product_type inclusion error" do
        expect(report).to include("product_type is not included in the list (actual value: \"unknown\")")
      end
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
      before do
        allow(DbValidator.configuration).to receive(:report_format).and_return(:text)
      end

      it "shows number of invalid records and models" do
        report = reporter.generate_report
        clean_report = strip_color_codes(report)

        expect(clean_report).to include("Found 1 invalid record across 1 model")
      end

      it "shows number of invalid records in a model" do
        report = reporter.generate_report
        clean_report = strip_color_codes(report)

        expect(clean_report).to include("User: 1 invalid record")
      end

      it "shows error details" do
        report = reporter.generate_report
        clean_report = strip_color_codes(report)

        expect(clean_report).to include("name can't be blank (actual value: \"\")")
      end
    end

    context "with json format" do
      let(:invalid_skills) do
        skills = [
          Skill.new(name: ""),
          Skill.new(name: nil),
          Skill.new(name: "   ")
        ]

        skills.each do |skill|
          skill.save(validate: false)
          skill.valid?
          reporter.add_invalid_record(skill)
        end

        skills
      end

      before do
        allow(DbValidator.configuration).to receive(:report_format).and_return(:json)

        setup_test_table(:skills) do |t|
          t.string :name
          t.timestamps
        end

        create_test_model(:Skill) do
          validates :name, presence: true
        end

        invalid_skills
      end

      after do
        Skill.delete_all
        CustomHelpers.remove_test_model(:Skill)
        ActiveRecord::Base.connection.drop_table(:skills)
      end

      it "generates a JSON report with the correct structure" do
        report = reporter.generate_report
        parsed_report = JSON.parse(report)

        expect(parsed_report["Skill"]).to be_a(Hash)
      end

      it "includes the correct error count" do
        report = reporter.generate_report
        parsed_report = JSON.parse(report)

        expect(parsed_report["Skill"]["error_count"]).to eq(3)
      end

      it "includes an array of records" do
        report = reporter.generate_report
        parsed_report = JSON.parse(report)

        expect(parsed_report["Skill"]["records"].length).to eq(3)
      end

      it "includes the correct record details" do
        report = JSON.parse(reporter.generate_report)
        expect(report["Skill"]["records"].first).to include("id" => kind_of(Integer),
                                                            "errors" => include(match(/name can't be blank/)))
      end
    end
  end
end
