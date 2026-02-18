# script: audit.ps1
param(
    [string]$Target = "",
    [string]$Policy = "",
    [switch]$Full,
    [switch]$GenerateReport,
    [switch]$Verbose
)

function Get-File-Hash {
    param($FilePath)
    
    if (-not (Test-Path $FilePath)) {
        return @{
            path = $FilePath
            exists = $false
            hash = ""
            status = "MISSING"
        }
    }
    
    try {
        $hash = Get-FileHash $FilePath -Algorithm SHA256
        return @{
            path = $FilePath
            exists = $true
            hash = $hash.Hash
            status = "OK"
        }
    } catch {
        return @{
            path = $FilePath
            exists = $true
            hash = "ERROR"
            status = "ERROR"
        }
    }
}

function Get-Directory-Integrity {
    param($DirectoryPath)
    
    $result = @{
        path = $DirectoryPath
        exists = Test-Path $DirectoryPath
        files = 0
        directories = 0
        total_size = 0
        suspicious_files = @()
        status = "OK"
    }
    
    if (-not $result.exists) {
        $result.status = "MISSING"
        return $result
    }
    
    try {
        $items = Get-ChildItem $DirectoryPath -Recurse -Force -ErrorAction SilentlyContinue
        
        foreach ($item in $items) {
            if ($item.PSIsContainer) {
                $result.directories++
            } else {
                $result.files++
                $result.total_size += $item.Length
                
                # Check for suspicious file extensions
                $suspiciousExtensions = @(".exe", ".bat", ".cmd", ".ps1", ".vbs", ".js", ".jar", ".dll")
                if ($item.Extension -in $suspiciousExtensions -and $item.Name -notmatch "^\.(gitignore|dockerignore|editorconfig)$") {
                    $result.suspicious_files += @{
                        name = $item.Name
                        path = $item.FullName
                        size = $item.Length
                        extension = $item.Extension
                    }
                }
            }
        }
        
        # Check for too many files (potential malware)
        if ($result.files -gt 1000) {
            $result.status = "SUSPICIOUS"
        }
        
    } catch {
        $result.status = "ERROR"
        $result.error = $_
    }
    
    return $result
}

function Get-Permission-Settings {
    param($TargetPath)
    
    $acl = Get-Acl $TargetPath
    $accessRules = $acl.Access
    
    $permissions = @{
        path = $TargetPath
        owner = $acl.Owner
        group = $acl.Group
        access_rules = @()
        status = "OK"
    }
    
    foreach ($rule in $accessRules) {
        $permissions.access_rules += @{
            identity = $rule.IdentityReference
            filesystemrights = $rule.FileSystemRights
            accesscontroltype = $rule.AccessControlType
            isinherited = $rule.IsInherited
            inheritanceflags = $rule.InheritanceFlags
            propagationflags = $rule.PropagationFlags
        }
    }
    
    # Check for dangerous permissions
    $dangerousPermissions = $accessRules | Where-Object {
        ($_.FileSystemRights -match "FullControl" -or $_.FileSystemRights -match "Modify") -and
        ($_.AccessControlType -eq "Allow") -and
        ($_.IsInherited -eq $false)
    }
    
    if ($dangerousPermissions.Count -gt 0) {
        $permissions.status = "DANGEROUS"
        $permissions.dangerous_permissions = $dangerousPermissions
    }
    
    return $permissions
}

function Get-Registry-Security {
    param()
    
    $registryKeys = @(
        "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run",
        "HKEY_CURRENT_USER\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run",
        "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services"
    )
    
    $registryAudit = @()
    
    foreach ($key in $registryKeys) {
        try {
            $entries = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
            $registryAudit += @{
                key = $key
                entries = $entries.PSObject.Properties.Name
                count = $entries.PSObject.Properties.Count
                status = "OK"
            }
        } catch {
            $registryAudit += @{
                key = $key
                entries = @()
                count = 0
                status = "ERROR"
                error = $_
            }
        }
    }
    
    return $registryAudit
}

