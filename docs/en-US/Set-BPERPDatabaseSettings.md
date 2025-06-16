---
external help file: BPC.DBRefresh-help.xml
Module Name: BPC.DBRefresh
online version:
schema: 2.0.0
---

# Set-BPERPDatabaseSettings

## SYNOPSIS
Restores database connection settings after database restore

## SYNTAX

```
Set-BPERPDatabaseSettings [-Config] <Hashtable> [-Settings] <Object[]> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Updates the NUUPGDST table with the connection settings that were
backed up before the database restore operation.

## EXAMPLES

### EXAMPLE 1
```
Set-BPERPDatabaseSettings -Config $config -Settings $savedSettings
```

## PARAMETERS

### -Config
Configuration hashtable containing database connection information

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

### -Settings
Array of settings retrieved from Get-BPERPDatabaseSettings

```yaml
Type: Object[]
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
