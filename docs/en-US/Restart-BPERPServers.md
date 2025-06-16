---
external help file: BPC.DBRefresh-help.xml
Module Name: BPC.DBRefresh
online version:
schema: 2.0.0
---

# Restart-BPERPServers

## SYNOPSIS
Restarts all BusinessPlus servers in the environment

## SYNTAX

```
Restart-BPERPServers [-Config] <Hashtable> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Initiates a restart of all servers to ensure services start properly
with the newly restored databases.

## EXAMPLES

### EXAMPLE 1
```
Restart-BPERPServers -Config $config
```

## PARAMETERS

### -Config
Configuration hashtable containing server lists

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