function Get-Process-Security {
    param()
    
    $processes = Get-Process | Select-Object -First 20
    $processAudit = @()
    
    foreach ($process in $processes) {
        try {
            $processInfo = Get-WmiObject -Class Win32_Process -Filter "ProcessId=$($process.Id)" -ErrorAction SilentlyContinue
            
            $processAudit += @{
                name = $process.ProcessName
                id = $process.Id
                path = if ($processInfo) { $processInfo.ExecutablePath } else { "N/A" }
                company = $process.Company
                description = $process.Description
                starttime = if ($processInfo) { $processInfo.CreationDate } else { "N/A" }
                status = "OK"
            }
        } catch {
            $processAudit += @{
                name = $process.ProcessName
                id = $process.Id
                path = "ERROR"
                company = $process.Company
                description = $process.Description
                starttime = "ERROR"
                status = "ERROR"
                error = $_
            }
        }
    }
    
    return $processAudit
}

function Get-Network-Security {
    param()
    
    $networkAudit = @{
        listening_ports = @()
        established_connections = @()
        suspicious_connections = @()
        status = "OK"
    }
    
    # Get listening ports
    $listening = netstat -ano | Select-String "LISTENING"
    foreach ($line in $listening) {
        $parts = $line.Line.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)
        if ($parts.Count -ge 4) {
            $networkAudit.listening_ports += @{
                protocol = $parts[0]
                local_address = $parts[1]
                foreign_address = $parts[2]
                state = "LISTENING"
                pid = $parts[3]
            }
        }
    }
    
    # Get established connections
    $established = netstat -ano | Select-String "ESTABLISHED"
    foreach ($line in $established) {
        $parts = $line.Line.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)
        if ($parts.Count -ge 4) {
            $networkAudit.established_connections += @{
                protocol = $parts[0]
                local_address = $parts[1]
                foreign_address = $parts[2]
                state = "ESTABLISHED"
                pid = $parts[3]
            }
        }
    }
    
    # Check for suspicious connections
    $suspiciousDomains = @("\.onion", "\.top", "\.xyz", "\.tk", "\.ml")
    foreach ($connection in $networkAudit.established_connections) {
        foreach ($domain in $suspiciousDomains) {
            if ($connection.foreign_address -like "*$domain") {
                $networkAudit.suspicious_connections += $connection
                $networkAudit.status = "SUSPICIOUS"
            }
        }
    }
    
    return $networkAudit
}

function Generate-Security-Report {
    param($auditResults, $Target, $Policy, $Full, $GenerateReport)
    
    $report = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        target = $Target
        policy = $Policy
        full_audit = $Full
        overall_status = "SECURE"
        sections = @()
    }
    
    # Add each audit section
    foreach ($section in $auditResults.Keys) {
        $report.sections += @{
            name = $section
            data = $auditResults[$section]
            status = if ($auditResults[$section].status) { $auditResults[$section].status } else { "OK" }
        }
        
        # Update overall status
        if ($report.sections[-1].status -eq "UNHEALTHY" -or $report.sections[-1].status -eq "SUSPICIOUS" -or $report.sections[-1].status -eq "DANGEROUS") {
            $report.overall_status = $report.sections[-1].status
        }
    }
    
    if ($GenerateReport) {
        $reportDir = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../reports"
        if (-not (Test-Path $reportDir)) {
            New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
        }
        
        $reportFile = "security_audit_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $reportPath = Join-Path $reportDir $reportFile
        
        $report | ConvertTo-Json -Depth 10 | Out-File $reportPath
        Write-Host "Security report generated: $reportPath" -ForegroundColor Green
    }
    
    return $report
}

# Main execution
Write-Host "=== Runner Security Audit ===" -ForegroundColor Cyan
Write-Host "Target: $Target" -ForegroundColor Yellow
Write-Host "Full Audit: $Full" -ForegroundColor Yellow
Write-Host ""

$auditResults = @{}

