<#
Artifact signing placeholder.
> 
param([string]$ArtifactPath)
$Signature = "$ArtifactPath|signature-placeholder"
Write-Host "Artifact signed: $ArtifactPath" -ForegroundColor Green
exit 0
