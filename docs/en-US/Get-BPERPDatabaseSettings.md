---
external help file: BPC.DBRefresh-help.xml
Module Name: BPC.DBRefresh
online version:
schema: 2.0.0
---

# Get-BPERPDatabaseSettings

## SYNOPSIS
Retrieves existing database connection settings

## SYNTAX

```
Get-BPERPDatabaseSettings [-Config] <Hashtable> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Queries the NUUPGDST table to backup existing connection string values
before database restoration.
These settings will be restored after the database restore.

## EXAMPLES

### EXAMPLE 1
```
$settings = Get-BPERPDatabaseSettings -Config $config
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
