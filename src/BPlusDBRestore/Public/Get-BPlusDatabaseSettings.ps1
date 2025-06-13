function Get-BPlusDatabaseSettings {
  <#
  .SYNOPSIS
      Retrieves existing database connection settings
  
  .DESCRIPTION
      Queries the NUUPGDST table to backup existing connection string values
      before database restoration. These settings will be restored after the database restore.
  
  .PARAMETER Config
      Configuration hashtable containing database connection information
  
  .EXAMPLE
      $settings = Get-BPlusDatabaseSettings -Config $config
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [hashtable]$Config
  )

  Write-BPlusLog -Message "Retrieving existing database connection settings" -LogPath $script:LogPath
  
  try {
    $query = @"
SELECT NUGUID, NUVALUE
FROM NUUPGDST
WHERE NUGUID IN (
    '94d4ebaa-4592-4f8d-a993-5dc644ea30cf',
    'cb52bc9d-7144-496d-bc97-60ef098c9af6',
    '52c99ef9-df47-4d1f-b834-6afc62f3f5b2',
    '1861797f-1024-4e57-960a-87df8bb48e2f',
    'fc0e3ed1-13f5-4e35-8b4d-901e1b7e17fa',
    '3c5a3a16-2b1f-497f-b40b-a52c8e39cd59',
    '4733aac2-b88f-45a9-9b38-a6d06e37b956',
    '8bb973e1-3e14-4f7f-8e22-aafc1e9f7b65',
    'e03a9833-b37f-4dcb-bd48-ac6fe0e0bb3f',
    '30e7de90-da96-48f2-9fa5-b19c96c7dcb9',
    '5b96e5a8-3be0-4ad8-be06-b27c7a7bfea7',
    '9c8d4ebf-e02e-4022-833f-b3b3e45e9ce1',
    'ef1103c4-c2df-4bcd-929a-b86c3d8e8072',
    'd5b5e5ae-d86f-45c5-aef1-bf1cb6f02c01',
    '3b4cc67a-00d5-4dd9-a2fe-c2fd9419e50e',
    '248e7f47-c7f6-4dc7-a7ba-c5e3b8cf1a37',
    'f7636c80-fad5-4ab0-9e7f-c8b860cf6ec9',
    '659cde1b-cf76-442d-a3f1-cd9a948bdb0d',
    'f9c3b4d5-1e81-42e2-ad4e-d10cde689e5f',
    '7d7a0a7f-4bdc-401f-81de-d4c228fc5d95',
    '40e6dc5b-1c1e-411f-a7be-dd6c6e837f95',
    '80cdc6f1-f0eb-4e7b-bddc-de5cf9fcc3c4',
    '0af16e4f-e3c1-49de-84d3-e1df87cf5d6f',
    '37b24e66-5ea2-4861-adf4-e30ba3eda53f'
)
"@

    $settings = Invoke-Sqlcmd -ServerInstance $Config.SQLInstance -Database $Config.SYSCATdb -Query $query
    
    Write-BPlusLog -Message "Retrieved $($settings.Count) connection settings" -LogPath $script:LogPath
    return $settings
  }
  catch {
    Write-BPlusLog -Message "Error retrieving database settings: $_" -Level Error -LogPath $script:LogPath
    throw
  }
}