# DbValidator

DbValidator helps identify invalid records in your Rails application that don't meet model validation requirements.

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
