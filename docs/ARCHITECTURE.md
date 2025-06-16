# Architecture Documentation

## System Overview

The BusinessPlus Test Environment Refresh tool is a PowerShell module designed to automate the process of refreshing test environments with production database backups. This document describes the architecture, design decisions, and implementation details.

## High-Level Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│                    User Interface Layer                       │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │ PowerShell  │  │   Wrapper    │  │  Command Line    │   │
│  │   Module    │  │   Script     │  │   Parameters     │   │
│  └─────────────┘  └──────────────┘  └──────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                               │
┌─────────────────────────────────────────────────────────────┐
│                    Business Logic Layer                       │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │   Restore   │  │   Service    │  │  Configuration   │   │
│  │ Orchestrator│  │  Management  │  │   Management     │   │
│  └─────────────┘  └──────────────┘  └──────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                               │
┌─────────────────────────────────────────────────────────────┐
│                      Data Access Layer                        │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │  SQL Server │  │   Windows    │  │      File        │   │
│  │  Interface  │  │   Services   │  │     System       │   │
│  └─────────────┘  └──────────────┘  └──────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Component Architecture

### 1. Module Structure

```text
BPC.DBRefresh/
├── Public/          # Exported functions
├── Private/         # Internal helper functions
├── Classes/         # PowerShell classes (future)
└── BPC.DBRefresh.psd1/psm1  # Module manifest and loader
```

### 2. Core Components

#### Restore Orchestrator (`Invoke-BPERPDatabaseRestore`)

- **Purpose**: Main entry point that coordinates the entire refresh process
- **Responsibilities**:
  - Parameter validation
  - Workflow orchestration
  - Error handling and logging
  - Progress reporting

#### Configuration Manager (`Get-BPERPEnvironmentConfig`)

- **Purpose**: Manages environment-specific configuration
- **Design Pattern**: Singleton per environment
- **Data Source**: INI files
- **Caching**: None (reads fresh each time)

#### Service Controller (`Stop-BPERPServices`, `Restart-BPERPServers`)

- **Purpose**: Manages Windows services and server lifecycle
- **Technology**: WMI and PowerShell remoting
- **Error Handling**: Continues on individual failures

#### Database Manager (`Invoke-BPERPDatabaseRestoreFiles`, `Set-BPERPDatabasePermissions`)

- **Purpose**: Handles all SQL Server operations
- **Technology**: dbatools PowerShell module
- **Transaction Scope**: Individual database operations

#### Notification System (`Send-BPERPNotification`)

- **Purpose**: Sends completion notifications
- **Technology**: MailKit or Send-MailMessage fallback
- **Template Engine**: Internal HTML builder

### 3. Data Flow

```text
1. User Input → Parameter Validation
2. Configuration Loading → Environment Setup
3. Service Shutdown → Database Quiesce
4. Backup Validation → File Access Check
5. Database Restore → Data Replacement
6. Security Configuration → Permission Setup
7. Post-Restore Tasks → Data Cleanup
8. Service Restart → Environment Activation
9. Notification → Status Report
```

## Design Patterns

### 1. Command Pattern

Each major operation is encapsulated in its own function, allowing for:

- Independent testing
- Reusability
- Clear separation of concerns

### 2. Pipeline Pattern

Functions are designed to work with PowerShell pipeline:

```powershell
Get-BPERPEnvironmentConfig | Stop-BPERPServices | Invoke-BPERPDatabaseRestoreFiles
```

### 3. Configuration Pattern

External configuration drives behavior:

- Environment-specific settings in INI files
- Parameter sets for operation modes
- Minimal hardcoding

## Security Architecture

### 1. Authentication

- **Windows Authentication**: Primary method for all operations
- **SQL Authentication**: Fallback option (not recommended)
- **No Credential Storage**: Credentials never persisted

### 2. Authorization

- **Role-Based**: Requires specific SQL and Windows roles
- **Least Privilege**: Documents minimum required permissions
- **Audit Trail**: Comprehensive logging of all operations

### 3. Data Protection

- **In Transit**: Uses existing SQL Server encryption
- **At Rest**: Relies on filesystem and SQL encryption
- **Sensitive Data**: Email addresses and accounts sanitized

## Error Handling Strategy

### 1. Levels of Error Handling

```powershell
try {
    # Operation level - specific error handling
    Restore-Database -Path $path
} catch [System.Data.SqlClient.SqlException] {
    # Handle SQL-specific errors
} catch {
    # Generic error handling with logging
    Write-BPERPLog -Level Error -Message $_.Exception
    throw  # Re-throw for upstream handling
}
```

### 2. Error Recovery

- **Partial Completion**: Tracks progress for restart capability
- **Rollback**: Limited (databases use REPLACE option)
- **Notification**: Always attempts to send status email

## Performance Considerations

### 1. Optimization Points

- **Parallel Operations**: Services stopped concurrently
- **Backup Compression**: Supports compressed backups
- **Network Efficiency**: Direct restore from network shares

### 2. Bottlenecks

- **Network Speed**: Primary constraint for large databases
- **Disk I/O**: Database file initialization
- **Service Dependencies**: Sequential requirement

## Extensibility

### 1. Hook Points

- **Pre/Post Functions**: Can add custom logic
- **Configuration Sections**: INI format allows additions
- **Module Extension**: Additional functions can be added

### 2. Future Enhancements

- **Plugin System**: For custom post-restore tasks
- **Event System**: For progress notifications
- **API Layer**: REST API for remote execution

## Dependencies

### 1. External Modules

- **PSLogging**: Structured logging framework
- **dbatools**: SQL Server automation
- **PsIni**: INI file parsing

### 2. System Requirements

- **PowerShell**: 5.1+ (Core compatible)
- **SQL Server**: 2012+ (tested on 2016+)
- **Windows Server**: 2012 R2+ (WMF 5.1)

### 3. Network Requirements

- **SMB**: For backup file access
- **WinRM**: For remote management
- **SQL**: TCP 1433 (configurable)

## Testing Strategy

### 1. Unit Tests

- Individual function testing
- Mock external dependencies
- Parameter validation

### 2. Integration Tests

- End-to-end workflow testing
- Real SQL Server instances
- Test environment required

### 3. Performance Tests

- Benchmark restore times
- Memory usage profiling
- Network utilization

## Monitoring and Observability

### 1. Logging

- **Structured Logs**: PSLogging format
- **Log Levels**: Verbose, Info, Warning, Error
- **Rotation**: Manual (no automatic rotation)

### 2. Metrics

- **Duration**: Total and per-phase timing
- **Success Rate**: Tracked in logs
- **Error Frequency**: Analyzable from logs

### 3. Health Checks

- **Pre-flight Checks**: Validates environment
- **Progress Indicators**: Console output
- **Post-Completion**: Email notification

## Deployment Architecture

### 1. Distribution Methods

- **GitHub**: Source code repository
- **PowerShell Gallery**: Module distribution
- **NuGet**: Package distribution

### 2. Installation Patterns

- **User Scope**: Recommended for most users
- **System Scope**: For server installations
- **Portable**: Direct script execution

### 3. Update Mechanism

- **Manual**: Update-Module command
- **Automatic**: Via package managers
- **Notifications**: GitHub releases

## Conclusion

This architecture provides a robust, maintainable, and extensible solution for BusinessPlus test environment refresh operations. The modular design allows for easy testing, modification, and enhancement while maintaining backward compatibility.
