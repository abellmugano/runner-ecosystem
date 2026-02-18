# script: logs.ps1
param(
    [string]$Level = "INFO",
    [string]$Component = "observability",
    [int]$Count = 10,
    [switch]$Follow,
    [switch]$Structured,
    [switch]$Verbose
)

function Get-Logs {
    param($Level, $Component, $Count, $Follow, $Structured, $Verbose)
    
    $logPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../logs/observability_$(Get-Date -Format 'yyyyMMdd').log"
    
    if (-not (Test-Path $logPath)) {
        Write-Host "No log file found: $logPath" -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host "=== Runner Observability Logs ===" -ForegroundColor Cyan
    Write-Host "Log File: $logPath" -ForegroundColor Yellow
    Write-Host "Level Filter: $Level" -ForegroundColor Yellow
    Write-Host "Component Filter: $Component" -ForegroundColor Yellow
    Write-Host ""
    
    if ($Structured) {
        # Read and parse structured JSON logs
        $logEntries = Get-Content $logPath | ConvertFrom-Json
        
        # Apply filters
        if ($Level -ne "INFO") {
            $logEntries = $logEntries | Where-Object { $_.level -eq $Level.ToUpper() }
        }
        
        if ($Component -ne "observability") {
            $logEntries = $logEntries | Where-Object { $_.component -eq $Component.ToLower() }
        }
        
        # Sort by timestamp descending
        $logEntries = $logEntries | Sort-Object timestamp -Descending | Select-Object -First $Count
        
        foreach ($entry in $logEntries) {
            $color = switch ($entry.level) {
                "ERROR" { "Red" }
                "WARN" { "Yellow" }
                "INFO" { "Green" }
                "DEBUG" { "Gray" }
                Default { "White" }
            }
            
            Write-Host "[$($entry.timestamp)] [$($entry.level)] [$($entry.component)] $($entry.message)" -ForegroundColor $color
            Write-Host "  Host: $($entry.host) | PID: $($entry.process_id) | Thread: $($entry.thread_id)" -ForegroundColor DarkGray
            Write-Host ""
        }
        
    } else {
        # Read traditional text logs
        $logEntries = Get-Content $logPath
        
        # Apply filters
        if ($Level -ne "INFO") {
            $logEntries = $logEntries | Where-Object { $_ -match "\[$Level\]" }
        }
        
        if ($Component -ne "observability") {
            $logEntries = $logEntries | Where-Object { $_ -match "\[$Component\]" }
        }
        
        # Show last N entries
        $logEntries = $logEntries | Select-Object -Last $Count
        
        foreach ($entry in $logEntries) {
            $color = if ($entry -match "\[ERROR\]") { "Red" }
            elseif ($entry -match "\[WARN\]") { "Yellow" }
            elseif ($entry -match "\[INFO\]") { "Green" }
            else { "White" }
            
            Write-Host $entry -ForegroundColor $color
        }
    }
    
    if ($Follow) {
        Write-Host "Following log file. Press Ctrl+C to stop..." -ForegroundColor DarkGray
        
        $lastPosition = 0
        while ($true) {
            $currentContent = Get-Content $logPath
            $newEntries = $currentContent | Select-Object -Skip $lastPosition
            
            foreach ($entry in $newEntries) {
                if ($Structured) {
                    try {
                        $logEntry = $entry | ConvertFrom-Json
                        $color = switch ($logEntry.level) {
                            "ERROR" { "Red" }
                            "WARN" { "Yellow" }
                            "INFO" { "Green" }
                            "DEBUG" { "Gray" }
                            Default { "White" }
                        }
                        Write-Host "[$($logEntry.timestamp)] [$($logEntry.level)] [$($logEntry.component)] $($logEntry.message)" -ForegroundColor $color
                    } catch {
                        Write-Host $entry -ForegroundColor White
                    }
                } else {
                    $color = if ($entry -match "\[ERROR\]") { "Red" }
                    elseif ($entry -match "\[WARN\]") { "Yellow" }
                    elseif ($entry -match "\[INFO\]") { "Green" }
                    else { "White" }
                    
                    Write-Host $entry -ForegroundColor $color
                }
            }
            
            $lastPosition = $currentContent.Count
            Start-Sleep 1
        }
    }
}

function Rotate-Logs {
    param()
    
    $logDir = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../logs"
    $logFiles = Get-ChildItem $logDir -Filter "observability_*.log"
    
    Write-Host "Rotating logs..." -ForegroundColor Cyan
    
    foreach ($logFile in $logFiles) {
        $archiveName = $logFile.BaseName -replace "observability_", "observability_archive_"
        $archivePath = Join-Path $logDir "$archiveName.log"
        
        Rename-Item -Path $logFile.FullName -NewName $archivePath
        Write-Host "  Rotated: $($logFile.Name) → $archiveName.log" -ForegroundColor Yellow
    }
    
    Write-Host "Log rotation completed" -ForegroundColor Green
}

function Clear-Logs {
    param()
    
    $logDir = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../logs"
    $logFiles = Get-ChildItem $logDir -Filter "*.log"
    
    Write-Host "Clearing logs..." -ForegroundColor Cyan
    
    foreach ($logFile in $logFiles) {
        Remove-Item $logFile.FullName -Force
        Write-Host "  Removed: $($logFile.Name)" -ForegroundColor Yellow
    }
    
    Write-Host "All logs cleared" -ForegroundColor Green
}

switch ($args[0]) {
    "rotate" {
        Rotate-Logs
    }
    "clear" {
        Clear-Logs
    }
    default {
        Get-Logs -Level $Level -Component $Component -Count $Count -Follow:$Follow -Structured:$Structured -Verbose:$Verbose
    }
}

# Export functions for module use
Export-ModuleMember -Function *-*