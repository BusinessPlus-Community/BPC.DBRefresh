# BPC.DBRefresh Roadmap

## Overview

This document outlines the planned features and enhancements for future releases of the BPC.DBRefresh module.

## Release Planning

### v1.1.0 (Next Release)

- [ ] Enhanced error handling and recovery mechanisms
- [ ] Performance optimizations for large database restores
- [ ] Additional configuration validation
- [ ] Extended PowerShell 7.x compatibility testing

### v1.2.0 (Future Release)

- [ ] System Center Data Protection Manager (DPM) Integration
  - Direct integration with DPM for automated backup retrieval
  - Support for DPM backup schedules and retention policies
  - Automated backup file discovery from DPM repositories
  - DPM authentication and permission management
- [ ] Enhanced notification system with multiple channels
- [ ] Web-based dashboard for restore status monitoring

### v2.0.0 (Major Release)

- [ ] Full DPM Integration Suite
  - Complete DPM workflow automation
  - Backup lifecycle management
  - Integration with DPM reporting
  - Support for DPM cloud backup targets
- [ ] REST API for external integrations
- [ ] Multi-environment parallel restore capabilities
- [ ] Advanced scheduling and orchestration

## Feature Details

### System Center Data Protection Manager (DPM) Integration

**Target Release**: v1.2.0 (initial support), v2.0.0 (full integration)

**Objectives**:

- Eliminate manual backup file handling
- Integrate with existing DPM infrastructure
- Automate backup discovery and selection
- Provide seamless restore workflows from DPM

**Key Features**:

1. **DPM Server Connection**
   - Secure authentication to DPM servers
   - Support for multiple DPM instances
   - Connection pooling and management

2. **Backup Discovery**
   - Query DPM for available backups
   - Filter by date, database, and recovery point
   - Automatic selection of latest valid backup

3. **Direct Restore**
   - Stream backups directly from DPM to SQL Server
   - Progress monitoring and reporting
   - Error handling and retry logic

4. **Configuration Integration**
   - DPM settings in BPC.DBRefresh.ini
   - Per-environment DPM source mapping
   - Credential management for DPM access

## Contributing

If you have feature requests or would like to contribute to the roadmap, please:

1. Open an issue on GitHub with the "enhancement" label
2. Provide detailed use cases and requirements
3. Join the discussion in existing roadmap issues

## Version History

- v1.0.0 - Initial release with core functionality
- v1.1.0 - (Planned) Enhanced error handling and performance
- v1.2.0 - (Planned) Initial DPM integration
- v2.0.0 - (Planned) Full DPM suite and API
