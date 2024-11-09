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

<img width="798" alt="Screenshot 2024-11-07 at 21 50 57" src="https://github.com/user-attachments/assets/33fbdb8b-b8ec-4284-9313-c1eeaf2eab2d">

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

### Test Mode

You can test new validation rules before applying them to your models:

```bash
$ rake db_validator:test model=User rule='validates :name, presence: true'
```

#### Testing Email Format Validation

Here's an example of testing email format validation rules:

```bash
# Testing invalid email format (without @)
$ rake db_validator:test model=User rule='validates :email, format: { without: /@/, message: "must contain @" }'

Found 100 records that would become invalid out of 100 total records.

# Testing valid email format (with @)
$ rake db_validator:test model=User rule='validates :email, format: { with: /@/, message: "must contain @" }'

No invalid records found.
```

#### Error Handling

Trying to test a validation rule for a non-existent attribute will return an error:

```
❌ Error: Attribute 'i_dont_exist' does not exist for model 'User'
Available columns: id, email, created_at, updated_at, name
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

The JSON report is saved to a file in the `db_validator_reports` directory.

```json
{
  "User": {
    "error_count": 2,
    "records": [
      {
        "id": 1,
        "errors": [
          "email is invalid (actual value: \"invalid-email\")"
        ]
      },
      {
        "id": 2,
        "errors": [
          "name can't be blank (actual value: \"\")"
        ]
      }
    ]
  }
}
```
