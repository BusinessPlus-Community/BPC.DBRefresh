---
external help file: BPC.DBRefresh-help.xml
Module Name: BPC.DBRefresh
online version:
schema: 2.0.0
---

# Invoke-BPERPDatabaseRestore

## SYNOPSIS
Restores BusinessPlus databases from backup files

## SYNTAX

```
Invoke-BPERPDatabaseRestore [-BPEnvironment] <String> [-IfasFilePath] <String> [-SyscatFilePath] <String>
 [[-AspnetFilePath] <String>] [-TestingMode] [-RestoreDashboards] [[-ConfigPath] <String>] [-SkipConfirmation]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Main function that orchestrates the complete BusinessPlus test environment refresh process.
This includes stopping services, restoring databases, configuring security, and restarting servers.

## EXAMPLES

### EXAMPLE 1
```
Invoke-BPERPDatabaseRestore -BPEnvironment "TEST" -IfasFilePath "\\backup\ifas.bak" -SyscatFilePath "\\backup\syscat.bak"
```

### EXAMPLE 2
```
Invoke-BPERPDatabaseRestore -BPEnvironment "QA" -IfasFilePath $ifas -SyscatFilePath $syscat -AspnetFilePath $aspnet -TestingMode -RestoreDashboards
```

## PARAMETERS

### -BPEnvironment
The name of the BusinessPlus environment to restore (e.g., TEST, QA, DEV)

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IfasFilePath
Path to the IFAS database backup file

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SyscatFilePath
Path to the SYSCAT database backup file

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AspnetFilePath
Path to the ASPNET database backup file (optional)

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TestingMode
Enable additional test accounts for testing purposes

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -RestoreDashboards
Copy dashboard files to the environment

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfigPath
Path to the INI configuration file.
Defaults to config\BPC.DBRefresh.ini

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipConfirmation
Skip the configuration review and confirmation prompt

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
