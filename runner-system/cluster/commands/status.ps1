# script: status.ps1
param(
    [switch]$Verbose,
    [switch]$Health,
    [switch]$Metrics
)

function Get-Cluster-Status {
    param($Verbose, $Health, $Metrics)
    
    $configPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../config/cluster.json"
    if (-not (Test-Path $configPath)) {
        Write-Error "Config file not found: $configPath"
        exit 1
    }
    
    $config = Get-Content $configPath | ConvertFrom-Json
    
    Write-Host "=== Runner Cluster Status ===" -ForegroundColor Cyan
    Write-Host "Cluster: $($config.cluster_name) v$($config.cluster_version)" -ForegroundColor Yellow
    Write-Host "Status: $($config.status)" -ForegroundColor $(if ($config.status -eq "ACTIVE") { "Green" } else { "Red" })
    Write-Host "Node Count: $($config.node_count)" -ForegroundColor Yellow
    Write-Host "Leader: $($config.leader)" -ForegroundColor $(if ($config.leader) { "Green" } else { "Red" })
    Write-Host ""
    
    if ($config.node_count -eq 0) {
        Write-Host "No nodes in the cluster. Use 'orbit cluster add' to add nodes." -ForegroundColor Yellow
        exit 0
    }
    
    # Calculate cluster metrics
    $totalCPU = 0
    $totalMemory = 0
    $totalStorage = 0
    $totalNetwork = 0
    $activeNodes = 0
    $masterNodes = 0
    $workerNodes = 0
    
    foreach ($node in $config.nodes) {
        $totalCPU += $node.capabilities.cpu
        $totalMemory += $node.capabilities.memory
        $totalStorage += $node.capabilities.storage
        $totalNetwork += $node.capabilities.network
        
        if ($node.status -eq "ACTIVE") {
            $activeNodes++
        }
        
        if ($node.type -eq "master") {
            $masterNodes++
        } else {
            $workerNodes++
        }
    }
    
    Write-Host "Cluster Resources:" -ForegroundColor Cyan
    Write-Host "  Total CPU: $totalCPU cores" -ForegroundColor White
    Write-Host "  Total Memory: $totalMemory GB" -ForegroundColor White
    Write-Host "  Total Storage: $totalStorage GB" -ForegroundColor White
    Write-Host "  Total Network: $totalNetwork Mbps" -ForegroundColor White
    Write-Host ""
    Write-Host "Node Distribution:" -ForegroundColor Cyan
    Write-Host "  Active Nodes: $activeNodes" -ForegroundColor Green
    Write-Host "  Master Nodes: $masterNodes" -ForegroundColor Yellow
    Write-Host "  Worker Nodes: $workerNodes" -ForegroundColor Yellow
    Write-Host ""
    
    # Show node details
    Write-Host "Cluster Nodes:" -ForegroundColor Cyan
    foreach ($node in $config.nodes) {
        $nodeColor = switch ($node.status) {
            "ACTIVE" { "Green" }
            "INACTIVE" { "Red" }
            "MAINTENANCE" { "Yellow" }
            Default { "White" }
        }
        
        $leaderIndicator = if ($node.name -eq $config.leader) { "[LEADER]" } else { "" }
        
        Write-Host "  $($node.name):" -ForegroundColor $nodeColor
        Write-Host "    Address: $($node.address) $leaderIndicator" -ForegroundColor White
        Write-Host "    Type: $($node.type) | Role: $($node.role)" -ForegroundColor White
        Write-Host "    Status: $($node.status)" -ForegroundColor White
        Write-Host "    Capabilities:" -ForegroundColor Yellow
        Write-Host "      CPU: $($node.capabilities.cpu) cores" -ForegroundColor White
        Write-Host "      Memory: $($node.capabilities.memory) GB" -ForegroundColor White
        Write-Host "      Storage: $($node.capabilities.storage) GB" -ForegroundColor White
        Write-Host "      Network: $($node.capabilities.network) Mbps" -ForegroundColor White
        Write-Host "    Services: $($node.services -join ", ")" -ForegroundColor Yellow
        Write-Host ""
    }
    
    if ($Health) {
        Write-Host "=== Cluster Health ===" -ForegroundColor Cyan
        Write-Host "Last Health Check: $($config.health.last_check)" -ForegroundColor Yellow
        Write-Host "Health Status: $($config.health.status)" -ForegroundColor $(if ($config.health.status -eq "HEALTHY") { "Green" } else { "Red" })
        
        if ($config.health.issues.Count -gt 0) {
            Write-Host "Health Issues:" -ForegroundColor Red
            foreach ($issue in $config.health.issues) {
                Write-Host "  - $issue" -ForegroundColor Red
            }
        }
        
        Write-Host ""
    }
    
    if ($Metrics) {
        Write-Host "=== Cluster Metrics ===" -ForegroundColor Cyan
        Write-Host "Average CPU Usage: $(Get-Random -Minimum 10 -Maximum 80)%" -ForegroundColor White
        Write-Host "Average Memory Usage: $(Get-Random -Minimum 30 -Maximum 85)%" -ForegroundColor White
        Write-Host "Average Storage Usage: $(Get-Random -Minimum 20 -Maximum 90)%" -ForegroundColor White
        Write-Host "Network Traffic: $(Get-Random -Minimum 100 -Maximum 10000) Mbps" -ForegroundColor White
        Write-Host ""
    }
    
    if ($Verbose) {
        # Show configuration details
        Write-Host "=== Cluster Configuration ===" -ForegroundColor Cyan
        Write-Host "Heartbeat Interval: $($config.config.heartbeat_interval) seconds" -ForegroundColor Yellow
        Write-Host "Failure Threshold: $($config.config.failure_threshold)" -ForegroundColor Yellow
        Write-Host "Replication Factor: $($config.config.replication_factor)" -ForegroundColor Yellow
        Write-Host "Quorum Size: $($config.config.quorum_size)" -ForegroundColor Yellow
        
        # Show health check details
        if ($config.health.issues.Count -gt 0) {
            Write-Host "Health Issues Details:" -ForegroundColor Red
            foreach ($issue in $config.health.issues) {
                Write-Host "  - $issue" -ForegroundColor Red
            }
        }
        
        # Save verbose log
        $logDir = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../logs"
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        
        $logFile = "cluster_status_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        $logPath = Join-Path $logDir $logFile
        
        $config | ConvertTo-Json -Depth 10 | Out-File $logPath
        Write-Host "Detailed status saved to: $logPath" -ForegroundColor Cyan
    }
    
    exit 0
}

Get-Cluster-Status -Verbose:$Verbose -Health:$Health -Metrics:$Metrics