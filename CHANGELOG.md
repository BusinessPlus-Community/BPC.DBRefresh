# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- PowerShellBuild module integration for standardized builds
- Comprehensive Docker container support with multi-stage builds
- WSL2 documentation and full development support
- Local CI testing capabilities with `Test-LocalCI.ps1`
- Container helper scripts for development environment
- `.env.example` template for SQL Server configuration
- Container-specific documentation (CONTAINER-USAGE.md, WSL-SETUP.md, QUICKSTART-CONTAINER.md)
- GitHub Actions local runner support with act

### Changed

- Module structure reorganized to root level (removed src/ directory)
- Consolidated PSScriptAnalyzer settings into single file
- Updated PSLogging dependency to version 2.5.2 (from non-existent 2.2.0)
- VSCode configuration standardized for organization
- Build system now uses psakeFile.ps1 with PowerShellBuild
- CI/CD pipeline separated into style and compatibility jobs

### Fixed

- All PSScriptAnalyzer warnings resolved
- CI/CD pipeline failures related to module dependencies
- Module loading issues with Classes directory
- PSScriptAnalyzer settings path in CI workflow

### Documentation

- Comprehensive documentation and GitHub repository structure
- Issue and pull request templates
- Community contribution guidelines
- Security policy for vulnerability reporting
- Updated CLAUDE.md with development notes and requirements
- Enhanced ROADMAP.md with version planning

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

[Unreleased]: https://github.com/businessplus-community/BPC.DBRefresh/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/businessplus-community/BPC.DBRefresh/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/businessplus-community/BPC.DBRefresh/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/businessplus-community/BPC.DBRefresh/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/businessplus-community/BPC.DBRefresh/releases/tag/v1.0.0
