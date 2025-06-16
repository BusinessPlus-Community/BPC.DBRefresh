---
external help file: BPC.DBRefresh-help.xml
Module Name: BPC.DBRefresh
online version:
schema: 2.0.0
---

# Set-BPERPConfiguration

## SYNOPSIS
Applies post-restore configuration settings to BusinessPlus

## SYNTAX

```
Set-BPERPConfiguration [-Config] <Hashtable> [[-TestingMode] <Boolean>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Updates various BusinessPlus settings after database restore including:
- NUUPAUSY display text with backup date
- Disables user accounts (except manager codes)
- Updates email addresses to dummy values
- Disables non-essential workflows

## EXAMPLES

### EXAMPLE 1
```
Set-BPERPConfiguration -Config $config -TestingMode $false
```

## PARAMETERS

### -Config
Configuration hashtable containing database and environment information

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

### -TestingMode
When enabled, preserves additional test accounts

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: False
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
