# script: profile.ps1
param(
    [string]$Action = "apply",
    [string]$Profile = "dev",
    [string]$Target = ".",
    [switch]$List,
    [switch]$Show,
    [switch]$Validate,
    [switch]$Backup,
    [switch]$Verbose
)

function Get-Profiles {
    param($Verbose)
    
    $profilesPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../"
    $profileDirs = Get-ChildItem $profilesPath -Directory
    
    $profiles = @()
    foreach ($dir in $profileDirs) {
        $profileFile = Join-Path $dir.FullName "profile.json"
        if (Test-Path $profileFile) {
            $profile = Get-Content $profileFile | ConvertFrom-Json
            $profiles += @{
                name = $profile.profile
                description = $profile.description
                version = $profile.version
                created_at = $profile.created_at
                path = $dir.FullName
            }
        }
    }
    
    return $profiles
}

function Apply-Profile {
    param($Profile, $Target, $Verbose)
    
    $profilesPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../"
    $profileDir = Join-Path $profilesPath $Profile
    $profileFile = Join-Path $profileDir "profile.json"
    
    if (-not (Test-Path $profileFile)) {
        Write-Error "Profile '$Profile' not found at: $profileFile" -ForegroundColor Red
        Write-Host "Available profiles: $(Get-Profiles | ForEach-Object { $_.name } -join ", ")" -ForegroundColor Yellow
        exit 1
    }
    
    $profile = Get-Content $profileFile | ConvertFrom-Json
    
    Write-Host "=== Runner Profile System ===" -ForegroundColor Cyan
    Write-Host "Applying profile: $($profile.profile)" -ForegroundColor Yellow
    Write-Host "Description: $($profile.description)" -ForegroundColor White
    Write-Host "Version: $($profile.version)" -ForegroundColor White
    Write-Host "Created: $($profile.created_at)" -ForegroundColor White
    Write-Host ""
    
    # Validate target directory
    if (-not (Test-Path $Target)) {
        Write-Host "Creating target directory: $Target" -ForegroundColor Cyan
        New-Item -ItemType Directory -Path $Target -Force | Out-Null
    }
    
    $targetPath = Resolve-Path $Target
    
    # Apply environment variables
    Write-Host "1. Applying environment variables..." -ForegroundColor Yellow
    foreach ($var in $profile.environment_variables.GetEnumerator()) {
        $envVarName = $var.Name
        $envVarValue = $var.Value
        
        # Backup existing variable if backup flag is set
        if ($Backup -and (Test-Path "env:$envVarName")) {
            $backupValue = Get-ChildItem "env:$envVarName" -ErrorAction SilentlyContinue
            $backupFile = Join-Path $targetPath ".env.backup.$envVarName"
            "$envVarName=$backupValue" | Out-File $backupFile
            Write-Host "  Backed up: $envVarName" -ForegroundColor Yellow
        }
        
        # Set environment variable
        Set-Item -Path "env:$envVarName" -Value $envVarValue
        Write-Host "  Set: $envVarName=$envVarValue" -ForegroundColor Green
    }
    
    # Apply paths
    Write-Host "2. Applying paths..." -ForegroundColor Yellow
    foreach ($path in $profile.paths.GetEnumerator()) {
        $pathName = $path.Name
        $pathValue = $path.Value
        
        # Resolve relative paths
        if ($pathValue -match "^\.\.") {
            $pathValue = Join-Path $targetPath $pathValue
        }
        
        # Create directory if it doesn't exist
        if (-not (Test-Path $pathValue)) {
            Write-Host "  Creating directory: $pathValue" -ForegroundColor Cyan
            New-Item -ItemType Directory -Path $pathValue -Force | Out-Null
        }
        
        Write-Host "  Path: $pathName = $pathValue" -ForegroundColor Green
    }
    
    # Apply settings to existing configurations
    Write-Host "3. Applying settings to existing configurations..." -ForegroundColor Yellow
    
    # Apply to supervisor
    $supervisorPath = "$targetPath/runner-system/supervisor"
    if (Test-Path $supervisorPath) {
        $supervisorConfig = "$supervisorPath/config/supervisor.json"
        if (Test-Path $supervisorConfig) {
            $supConfig = Get-Content $supervisorConfig | ConvertFrom-Json
            $supConfig.health_interval = $profile.settings.health_check.interval
            $supConfig | ConvertTo-Json -Depth 10 | Set-Content $supervisorConfig
            Write-Host "  Updated: supervisor health interval to $($profile.settings.health_check.interval)s" -ForegroundColor Green
        }
    }
    
    # Apply to build
    $buildPath = "$targetPath/runner-system/build"
    if (Test-Path $buildPath) {
        $buildConfig = "$buildPath/config/build.json"
        if (Test-Path $buildConfig) {
            $bldConfig = Get-Content $buildConfig | ConvertFrom-Json
            $bldConfig.output_dir = $profile.paths.artifacts
            $bldConfig | ConvertTo-Json -Depth 10 | Set-Content $buildConfig
            Write-Host "  Updated: build output directory to $($profile.paths.artifacts)" -ForegroundColor Green
        }
    }
    
    # Apply to observability
    $obsPath = "$targetPath/runner-system/observability"
    if (Test-Path $obsPath) {
        # Update logger settings
        $loggerPath = "$obsPath/logs/logger.ps1"
        if (Test-Path $loggerPath) {
            $loggerContent = Get-Content $loggerPath -Raw
            $loggerContent = $loggerContent -replace "observability_\\\(Get-Date -Format 'yyyyMMdd'\).log", $profile.paths.logs + "/$($profile.profile)_\\\(Get-Date -Format 'yyyyMMdd'\).log"
            $loggerContent | Out-File $loggerPath
            Write-Host "  Updated: observability log path" -ForegroundColor Green
        }
        
        # Update metrics settings
        $metricsPath = "$obsPath/metrics/metrics.ps1"
        if (Test-Path $metricsPath) {
            $metricsContent = Get-Content $metricsPath -Raw
            $metricsContent = $metricsContent -replace "metrics_data", $profile.paths.metrics
            $metricsContent | Out-File $metricsPath
            Write-Host "  Updated: observability metrics path" -ForegroundColor Green
        }
    }
    
    # Apply to deploy
    $deployPath = "$targetPath/runner-system/deploy"
    if (Test-Path $deployPath) {
        $deployConfig = "$deployPath/config/deploy.json"
        if (Test-Path $deployConfig) {
            $depConfig = Get-Content $deployConfig | ConvertFrom-Json
            $depConfig.environments = $profile.settings.deploy.environment
            $depConfig | ConvertTo-Json -Depth 10 | Set-Content $deployConfig
            Write-Host "  Updated: deploy environment to $($profile.settings.deploy.environment)" -ForegroundColor Green
        }
    }
    
    # Apply to security
    $securityPath = "$targetPath/runner-system/security"
    if (Test-Path $securityPath) {
        $securityConfig = "$securityPath/policies/security.json"
        if (Test-Path $securityConfig) {
            $secConfig = Get-Content $securityConfig | ConvertFrom-Json
            $secConfig.password_policy.minimum_length = $profile.settings.security.password_policy.minimum_length
            $secConfig | ConvertTo-Json -Depth 10 | Set-Content $securityConfig
            Write-Host "  Updated: security password policy" -ForegroundColor Green
        }
    }
    
    # Apply to cluster
    $clusterPath = "$targetPath/runner-system/cluster"
    if (Test-Path $clusterPath) {
        $clusterConfig = "$clusterPath/config/cluster.json"
        if (Test-Path $clusterConfig) {
            $cluConfig = Get-Content $clusterConfig | ConvertFrom-Json
            $cluConfig.config.heartbeat_interval = $profile.settings.cluster.heartbeat_interval
            $cluConfig | ConvertTo-Json -Depth 10 | Set-Content $clusterConfig
            Write-Host "  Updated: cluster heartbeat interval to $($profile.settings.cluster.heartbeat_interval)s" -ForegroundColor Green
        }
    }
    
    # Create profile marker file
    $profileMarker = Join-Path $targetPath ".runner-profile"
    "$Profile" | Out-File $profileMarker
    Write-Host "  Created profile marker: $profileMarker" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Profile '$Profile' applied successfully!" -ForegroundColor Green
    Write-Host "Target: $targetPath" -ForegroundColor Yellow
    Write-Host ""
    
    if ($Verbose) {
        Write-Host "Applied settings summary:" -ForegroundColor Cyan
        Write-Host "  Logging level: $($profile.settings.logging.level)" -ForegroundColor White
        Write-Host "  Health check interval: $($profile.settings.health_check.interval)s" -ForegroundColor White
        Write-Host "  Metrics interval: $($profile.settings.metrics.interval)s" -ForegroundColor White
        Write-Host "  Build mode: $($profile.settings.build.mode)" -ForegroundColor White
        Write-Host "  Security audit: $($profile.settings.security.audit_enabled)" -ForegroundColor White
    }
    
    # Save applied profile log
    $logDir = Join-Path $targetPath "logs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    $logFile = "profile_apply_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    $logPath = Join-Path $logDir $logFile
    
    $logEntry = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        action = "PROFILE_APPLY"
        profile = $Profile
        target = $targetPath
        status = "SUCCESS"
        settings_applied = $profile.settings.Keys
    }
    
    $logEntry | ConvertTo-Json | Out-File $logPath
    
    if ($Verbose) {
        Write-Host "Profile application log saved to: $logPath" -ForegroundColor Cyan
    }
    
    exit 0
}

