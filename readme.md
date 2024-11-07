# DbValidator

DbValidator is a comprehensive solution for validating existing database records in Rails applications. It helps you identify records that don't meet your model's validation requirements, which can happen due to data migrations, changed validation rules, or direct database modifications.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'db_validator'
```

Then execute:

```bash
$ bundle install
```

Or install it yourself:

```bash
$ gem install db_validator
```

## Setup

Generate the initializer:

```bash
$ rails generate db_validator:install
```

This will create a configuration file at `config/initializers/db_validator.rb` where you can customize the validation behavior.

## Configuration

```ruby
DbValidator.configure do |config|
  # Specify specific models to validate (optional)
  config.only_models = %w[User Post]

  # Ignore specific models from validation (optional)
  config.ignored_models = ["AdminUser"]

  # Ignore specific attributes for specific models (optional)
  config.ignored_attributes = {
    "User" => ["encrypted_password", "reset_password_token"],
    "Post" => ["cached_votes"]
  }

  # Set the batch size for processing records (default: 1000)
  config.batch_size = 1000

  # Set the report format (:text or :json)
  config.report_format = :text

  # Enable automatic fixing of simple validation errors
  config.auto_fix = false

  # Limit the number of records to validate per model
  config.limit = nil
end
```

## Usage

### Rake Task

The simplest way to run validation is using the provided rake task:

#### Validate all models

```bash
$ rake db_validator:validate
```

#### Validate specific models

```bash
$ rake db_validator:validate models=user,post
```

#### Limit the number of records to validate

```bash
$ rake db_validator:validate limit=1000
```

#### Generate JSON report

```bash
$ rake db_validator:validate format=json
```

### Ruby Code

You can also run validation from your Ruby code:

#### Validate all models

```ruby
report = DbValidator.validate
```

#### Validate with options

```ruby
report = DbValidator.validate(
  only_models: ['User', 'Post'],
  limit: 1000,
  report_format: :json
)
```

## Report Format

### Text Format (Default)

```
DbValidator Report
==================
Found invalid records:

User: 2 invalid records
ID: 1
  email is invalid (actual value: "invalid-email")
ID: 2
  name can't be blank (actual value: "")

Post: 1 invalid record
ID: 5
  title can't be blank (actual value: "")
  category is not included in the list (allowed values: news, blog, actual value: "invalid")
```

### JSON Format

```json
[
  {
    "model": "User",
    "id": 1,
    "errors": ["email is invalid (actual value: \"invalid-email\")"]
  },
  {
    "model": "User",
    "id": 2,
    "errors": ["name can't be blank (actual value: \"\")"]
  }
]
```
