<#
PowerShell script placeholder to report deployment status.
Returns a JSON object with basic status information.
#>
param(
  [string]$Environment = "test"
)
 $info = @{
  environment = $Environment
  status = "idle"
  lastDeploy = (Get-Date).ToString("o")
}
ConvertTo-Json $info -Depth 2
