param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = "test",
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = "",
    [Parameter(Mandatory=$false)]
    [string]$Version = ""
)

Write-Host "Rollback: Environment=$Environment, Project=$ProjectName, Version=$Version" -ForegroundColor Cyan
exit 0
