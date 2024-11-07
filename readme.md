[![Gem Version](https://badge.fury.io/rb/db_validator.svg?icon=si%3Arubygems)](https://badge.fury.io/rb/db_validator)
[![RSpec Tests](https://github.com/krzysztoff1/db-validator/actions/workflows/rspec.yml/badge.svg)](https://github.com/krzysztoff1/db-validator/actions/workflows/rspec.yml)

# DbValidator

DbValidator helps identify invalid records in your Rails application that don't meet model validation requirements. It finds records that became invalid after validation rule changes, and validates imported or manually edited data. You can use it to audit records before deploying new validations and catch any data that bypassed validation checks.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'db_validator'
```

Then execute:

```bash
$ bundle install
```

## Usage

### Rake Task

The simplest way to run validation is using the provided rake task:

#### Validate models in interactive mode

```bash
$ rake db_validator:validate
```

This will start an interactive mode where you can select which models to validate and adjust other options.

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

### Interactive Mode

Running the validation task without specifying models will start an interactive mode:

```bash
$ rake db_validator:validate
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
