# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-13

### Added
- Add error message for enum validation

## [0.3.0] - 2024-11-09

### Added
- Add test mode - `rake db_validator:test`
- Add error count and grouping in JSON reports
- Save JSON report to a file in the `db_validator_reports` directory

### Fixed
- Skip validation of HABTM (Has And Belongs To Many) join tables

### Changed
- Restructure JSON output format to include error counts and grouped records

## [0.2.0] - 2024-11-07

### Added
- Enhanced interactive mode with improved UI

## [0.1.0] - 2024-11-07

### Added
- Initial release
