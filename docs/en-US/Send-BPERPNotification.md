---
external help file: BPC.DBRefresh-help.xml
Module Name: BPC.DBRefresh
online version:
schema: 2.0.0
---

# Send-BPERPNotification

## SYNOPSIS
Sends email notification upon completion of the restore operation

## SYNTAX

```
Send-BPERPNotification [-Config] <Hashtable> [-BackupFiles] <Hashtable> [[-TestingMode] <Boolean>]
 [-StartTime] <DateTime> [-EndTime] <DateTime> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Sends an HTML formatted email to configured recipients with details
about the completed restore operation.

## EXAMPLES

### EXAMPLE 1
```
Send-BPERPNotification -Config $config -BackupFiles $files -StartTime $start -EndTime $end
```

## PARAMETERS

### -Config
Configuration hashtable containing SMTP settings

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
Hashtable containing backup file information

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

### -TestingMode
Whether testing mode was enabled

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartTime
When the restore operation started

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EndTime
When the restore operation completed

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: True
Position: 5
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
