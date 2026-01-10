function Test-MailKitAvailable {
    <#
    .SYNOPSIS
        Tests if MailKit and MimeKit assemblies are available.

    .DESCRIPTION
        Checks if MailKit and MimeKit NuGet packages are installed and their
        assemblies can be loaded. Returns detailed information about availability.

    .EXAMPLE
        if (Test-MailKitAvailable) {
            # Proceed with email operations
        }

    .EXAMPLE
        $result = Test-MailKitAvailable -Detailed
        if (-not $result.Available) {
            Write-Warning $result.Message
        }

    .PARAMETER Detailed
        Returns a detailed object with availability status and paths instead of a boolean.

    .OUTPUTS
        System.Boolean or PSCustomObject depending on -Detailed switch.
    #>
    [CmdletBinding()]
    [OutputType([bool], [PSCustomObject])]
    param(
        [Parameter()]
        [switch]$Detailed
    )

    $result = [PSCustomObject]@{
        Available       = $false
        MailKitPath     = $null
        MimeKitPath     = $null
        MailKitLoaded   = $false
        MimeKitLoaded   = $false
        Message         = ''
        NuGetPath       = $null
    }

    try {
        # Check if assemblies are already loaded
        $mailKitAssembly = [System.AppDomain]::CurrentDomain.GetAssemblies() |
            Where-Object { $_.GetName().Name -eq 'MailKit' }
        $mimeKitAssembly = [System.AppDomain]::CurrentDomain.GetAssemblies() |
            Where-Object { $_.GetName().Name -eq 'MimeKit' }

        if ($mailKitAssembly -and $mimeKitAssembly) {
            $result.Available = $true
            $result.MailKitLoaded = $true
            $result.MimeKitLoaded = $true
            $result.Message = 'MailKit and MimeKit assemblies are already loaded'

            if ($Detailed) { return $result }
            return $true
        }

        # Common NuGet package locations
        $nugetPaths = @(
            "$env:USERPROFILE\.nuget\packages",
            "$env:ProgramFiles\PackageManagement\NuGet\Packages",
            "${env:ProgramFiles(x86)}\PackageManagement\NuGet\Packages",
            "C:\Program Files\PackageManagement\NuGet\Packages"
        )

        $mailKitPath = $null
        $mimeKitPath = $null

        foreach ($basePath in $nugetPaths) {
            if (-not (Test-Path -Path $basePath)) { continue }

            # Find MailKit DLL
            if (-not $mailKitPath) {
                $mailKitDirs = Get-ChildItem -Path $basePath -Directory -Filter 'mailkit*' -ErrorAction SilentlyContinue |
                    Sort-Object Name -Descending
                foreach ($dir in $mailKitDirs) {
                    $dllPaths = @(
                        (Join-Path -Path $dir.FullName -ChildPath 'lib\net45\MailKit.dll'),
                        (Join-Path -Path $dir.FullName -ChildPath 'lib\netstandard2.0\MailKit.dll'),
                        (Join-Path -Path $dir.FullName -ChildPath 'lib\net461\MailKit.dll')
                    )
                    foreach ($dllPath in $dllPaths) {
                        if (Test-Path -Path $dllPath) {
                            $mailKitPath = $dllPath
                            $result.NuGetPath = $basePath
                            break
                        }
                    }
                    if ($mailKitPath) { break }
                }
            }

            # Find MimeKit DLL
            if (-not $mimeKitPath) {
                $mimeKitDirs = Get-ChildItem -Path $basePath -Directory -Filter 'mimekit*' -ErrorAction SilentlyContinue |
                    Sort-Object Name -Descending
                foreach ($dir in $mimeKitDirs) {
                    $dllPaths = @(
                        (Join-Path -Path $dir.FullName -ChildPath 'lib\net45\MimeKit.dll'),
                        (Join-Path -Path $dir.FullName -ChildPath 'lib\netstandard2.0\MimeKit.dll'),
                        (Join-Path -Path $dir.FullName -ChildPath 'lib\net461\MimeKit.dll')
                    )
                    foreach ($dllPath in $dllPaths) {
                        if (Test-Path -Path $dllPath) {
                            $mimeKitPath = $dllPath
                            break
                        }
                    }
                    if ($mimeKitPath) { break }
                }
            }

            if ($mailKitPath -and $mimeKitPath) { break }
        }

        $result.MailKitPath = $mailKitPath
        $result.MimeKitPath = $mimeKitPath

        if ($mailKitPath -and $mimeKitPath) {
            $result.Available = $true
            $result.Message = 'MailKit and MimeKit packages found'
        } elseif (-not $mailKitPath -and -not $mimeKitPath) {
            $result.Message = 'Neither MailKit nor MimeKit packages found. Run Install-MailKitDependency to install.'
        } elseif (-not $mailKitPath) {
            $result.Message = 'MailKit package not found. Run Install-MailKitDependency to install.'
        } else {
            $result.Message = 'MimeKit package not found. Run Install-MailKitDependency to install.'
        }

    } catch {
        $result.Message = "Error checking MailKit availability: $($_.Exception.Message)"
    }

    if ($Detailed) { return $result }
    return $result.Available
}
