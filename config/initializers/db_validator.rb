# frozen_string_literal: true

DbValidator.configure do |config|
  config.only_models = %w[Documents Users]
  config.batch_size = 500
  config.limit = 500
  config.model_limits = {
    "documents" => 500,
    "users" => 1000
  }
  config.report_format = :json
end