# Audit 1: File Integrity
Write-Host "1. Checking file integrity..." -ForegroundColor Yellow
$filesToAudit = @(
    "$(Split-Path $script:MyInvocation.MyCommand.Path)/../../supervisor/config/supervisor.json",
    "$(Split-Path $script:MyInvocation.MyCommand.Path)/../../build/config/build.json",
    "$(Split-Path $script:MyInvocation.MyCommand.Path)/../../observability/logs/logger.ps1",
    "$(Split-Path $script:MyInvocation.MyCommand.Path)/../../deploy/config/deploy.json"
)

$fileHashes = @()
foreach ($file in $filesToAudit) {
    $hashResult = Get-File-Hash -FilePath $file
    $fileHashes += $hashResult
    
    if ($hashResult.exists) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file (Missing)" -ForegroundColor Red
    }
}

$auditResults.file_integrity = @{
    files = $fileHashes
    total_files = $fileHashes.Count
    missing_files = ($fileHashes | Where-Object { -not $_.exists }).Count
    status = if (($fileHashes | Where-Object { -not $_.exists }).Count -eq 0) { "OK" } else { "UNHEALTHY" }
}

Write-Host ""

# Audit 2: Directory Structure
Write-Host "2. Checking directory structure..." -ForegroundColor Yellow
$directoriesToAudit = @(
    "$(Split-Path $script:MyInvocation.MyCommand.Path)/../../",
    "$(Split-Path $script:MyInvocation.MyCommand.Path)/../../supervisor",
    "$(Split-Path $script:MyInvocation.MyCommand.Path)/../../build",
    "$(Split-Path $script:MyInvocation.MyCommand.Path)/../../observability",
    "$(Split-Path $script:MyInvocation.MyCommand.Path)/../../deploy",
    "$(Split-Path $script:MyInvocation.MyCommand.Path)/../../security"
)

$directoryIntegrity = @()
foreach ($directory in $directoriesToAudit) {
    $integrity = Get-Directory-Integrity -DirectoryPath $directory
    $directoryIntegrity += $integrity
    
    Write-Host "  ✓ $directory" -ForegroundColor Green
    Write-Host "    Files: $($integrity.files) | Directories: $($integrity.directories) | Size: $(( $integrity.total_size / 1MB ).ToString('2.2')) MB" -ForegroundColor Yellow
    
    if ($integrity.suspicious_files.Count -gt 0) {
        Write-Host "    Suspicious files found: $($integrity.suspicious_files.Count)" -ForegroundColor Red
        foreach ($suspicious in $integrity.suspicious_files) {
            Write-Host "      - $($suspicious.name) ($($suspicious.extension))" -ForegroundColor Red
        }
    }
}

$auditResults.directory_structure = @{
    directories = $directoryIntegrity
    total_directories = $directoryIntegrity.Count
    suspicious_directories = ($directoryIntegrity | Where-Object { $_.status -eq "SUSPICIOUS" }).Count
    status = if (($directoryIntegrity | Where-Object { $_.status -ne "OK" }).Count -eq 0) { "OK" } else { "UNHEALTHY" }
}

Write-Host ""

# Audit 3: Permission Settings
if ($Full) {
    Write-Host "3. Checking permission settings..." -ForegroundColor Yellow
    $permissionAudit = @()
    
    foreach ($directory in $directoriesToAudit) {
        $permissions = Get-Permission-Settings -TargetPath $directory
        $permissionAudit += $permissions
        
        Write-Host "  ✓ $directory" -ForegroundColor Green
        Write-Host "    Owner: $($permissions.owner)" -ForegroundColor Yellow
        Write-Host "    Status: $($permissions.status)" -ForegroundColor $(if ($permissions.status -eq "OK") { "Green" } else { "Red" })
        
        if ($permissions.dangerous_permissions) {
            Write-Host "    Dangerous permissions found:" -ForegroundColor Red
            foreach ($rule in $permissions.dangerous_permissions) {
                Write-Host "      - $($rule.identity): $($rule.filesystemrights)" -ForegroundColor Red
            }
        }
    }
    
    $auditResults.permission_settings = @{
        directories = $permissionAudit
        dangerous_permissions = ($permissionAudit | Where-Object { $_.status -eq "DANGEROUS" }).Count
        status = if (($permissionAudit | Where-Object { $_.status -eq "DANGEROUS" }).Count -eq 0) { "OK" } else { "UNHEALTHY" }
    }
    
    Write-Host ""
}

