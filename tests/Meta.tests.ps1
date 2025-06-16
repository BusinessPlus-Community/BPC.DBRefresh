BeforeDiscovery {
    $projectRoot = Split-Path -Path $PSScriptRoot -Parent
    if (-not $projectRoot) {
        $projectRoot = Join-Path -Path $PSScriptRoot -ChildPath '..'
    }

    $allTextFiles = Get-ChildItem -Path $projectRoot -File -Recurse | 
        Where-Object { 
            @('.gitignore', '.gitattributes', '.ps1', '.psm1', '.psd1', '.ps1xml', '.txt', '.xml', '.cmd', '.json', '.md', '.yml', '.yaml', '.toml') -contains $_.Extension -and
            $_.FullName -notmatch '[\\/]\.git[\\/]' -and
            $_.FullName -notmatch '[\\/]Output[\\/]' -and
            $_.FullName -notmatch '[\\/]BuildOutput[\\/]' -and
            $_.FullName -notmatch '[\\/]\.vscode[\\/]' -and
            $_.FullName -notmatch '[\\/]node_modules[\\/]'
        }
}

Describe 'Text files formatting' {
    Context 'File encoding' {
        It 'No text file uses Unicode/UTF-16 encoding' {
            $badFiles = @()
            
            foreach ($file in $allTextFiles) {
                $encoding = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
                if ($encoding -match '[\x00]') {
                    $badFiles += $file.FullName
                }
            }
            
            $badFiles | Should -BeNullOrEmpty
        }
    }
    
    Context 'Indentations' {
        It 'No text file use tabs for indentations' {
            $badFiles = @()
            
            foreach ($file in $allTextFiles) {
                $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
                if ($content -match '\t') {
                    # Skip files that are allowed to have tabs
                    if ($file.Name -in @('Makefile', '.gitmodules')) {
                        continue
                    }
                    $badFiles += $file.FullName
                }
            }
            
            $badFiles | Should -BeNullOrEmpty
        }
    }
}