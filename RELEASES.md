# Release Process

This document outlines the release process for the BusinessPlus Test Environment Refresh script.

## Versioning

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR** version for incompatible changes
- **MINOR** version for new functionality (backwards compatible)
- **PATCH** version for backwards compatible bug fixes

## Release Checklist

Before creating a new release:

1. **Update Version Number**
   - Update `$sScriptVersion` in `hpsBPC.DBRefresh.ps1`
   - Update version in any documentation

2. **Update Documentation**
   - Update CHANGELOG.md with release notes
   - Ensure README.md is current
   - Update any configuration examples

3. **Testing**
   - Test all major functionality
   - Verify new features work as expected
   - Ensure backwards compatibility

4. **Create Release**

   ```bash
   git checkout main
   git pull origin main
   git tag -a v1.4.0 -m "Release version 1.4.0"
   git push origin v1.4.0
   ```

5. **GitHub Release**
   - Go to [Releases](https://github.com/businessplus-community/BPC.DBRefresh/releases)
   - Click "Draft a new release"
   - Select the tag you just created
   - Title: "v1.4.0 - Brief Description"
   - Description: Copy from CHANGELOG.md
   - Attach any binaries if applicable
   - Publish release

## Release Notes Template

```markdown
## What's Changed
- Feature: Brief description by @contributor
- Fix: Brief description by @contributor
- Docs: Brief description by @contributor

## Breaking Changes
- List any breaking changes here

## Upgrade Instructions
- Any special instructions for upgrading

**Full Changelog**: https://github.com/businessplus-community/BPC.DBRefresh/compare/v1.3.0...v1.4.0
```

## Post-Release

1. Announce in appropriate channels
2. Update any dependent documentation
3. Monitor issues for any problems
4. Begin planning next release

## Emergency Patches

For critical security fixes:

1. Create patch on a hotfix branch
2. Test thoroughly but expedite process
3. Release as patch version (e.g., 1.3.1)
4. Notify users immediately
