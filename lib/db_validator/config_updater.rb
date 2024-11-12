# frozen_string_literal: true

module DbValidator
  class ConfigUpdater
    def self.update_from_env
      new.update_from_env
    end

    def self.update_from_options(options)
      new.update_from_options(options)
    end

    def update_from_env
      update_config(
        limit: ENV["limit"]&.to_i,
        report_format: ENV["format"]&.to_sym,
        show_records: ENV["show_records"] != "false"
      )
    end

    def update_from_options(options)
      update_config(
        limit: options[:limit],
        batch_size: options[:batch_size],
        report_format: options[:format]&.to_sym,
        show_records: options[:show_records]
      )
    end

    private

    def update_config(settings)
      settings.each do |key, value|
        next unless value

        DbValidator.configuration.public_send("#{key}=", value)
      end
    end
  end
end
