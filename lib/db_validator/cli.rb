# frozen_string_literal: true

require "tty-prompt"
require "tty-box"
require "tty-spinner"
require "optparse"
require "logger"

module DbValidator
  class CLI
    def initialize
      @prompt = TTY::Prompt.new
      @options = {}
    end

    def start
      if ARGV.empty?
        interactive_mode
      else
        parse_command_line_args
        validate_with_options
      end
    end

    def display_progress(message)
      spinner = TTY::Spinner.new("[:spinner] #{message}", format: :dots)
      spinner.auto_spin
      yield if block_given?
      spinner.success
    end

    def select_models(available_models)
      system "clear"
      display_header

      if available_models.empty?
        @prompt.error("No models found in the application.")
        exit
      end

      choices = available_models.map { |model| { name: model, value: model } }
      choices.unshift({ name: "All Models", value: "all" })

      @prompt.say("\n")
      selected = @prompt.multi_select(
        "Select models to validate:",
        choices,
        per_page: 10,
        echo: false,
        show_help: :always,
        filter: true,
        cycle: true
      )

      if selected.include?("all")
        available_models
      else
        selected
      end
    end

    def parse_command_line_args
      args = ARGV.join(" ").split(/\s+/)
      args.each do |arg|
        key, value = arg.split("=")
        case key
        when "models"
          @options[:only_models] = value.split(",").map(&:strip).map(&:classify)
        when "limit"
          @options[:limit] = value.to_i
        when "format"
          @options[:report_format] = value.to_sym
        end
      end
    end

    def validate_with_options
      load_rails
      configure_validator(@options[:only_models], @options)
      validator = DbValidator::Validator.new
      report = validator.validate_all
      puts "\n#{report}"
    end

    def interactive_mode
      load_rails
      display_header

      display_progress("Loading models") do
        Rails.application.eager_load!
      end

      available_models = ActiveRecord::Base.descendants
                                         .reject(&:abstract_class?)
                                         .select(&:table_exists?)
                                         .map(&:name)
                                         .sort

      if available_models.empty?
        puts "No models found in the application."
        exit 1
      end

      selected_models = select_models(available_models)
      options = configure_options

      configure_validator(selected_models, options)
      validator = DbValidator::Validator.new
      report = validator.validate_all
      puts "\n#{report}"
    end

    def load_rails
      require File.expand_path("config/environment", Dir.pwd)
    rescue LoadError
      puts "Error: Rails application not found. Please run this command from your Rails application root."
      exit 1
    end

    def configure_validator(models = nil, options = {})
      config = DbValidator.configuration
      config.only_models = models if models
      config.limit = options[:limit] if options[:limit]
      config.batch_size = options[:batch_size] if options[:batch_size]
      config.report_format = options[:format] if options[:format]
    end

    def configure_options
      options = {}

      @prompt.say("\n")
      limit_input = @prompt.ask("Enter record limit (leave blank for no limit):") do |q|
        q.validate(/^\d*$/, "Please enter a valid number")
        q.convert(:int, nil)
      end
      options[:limit] = limit_input if limit_input.present?

      options[:format] = @prompt.select("Select report format:", %w[text json], default: "text")

      options[:show_records] = @prompt.yes?("Show failing records in the report?", default: true)

      options
    end

    def display_header
      title = TTY::Box.frame(
        "DB Validator",
        "Interactive Model Validation",
        padding: 1,
        align: :center,
        border: :thick,
        style: {
          border: {
            fg: :cyan
          }
        }
      )
      puts title
    end
  end
end
