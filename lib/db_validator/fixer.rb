# frozen_string_literal: true

module DbValidator
  class Fixer
    def initialize
      @fixed_records = 0
      @failed_fixes = 0
    end

    def fix_record(record)
      return false unless record.invalid?

      success = attempt_fix(record)
      if success
        @fixed_records += 1
      else
        @failed_fixes += 1
      end
      success
    end

    def statistics
      {
        fixed_records: @fixed_records,
        failed_fixes: @failed_fixes
      }
    end

    private

    def attempt_fix(record)
      record.save
    end
  end
end
