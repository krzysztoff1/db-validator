# frozen_string_literal: true

require "tty-prompt"
require "tty-box"
require "tty-spinner"

module DbValidator
  class CLI
    def initialize
      @prompt = TTY::Prompt.new
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

    def configure_options
      options = {}

      @prompt.say("\n")
      if @prompt.yes?("Would you like to configure additional options?", default: false)
        limit_input = @prompt.ask("Enter record limit (leave blank for no limit):") do |q|
          q.validate(/^\d*$/, "Please enter a valid number")
          q.convert(:int, nil)
        end
        options[:limit] = limit_input if limit_input.present?

        batch_size = @prompt.ask("Enter batch size:", default: 1000, convert: :int) do |q|
          q.validate(/^\d+$/, "Please enter a positive number")
          q.messages[:valid?] = "Please enter a positive number"
        end
        options[:batch_size] = batch_size if batch_size.present?

        options[:format] = @prompt.select("Select report format:", %w[text json], default: "text")
      end

      options
    end

    def display_progress(message)
      spinner = TTY::Spinner.new("[:spinner] #{message}", format: :dots)
      spinner.auto_spin
      yield if block_given?
      spinner.success
    end

    private

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