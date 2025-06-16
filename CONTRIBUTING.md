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
3. Install dependencies (`./build.ps1 -Bootstrap`)
4. Make your changes
5. Run tests and linting (`./build.ps1 -Task All`)
6. Test thoroughly in a non-production environment
7. Commit your changes (`git commit -m 'Add amazing feature'`)
8. Push to your branch (`git push origin feature/amazing-feature`)
9. Open a Pull Request

## Development Guidelines

### Development Environment Setup

#### Traditional Setup
```powershell
# Clone the repository
git clone https://github.com/businessplus-community/BPC.DBRefresh.git
cd BPC.DBRefresh

# Install dependencies
./build.ps1 -Bootstrap

# Run tests to verify setup
./build.ps1 -Task Test
```

#### Container Development (Recommended)
```powershell
# Copy environment template
cp .env.example .env
# Edit .env with your SQL Server details

# Start development environment
./scripts/Start-DevEnvironment.ps1

# Test container setup
./scripts/Test-ContainerSetup.ps1
```

### PowerShell Style Guide

- Use PascalCase for function names and parameters
- Use camelCase for variables
- Include comment-based help for all functions
- Use verbose parameter names (avoid aliases in scripts)
- Follow [PowerShell Best Practices](https://poshcode.gitbook.io/powershell-practice-and-style/)
- All functions must use the `BPERP` prefix (e.g., `Invoke-BPERPDatabaseRestore`)

### Code Standards

- Maintain the existing module structure (root level, not src/)
- Add inline comments for complex logic
- Update the module version in BPC.DBRefresh.psd1 for releases
- Ensure all database operations include error handling
- Log all significant operations using the PSLogging module
- Follow PSScriptAnalyzer rules (run `./build.ps1 -Task Analyze`)
- **IMPORTANT**: Always run `./build.ps1` before committing to ensure all tests pass

### Testing

Before submitting:

1. Run the full build pipeline:
   ```powershell
   ./build.ps1 -Task All
   ```

2. Run tests locally:
   ```powershell
   # Unit tests
   Invoke-Pester -Path ./tests/Unit
   
   # Integration tests (requires test environment)
   Invoke-Pester -Path ./tests/Integration
   ```

3. Test CI locally:
   ```powershell
   ./scripts/Test-LocalCI.ps1
   ```

4. Verify functionality:
   - Test with various parameter combinations
   - Verify all database operations complete successfully
   - Ensure email notifications work (if configured)
   - Check that logging captures all operations
   - Test error scenarios (missing files, access denied, etc.)

### Documentation

- Update README.md if adding new features or parameters
- Update CLAUDE.md if changing architecture or workflow
- Update CHANGELOG.md with your changes under [Unreleased]
- Include clear commit messages
- Document any new configuration options in the sample INI file
- Update relevant documentation in the docs/ folder
- Add examples to the examples/ folder for new features

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