# Audit 4: Registry Security
if ($Full) {
    Write-Host "4. Checking registry security..." -ForegroundColor Yellow
    $registryAudit = Get-Registry-Security
    
    Write-Host "  ✓ Registry keys checked" -ForegroundColor Green
    Write-Host "    Entries found: $($registryAudit[0].count + $registryAudit[1].count + $registryAudit[2].count)" -ForegroundColor Yellow
    
    $auditResults.registry_security = @{
        keys = $registryAudit
        total_entries = $registryAudit[0].count + $registryAudit[1].count + $registryAudit[2].count
        status = "OK"
    }
    
    Write-Host ""
}

# Audit 5: Process Security
if ($Full) {
    Write-Host "5. Checking process security..." -ForegroundColor Yellow
    $processAudit = Get-Process-Security
    
    Write-Host "  ✓ Processes checked" -ForegroundColor Green
    Write-Host "    Active processes: $($processAudit.Count)" -ForegroundColor Yellow
    
    $auditResults.process_security = @{
        processes = $processAudit
        total_processes = $processAudit.Count
        suspicious_processes = ($processAudit | Where-Object { $_.status -eq "ERROR" }).Count
        status = if (($processAudit | Where-Object { $_.status -eq "ERROR" }).Count -eq 0) { "OK" } else { "UNHEALTHY" }
    }
    
    Write-Host ""
}

# Audit 6: Network Security
if ($Full) {
    Write-Host "6. Checking network security..." -ForegroundColor Yellow
    $networkAudit = Get-Network-Security
    
    Write-Host "  ✓ Network connections checked" -ForegroundColor Green
    Write-Host "    Listening ports: $($networkAudit.listening_ports.Count)" -ForegroundColor Yellow
    Write-Host "    Established connections: $($networkAudit.established_connections.Count)" -ForegroundColor Yellow
    
    if ($networkAudit.suspicious_connections.Count -gt 0) {
        Write-Host "    Suspicious connections found: $($networkAudit.suspicious_connections.Count)" -ForegroundColor Red
        foreach ($connection in $networkAudit.suspicious_connections) {
            Write-Host "      - $($connection.foreign_address)" -ForegroundColor Red
        }
    }
    
    $auditResults.network_security = @{
        listening_ports = $networkAudit.listening_ports
        established_connections = $networkAudit.established_connections
        suspicious_connections = $networkAudit.suspicious_connections
        status = $networkAudit.status
    }
    
    Write-Host ""
}

# Generate final report
$finalReport = Generate-Security-Report -auditResults $auditResults -Target $Target -Policy $Policy -Full:$Full -GenerateReport:$GenerateReport

Write-Host ""
Write-Host "=== Audit Summary ===" -ForegroundColor Cyan
Write-Host "Overall Status: $($finalReport.overall_status)" -ForegroundColor $(if ($finalReport.overall_status -eq "SECURE") { "Green" } else { "Red" })
Write-Host "Total Checks: $($finalReport.sections.Count)" -ForegroundColor Yellow

foreach ($section in $finalReport.sections) {
    Write-Host "  $($section.name): $($section.status)" -ForegroundColor $(if ($section.status -eq "OK") { "Green" } else { "Red" })
}

Write-Host ""
Write-Host "Audit completed at $(Get-Date -Format "HH:mm:ss")" -ForegroundColor Cyan

exit $(if ($finalReport.overall_status -eq "SECURE") { 0 } else { 1 })

# Export functions for module use
Export-ModuleMember -Function *-*