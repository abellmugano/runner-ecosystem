function Write-OCLog {
  param(
    [Parameter(Mandatory=$true)]
    [string]$Message,
    [ValidateSet("INFO","WARN","ERROR","DEBUG")]
    [string]$Level = "INFO",
    [string]$LogFile = $null
  )
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $line = "$ts [$Level] $Message"
  Write-Host $line
  if ($LogFile) {
     try { Add-Content -Path $LogFile -Value $line } catch { }
  }
}

function Get-ApiJson {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)]
    [string]$Uri,
    [int]$RetryCount = 3,
    [int]$DelaySeconds = 2,
    [hashtable]$Headers = @{},
    [int]$TimeoutSeconds = 30
  )
  $attempt = 0
  while ($attempt -lt $RetryCount) {
     $attempt++
     try {
        $response = Invoke-RestMethod -Uri $Uri -Headers $Headers -TimeoutSec $TimeoutSeconds
        return $response
     } catch {
        Write-OCLog -Message "Attempt $attempt failed for $Uri. $_" -Level "ERROR"
        if ($attempt -ge $RetryCount) {
           throw
        }
        Start-Sleep -Seconds $DelaySeconds
     }
  }
}

function Write-JsonToFile {
  [CmdletBinding()]
  param(
     [Parameter(Mandatory=$true)]
     [Object]$Data,
     [Parameter(Mandatory=$true)]
     [string]$Path,
     [int]$Depth = 10
  )
  $Json = $Data | ConvertTo-Json -Depth $Depth
  $dir = Split-Path -Path $Path -Parent
  if (-not (Test-Path -Path $dir)) {
     New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  $tempPath = "$Path.tmp"
  $Json | Out-File -FilePath $tempPath -Encoding UTF8 -Width 5000
  Move-Item -Path $tempPath -Destination $Path -Force
  Write-OCLog -Message "Wrote JSON to $Path" -Level "INFO"
}

function Get-ProcessingSummary {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)]
    [string]$Path
  )
  if (-not (Test-Path -Path $Path)) {
    return @{ Path = $Path; Exists = $false; SizeBytes = 0 }
  }
  $bytes = (Get-Item $Path).Length
  return @{ Path = $Path; Exists = $true; SizeBytes = $bytes }
}

Export-ModuleMember -Function Get-ApiJson, Write-JsonToFile, Get-ProcessingSummary, Write-OCLog
