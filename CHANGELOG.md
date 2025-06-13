# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Comprehensive documentation and GitHub repository structure
- Issue and pull request templates
- Community contribution guidelines
- Security policy for vulnerability reporting

## [1.3.0] - Previous Release

### Added

- Email notification support using MailKit
- Dashboard restoration functionality with `-restoreDashboards` parameter
- Testing mode with `-testingMode` parameter for enabling additional test accounts

### Changed

- Improved error handling and logging
- Updated module dependencies

### Fixed

- Database permission issues after restoration
- Service restart reliability

### Security

- Enhanced credential handling
- Improved configuration file security

## [1.2.0] - Previous Release

### Added

- Support for multiple environment configurations
- Automated server reboot functionality
- Enhanced logging with PSLogging module

### Changed

- Refactored database restoration logic
- Improved parameter validation

## [1.1.0] - Previous Release

### Added

- Initial support for ASPNET database restoration
- Configuration file validation

### Fixed

- SQL connection string handling
- User permission mapping

## [1.0.0] - Initial Release

### Added

- Core database restoration functionality for IFAS and SYSCAT
- Environment-specific configuration support
- Service management automation
- Post-restore cleanup tasks
- Basic logging functionality

[Unreleased]: https://github.com/businessplus-community/bp-test-env-refresh/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/businessplus-community/bp-test-env-refresh/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/businessplus-community/bp-test-env-refresh/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/businessplus-community/bp-test-env-refresh/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/businessplus-community/bp-test-env-refresh/releases/tag/v1.0.0