function List-Profiles {
    param($Verbose)
    
    $profiles = Get-Profiles -Verbose:$Verbose
    
    Write-Host "=== Available Profiles ===" -ForegroundColor Cyan
    foreach ($profile in $profiles) {
        Write-Host "  $($profile.name):" -ForegroundColor Green
        Write-Host "    Description: $($profile.description)" -ForegroundColor White
        Write-Host "    Version: $($profile.version)" -ForegroundColor White
        Write-Host "    Created: $($profile.created_at)" -ForegroundColor White
        Write-Host "    Path: $($profile.path)" -ForegroundColor White
        Write-Host ""
    }
    
    exit 0
}

function Show-Profile {
    param($Profile, $Verbose)
    
    $profilesPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../"
    $profileDir = Join-Path $profilesPath $Profile
    $profileFile = Join-Path $profileDir "profile.json"
    
    if (-not (Test-Path $profileFile)) {
        Write-Error "Profile '$Profile' not found at: $profileFile" -ForegroundColor Red
        exit 1
    }
    
    $profile = Get-Content $profileFile | ConvertFrom-Json
    
    Write-Host "=== Profile Details ===" -ForegroundColor Cyan
    Write-Host "Name: $($profile.profile)" -ForegroundColor Yellow
    Write-Host "Description: $($profile.description)" -ForegroundColor White
    Write-Host "Version: $($profile.version)" -ForegroundColor White
    Write-Host "Created: $($profile.created_at)" -ForegroundColor White
    Write-Host "Author: $($profile.author)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Settings:" -ForegroundColor Cyan
    foreach ($setting in $profile.settings.GetEnumerator()) {
        Write-Host "  $($setting.Name):" -ForegroundColor Green
        if ($setting.Value -is [hashtable]) {
            foreach ($subSetting in $setting.Value.GetEnumerator()) {
                Write-Host "    $($subSetting.Name): $($subSetting.Value)" -ForegroundColor White
            }
        } else {
            Write-Host "    Value: $($setting.Value)" -ForegroundColor White
        }
    }
    
    Write-Host ""
    Write-Host "Dependencies:" -ForegroundColor Cyan
    Write-Host "  Required: $($profile.dependencies.required -join ", ")" -ForegroundColor White
    Write-Host "  Optional: $($profile.dependencies.optional -join ", ")" -ForegroundColor White
    
    Write-Host ""
    Write-Host "Environment Variables:" -ForegroundColor Cyan
    foreach ($var in $profile.environment_variables.GetEnumerator()) {
        Write-Host "  $($var.Name) = $($var.Value)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "Paths:" -ForegroundColor Cyan
    foreach ($path in $profile.paths.GetEnumerator()) {
        Write-Host "  $($path.Name) = $($path.Value)" -ForegroundColor White
    }
    
    exit 0
}

function Validate-Profile {
    param($Profile, $Verbose)
    
    $profilesPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../"
    $profileDir = Join-Path $profilesPath $Profile
    $profileFile = Join-Path $profileDir "profile.json"
    
    if (-not (Test-Path $profileFile)) {
        Write-Error "Profile '$Profile' not found at: $profileFile" -ForegroundColor Red
        exit 1
    }
    
    $profile = Get-Content $profileFile | ConvertFrom-Json
    
    Write-Host "=== Profile Validation ===" -ForegroundColor Cyan
    Write-Host "Validating profile: $($profile.profile)" -ForegroundColor Yellow
    Write-Host ""
    
    $validationErrors = @()
    $validationWarnings = @()
    
    # Validate required fields
    $requiredFields = @("profile", "description", "version", "created_at", "author", "settings", "dependencies", "environment_variables", "paths")
    foreach ($field in $requiredFields) {
        if (-not $profile.PSObject.Properties.Name.Contains($field)) {
            $validationErrors += "Missing required field: $field"
        }
    }
    
    # Validate settings structure
    $requiredSettings = @("logging", "health_check", "metrics", "build", "deploy", "security", "observability", "cluster", "sdk", "profiles")
    foreach ($setting in $requiredSettings) {
        if (-not $profile.settings.PSObject.Properties.Name.Contains($setting)) {
            $validationErrors += "Missing required setting: $setting"
        }
    }
    
    # Validate dependencies
    if ($profile.dependencies.required.Count -eq 0) {
        $validationWarnings += "No required dependencies specified"
    }
    
    # Validate environment variables
    $invalidEnvVars = $profile.environment_variables.GetEnumerator() | Where-Object { $_.Name -match "[^a-zA-Z0-9_]" }
    foreach ($invalid in $invalidEnvVars) {
        $validationErrors += "Invalid environment variable name: $($invalid.Name)"
    }
    
    # Validate paths
    $invalidPaths = $profile.paths.GetEnumerator() | Where-Object { $_.Value -match "[^a-zA-Z0-9_/.-]" }
    foreach ($invalid in $invalidPaths) {
        $validationWarnings += "Suspicious path value: $($_.Value)"
    }
    
    # Display results
    if ($validationErrors.Count -gt 0) {
        Write-Host "Validation Errors ($($validationErrors.Count))" -ForegroundColor Red
        foreach ($error in $validationErrors) {
            Write-Host "  - $error" -ForegroundColor Red
        }
    }
    
    if ($validationWarnings.Count -gt 0) {
        Write-Host "Validation Warnings ($($validationWarnings.Count))" -ForegroundColor Yellow
        foreach ($warning in $validationWarnings) {
            Write-Host "  - $warning" -ForegroundColor Yellow
        }
    }
    
    if ($validationErrors.Count -eq 0) {
        Write-Host "Profile validation passed successfully!" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "Profile validation failed with errors." -ForegroundColor Red
        exit 1
    }
}

switch ($Action.ToLower()) {
    "apply" {
        Apply-Profile -Profile $Profile -Target $Target -Verbose:$Verbose
    }
    "list" {
        List-Profiles -Verbose:$Verbose
    }
    "show" {
        Show-Profile -Profile $Profile -Verbose:$Verbose
    }
    "validate" {
        Validate-Profile -Profile $Profile -Verbose:$Verbose
    }
    default {
        Write-Host "Usage: orbit profile {apply|list|show|validate} [options]" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor Cyan
        Write-Host "  apply <profile>    Apply profile to target directory" -ForegroundColor White
        Write-Host "  list                List all available profiles" -ForegroundColor White
        Write-Host "  show <profile>      Show profile details" -ForegroundColor White
        Write-Host "  validate <profile>  Validate profile configuration" -ForegroundColor White
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor Cyan
        Write-Host "  orbit profile apply dev" -ForegroundColor White
        Write-Host "  orbit profile apply ai -Target ./my-project" -ForegroundColor White
        Write-Host "  orbit profile list" -ForegroundColor White
        Write-Host "  orbit profile show enterprise" -ForegroundColor White
        Write-Host "  orbit profile validate dev" -ForegroundColor White
        exit 1
    }
}

# Export functions for module use
Export-ModuleMember -Function *-*