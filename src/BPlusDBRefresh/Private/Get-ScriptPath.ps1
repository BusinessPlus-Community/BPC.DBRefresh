function Get-ScriptPath {
    <#
    .SYNOPSIS
        Gets the path to the script or module root directory.

    .DESCRIPTION
        Returns the directory path where the module or calling script is located.
        This provides a reliable way to reference resources relative to the module.

    .EXAMPLE
        $resourcePath = Join-Path -Path (Get-ScriptPath) -ChildPath 'Resources'

    .OUTPUTS
        System.String - The full path to the script/module directory.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    # Try module root first
    if ($script:ModuleRoot) {
        return $script:ModuleRoot
    }

    # Fall back to PSScriptRoot
    if ($PSScriptRoot) {
        return $PSScriptRoot
    }

    # Last resort - current location
    return (Get-Location).Path
}


function Get-ResourcePath {
    <#
    .SYNOPSIS
        Gets the path to the module's Resources directory.

    .DESCRIPTION
        Returns the full path to the Resources directory within the module,
        which contains SQL scripts, templates, and other static files.

    .PARAMETER SubPath
        Optional subdirectory or file within Resources.

    .EXAMPLE
        $sqlPath = Get-ResourcePath -SubPath 'SQL'

    .EXAMPLE
        $templatePath = Get-ResourcePath -SubPath 'Templates\CompletionEmail.html'

    .OUTPUTS
        System.String - The full path to the resources directory or file.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Position = 0)]
        [string]$SubPath
    )

    $resourcesRoot = if ($script:ResourcesPath) {
        $script:ResourcesPath
    } else {
        Join-Path -Path (Get-ScriptPath) -ChildPath 'Resources'
    }

    if ($SubPath) {
        Join-Path -Path $resourcesRoot -ChildPath $SubPath
    } else {
        $resourcesRoot
    }
}


function Get-SqlResourceContent {
    <#
    .SYNOPSIS
        Reads the content of a SQL resource file.

    .DESCRIPTION
        Loads a SQL script from the Resources/SQL directory and optionally
        replaces parameter placeholders with actual values.

    .PARAMETER FileName
        The name of the SQL file (without path).

    .PARAMETER Parameters
        A hashtable of parameter names and values to replace in the SQL.
        Parameter names in SQL should be prefixed with @ (e.g., @DatabaseName).

    .EXAMPLE
        $sql = Get-SqlResourceContent -FileName 'Set-IfasPermissions.sql' -Parameters @{
            Database = 'TestDB'
            AdminSource = 'DOMAIN\OldAdmin'
            AdminDestination = 'DOMAIN\NewAdmin'
        }

    .OUTPUTS
        System.String - The SQL script content with parameters replaced.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$FileName,

        [Parameter()]
        [hashtable]$Parameters
    )

    $sqlPath = Get-ResourcePath -SubPath "SQL\$FileName"

    if (-not (Test-Path -Path $sqlPath)) {
        throw "SQL resource file not found: $sqlPath"
    }

    $sqlContent = Get-Content -Path $sqlPath -Raw -ErrorAction Stop

    if ($Parameters) {
        foreach ($key in $Parameters.Keys) {
            $placeholder = "@$key"
            $value = $Parameters[$key]
            $sqlContent = $sqlContent -replace [regex]::Escape($placeholder), $value
        }
    }

    $sqlContent
}


function Get-TemplateContent {
    <#
    .SYNOPSIS
        Reads the content of a template file.

    .DESCRIPTION
        Loads a template from the Resources/Templates directory and replaces
        placeholder tokens with actual values.

    .PARAMETER FileName
        The name of the template file (without path).

    .PARAMETER Tokens
        A hashtable of token names and values to replace in the template.
        Tokens in the template should use {{TokenName}} format.

    .EXAMPLE
        $html = Get-TemplateContent -FileName 'CompletionEmail.html' -Tokens @{
            Environment = 'TEST1'
            RequestedBy = 'DOMAIN\User'
        }

    .OUTPUTS
        System.String - The template content with tokens replaced.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$FileName,

        [Parameter()]
        [hashtable]$Tokens
    )

    $templatePath = Get-ResourcePath -SubPath "Templates\$FileName"

    if (-not (Test-Path -Path $templatePath)) {
        throw "Template file not found: $templatePath"
    }

    $templateContent = Get-Content -Path $templatePath -Raw -ErrorAction Stop

    if ($Tokens) {
        foreach ($key in $Tokens.Keys) {
            $placeholder = "{{$key}}"
            $value = $Tokens[$key]
            $templateContent = $templateContent -replace [regex]::Escape($placeholder), $value
        }
    }

    $templateContent
}
