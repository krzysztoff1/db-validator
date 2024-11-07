# frozen_string_literal: true

module DbValidator
  class Configuration
    attr_accessor :only_models, :ignored_models, :ignored_attributes, :batch_size, :report_format, :auto_fix, :limit

    def initialize
      @only_models = []
      @ignored_models = []
      @ignored_attributes = {}
      @batch_size = 1000
      @report_format = :text
      @auto_fix = false
      @limit = nil
    end

    def only_models=(models)
      @only_models = models.map(&:downcase)
    end

    def ignored_models
      @ignored_models ||= []
    end

    def ignored_models=(models)
      @ignored_models = models.map(&:downcase)
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
