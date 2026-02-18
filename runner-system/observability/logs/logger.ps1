# script: logger.ps1
param(
    [string]$Message,
    [string]$Level = "INFO",
    [string]$Component = "observability",
    [string]$OutputFile = "",
    [switch]$Structured,
    [switch]$Verbose
)

function Write-Structured-Log {
    param($Message, $Level, $Component, $OutputFile, $Verbose)
    
    $logEntry = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        level = $Level.ToUpper()
        component = $Component.ToLower()
        message = $Message
        host = $env:COMPUTERNAME
        process_id = $PID
        thread_id = (Get-Random -Minimum 1000 -Maximum 9999)
    }
    
    if (-not $OutputFile) {
        $logPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../logs/observability_$(Get-Date -Format 'yyyyMMdd').log"
    } else {
        $logPath = $OutputFile
    }
    
    # Ensure log directory exists
    $logDir = Split-Path $logPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    # Write to file
    $logEntry | ConvertTo-Json | Out-File $logPath -Append
    
    # Output to console based on level
    $consoleColor = switch ($Level.ToUpper()) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "INFO" { "Green" }
        "DEBUG" { "Gray" }
        Default { "White" }
    }
    
    if ($Verbose -or $Level -ne "DEBUG") {
        Write-Host "[$($logEntry.timestamp)] [$($logEntry.level)] [$($logEntry.component)] $($logEntry.message)" -ForegroundColor $consoleColor
    }
    
    return $logEntry
}

function Write-Traditional-Log {
    param($Message, $Level, $Component, $OutputFile, $Verbose)
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp] [$Level] [$Component] $Message"
    
    if (-not $OutputFile) {
        $logPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../logs/observability_$(Get-Date -Format 'yyyyMMdd').log"
    } else {
        $logPath = $OutputFile
    }
    
    # Ensure log directory exists
    $logDir = Split-Path $logPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    # Write to file
    $logLine | Out-File $logPath -Append
    
    # Output to console based on level
    $consoleColor = switch ($Level.ToUpper()) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "INFO" { "Green" }
        "DEBUG" { "Gray" }
        Default { "White" }
    }
    
    if ($Verbose -or $Level -ne "DEBUG") {
        Write-Host $logLine -ForegroundColor $consoleColor
    }
    
    return $logLine
}

if ($Structured) {
    Write-Structured-Log -Message $Message -Level $Level -Component $Component -OutputFile $OutputFile -Verbose:$Verbose
} else {
    Write-Traditional-Log -Message $Message -Level $Level -Component $Component -OutputFile $OutputFile -Verbose:$Verbose
}

# Export functions for module use
Export-ModuleMember -Function *-*