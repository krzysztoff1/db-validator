# frozen_string_literal: true

require "spec_helper"

RSpec.describe DbValidator::Fixer do
  let(:fixer) { described_class.new }

  describe "#fix_record" do
    let(:record) { double("Record", invalid?: true) }

    context "when record can be fixed" do
      before do
        allow(record).to receive(:save).and_return(true)
      end

      it "returns true when record is fixed" do
        expect(fixer.fix_record(record)).to be true
      end

      it "increments fixed records count" do
        fixer.fix_record(record)
        expect(fixer.statistics[:fixed_records]).to eq(1)
      end
    end

    context "when record cannot be fixed" do
      before do
        allow(record).to receive(:save).and_return(false)
      end

      it "returns false when record cannot be fixed" do
        expect(fixer.fix_record(record)).to be false
      end

      it "increments failed fixes count" do
        fixer.fix_record(record)
        expect(fixer.statistics[:failed_fixes]).to eq(1)
      end
    end
  end

  describe "#statistics" do
    it "returns initial statistics when no fixes attempted" do
      expect(fixer.statistics).to eq(
        fixed_records: 0,
        failed_fixes: 0
      )
    end
  end
end
