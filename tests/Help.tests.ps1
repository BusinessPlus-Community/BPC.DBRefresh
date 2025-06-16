BeforeDiscovery {
    $projectRoot = Split-Path -Path $PSScriptRoot -Parent
    $modulePath = Join-Path -Path $projectRoot -ChildPath 'BPC.DBRefresh'
    
    # Import the module
    Import-Module $modulePath -Force
    
    $exportedCommands = (Get-Module -Name BPC.DBRefresh).ExportedCommands.Values | 
        Where-Object { $_.CommandType -eq 'Function' }
}

Describe "Test help for <_.Name>" -ForEach $exportedCommands {
    BeforeAll {
        $command = $_
        $help = Get-Help $command.Name -Full
    }
    
    It 'Help is not auto-generated' {
        $help.Synopsis | Should -Not -BeLike '*<CommonParameters>*'
    }
    
    It 'Has description' {
        $help.Description.Text | Should -Not -BeNullOrEmpty
    }
    
    It 'Has example code' {
        $help.Examples.Example.Code | Should -Not -BeNullOrEmpty
    }
    
    It 'Has example help' {
        $help.Examples.Example | ForEach-Object {
            $_.Remarks.Text | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Parameter <_.Name>" -ForEach $command.Parameters.Values {
        BeforeAll {
            $parameter = $_
            $parameterName = $parameter.Name
            $parameterHelp = $help.parameters.parameter | Where-Object { $_.Name -eq $parameterName }
            $parameterHelpType = if ($parameterHelp.parameterValue) { $parameterHelp.parameterValue.Trim() }
            
            # Handle common parameters that might not have help
            $commonParameters = @(
                'Debug', 'ErrorAction', 'ErrorVariable', 'InformationAction',
                'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable',
                'Verbose', 'WarningAction', 'WarningVariable', 'WhatIf', 'Confirm',
                'ProgressAction'
            )
            $isCommonParameter = $parameterName -in $commonParameters
            
            # Determine if mandatory
            $codeMandatory = $parameter.Attributes | 
                Where-Object { $_.TypeId.Name -eq 'ParameterAttribute' } |
                Select-Object -ExpandProperty Mandatory -ErrorAction SilentlyContinue
        }
        
        It 'Has description' -Skip:$isCommonParameter {
            $parameterHelp.Description.Text | Should -Not -BeNullOrEmpty
        }
        
        It 'Has correct [mandatory] value' -Skip:$isCommonParameter {
            $parameterHelp.Required | Should -Be $codeMandatory
        }
        
        It 'Has correct parameter type' -Skip:$isCommonParameter {
            $parameterHelpType | Should -Be $parameter.ParameterType.Name
        }
    }
}