---
external help file: BPC.DBRefresh-help.xml
Module Name: BPC.DBRefresh
online version:
schema: 2.0.0
---

# Invoke-BPERPDatabaseRestoreFiles

## SYNOPSIS
Restores BusinessPlus database files from backups

## SYNTAX

```
Invoke-BPERPDatabaseRestoreFiles [-Config] <Hashtable> [-BackupFiles] <Hashtable>
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Performs the actual database restore operations for ASPNET, SYSCAT, and IFAS databases.
Uses dbatools for reliable database restoration with proper file relocation.

## EXAMPLES

### EXAMPLE 1
```
Invoke-BPERPDatabaseRestoreFiles -Config $config -BackupFiles @{IFAS = 'C:\backup\ifas.bak'; SYSCAT = 'C:\backup\syscat.bak'}
```

## PARAMETERS

### -Config
Configuration hashtable containing database and file path information

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -BackupFiles
Hashtable containing paths to backup files (ASPNET, SYSCAT, IFAS)

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
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
