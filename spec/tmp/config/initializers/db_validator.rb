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

  # Set the batch size for processing records (default: 1000)
  # config.batch_size = 1000

  # Set the report format (:text or :json)
  # config.report_format = :text

  # Enable automatic fixing of simple validation errors
  # config.auto_fix = false
end