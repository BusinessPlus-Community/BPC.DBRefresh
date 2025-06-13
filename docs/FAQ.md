# Frequently Asked Questions

## General Questions

### What is BusinessPlus Test Environment Refresh?

This is a PowerShell module that automates the process of refreshing BusinessPlus test environments with production database backups. It handles database restoration, security configuration, and environment-specific settings.

### Who can use this tool?

This tool is designed for K-12 school district IT staff who manage BusinessPlus ERP/HR/PY systems. You need appropriate permissions to:
- Access SQL Server instances
- Control services on target servers
- Read production backup files
- Modify test environment databases

### Is this officially supported by BusinessPlus?

No, this is a community-driven project maintained by the BusinessPlus Community. It's not officially affiliated with or supported by the BusinessPlus software vendor.

## Installation & Setup

### What are the prerequisites?

- PowerShell 5.1 or higher
- Required PowerShell modules: PSLogging, dbatools, PsIni
- SQL Server access with sysadmin privileges
- Network access to all environment servers
- Access to production backup files

### How do I install the required modules?

```powershell
Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module -Name PSLogging, dbatools, PsIni -Force -Scope CurrentUser
```

### Where do I get the configuration file?

Copy the sample configuration from `config/hpsBPC.DBRefresh-sample.ini` and customize it for your environment.

## Usage Questions

### How long does the refresh process take?

The duration depends on:
- Size of your databases (typically 30 GB - 200 GB)
- Network speed for backup file access
- Server performance
- Number of servers in the environment

Typical refresh times range from 1-4 hours.

### Can I refresh just one database?

Currently, the tool requires at least IFAS and SYSCAT databases. ASPNET is optional. Individual database refresh is not supported as the databases have interdependencies.

### What happens to existing data?

All existing data in the test environment is permanently replaced with the production backup data. Always ensure you have backups if you need to preserve test data.

### Can I run this during business hours?

It's not recommended. The process:
- Stops BusinessPlus services
- Makes databases unavailable
- Reboots servers

Schedule refreshes during maintenance windows.

## Security Questions

### How are user accounts handled?

- All user accounts are disabled except those listed as manager codes
- Email addresses are replaced with dummy values
- Passwords remain from production (but accounts are disabled)

### Is production data safe?

The script only reads from production backups; it never modifies production systems. However, ensure:
- Backup files are stored securely
- Test environments are properly isolated
- Access to test systems is controlled

### What about sensitive data?

Consider implementing additional data masking for sensitive information like:
- Social Security Numbers
- Financial data
- Personal information

This tool provides basic security measures but may not meet all compliance requirements.

## Troubleshooting

### The script fails with "Access Denied"

Check:
1. SQL Server permissions (need sysadmin role)
2. Windows permissions on target servers
3. Network share access for backup files
4. Service control permissions

### Database restore fails

Common causes:
- Insufficient disk space
- Backup file corruption
- SQL Server version incompatibility
- Incorrect file paths in configuration

### Services won't stop

Some services may have dependencies. The script will attempt to stop them, but manual intervention might be needed for:
- Services with open connections
- Services in a failed state
- Third-party integrated services

### Email notifications aren't working

Verify:
- SMTP server settings in configuration
- Network access to SMTP server
- Authentication requirements
- Firewall rules

## Best Practices

### How often should I refresh test environments?

Recommendations:
- **Weekly**: For active development/testing
- **Monthly**: For stable environments
- **Quarterly**: For rarely used environments
- **Before major changes**: Always refresh before testing significant updates

### Should I automate the refresh process?

Yes, but with caution:
- Use Windows Task Scheduler or similar
- Always schedule during off-hours
- Implement monitoring and alerting
- Keep logs for audit purposes
- Test automation thoroughly first

### How do I handle multiple test environments?

- Create separate configuration files for each environment
- Stagger refresh schedules to avoid resource conflicts
- Consider using different backup sets for different purposes
- Document which environment serves which purpose

## Advanced Topics

### Can I customize the post-restore process?

Yes, you can:
- Modify the PowerShell functions
- Add custom SQL scripts
- Extend the workflow with additional steps
- Create environment-specific configurations

### How do I contribute improvements?

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request
5. See [CONTRIBUTING.md](../CONTRIBUTING.md) for details

### Where can I get help?

- Open an issue on [GitHub](https://github.com/businessplus-community/BPC.DBRefresh/issues)
- Email code@bpluscommunity.org
- Check existing issues for solutions
- Review the documentation

## Module-Specific Questions

### What's the difference between the script and module versions?

The module version:
- Provides better organization and reusability
- Allows selective function usage
- Includes comprehensive testing
- Supports PowerShell Gallery distribution
- Maintains backward compatibility

### Can I use individual functions?

Yes! After importing the module, you can use any public function:
```powershell
Import-Module BPC.DBRefresh
Stop-BPERPServices -Config $config
# Use other functions as needed
```

### How do I update the module?

```powershell
Update-Module -Name BPC.DBRefresh
```

Or for a specific version:
```powershell
Update-Module -Name BPC.DBRefresh -RequiredVersion 1.4.0
```