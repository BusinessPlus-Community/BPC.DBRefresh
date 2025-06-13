# Contributing to BusinessPlus Test Environment Refresh

Thank you for your interest in contributing to this project! This document provides guidelines and instructions for contributing.

## Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- A clear and descriptive title
- Steps to reproduce the issue
- Expected behavior vs actual behavior
- Environment details (PowerShell version, OS, SQL Server version)
- Relevant log entries from `BPC.DBRefresh.log`
- Configuration file excerpts (sanitized of sensitive data)

### Suggesting Enhancements

Enhancement suggestions are welcome! Please provide:

- A clear and descriptive title
- Detailed description of the proposed enhancement
- Use cases and benefits
- Possible implementation approach
- Any potential drawbacks or considerations

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly in a non-production environment
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to your branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Development Guidelines

### PowerShell Style Guide

- Use PascalCase for function names and parameters
- Use camelCase for variables
- Include comment-based help for all functions
- Use verbose parameter names (avoid aliases in scripts)
- Follow [PowerShell Best Practices](https://poshcode.gitbook.io/powershell-practice-and-style/)

### Code Standards

- Maintain the existing code structure
- Add inline comments for complex logic
- Update the script version number for significant changes
- Ensure all database operations include error handling
- Log all significant operations using the PSLogging module

### Testing

Before submitting:

1. Test the script with various parameter combinations
2. Verify all database operations complete successfully
3. Ensure email notifications work (if configured)
4. Check that logging captures all operations
5. Test error scenarios (missing files, access denied, etc.)

### Documentation

- Update README.md if adding new features or parameters
- Update CLAUDE.md if changing architecture or workflow
- Include clear commit messages
- Document any new configuration options in the sample INI file

## Commit Message Guidelines

Use clear and descriptive commit messages:

- `feat:` New feature or enhancement
- `fix:` Bug fix
- `docs:` Documentation changes
- `refactor:` Code refactoring
- `test:` Adding or updating tests
- `chore:` Maintenance tasks

Example: `feat: Add support for differential backups`

## Review Process

1. All submissions require review before merging
2. Reviewers will check for:
   - Code quality and style compliance
   - Security implications
   - Performance impact
   - Documentation completeness
3. Address reviewer feedback promptly
4. Once approved, your contribution will be merged

## Security

- Never commit sensitive data (passwords, connection strings, server names)
- Always use the sample INI file for examples
- Report security vulnerabilities privately (see [SECURITY.md](SECURITY.md))

## Questions?

Feel free to open an issue for any questions about contributing.

Thank you for helping improve BusinessPlus Test Environment Refresh!