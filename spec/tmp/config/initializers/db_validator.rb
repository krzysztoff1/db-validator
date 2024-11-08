# frozen_string_literal: true

DbValidator.configure do |config|
  # Specify specific models to validate
  config.only_models = %w[User Post]

  # Ignore specific models from validation
  # config.ignored_models = ["AdminUser"]

  # Ignore specific attributes for specific models
  # config.ignored_attributes = {
  #   "User" => ["encrypted_password", "reset_password_token"],
  #   "Post" => ["cached_votes"]
  # }

  # Set the report format (:text or :json)
  # config.report_format = :text

  # Show detailed record information in reports
  # config.show_records = true
end
