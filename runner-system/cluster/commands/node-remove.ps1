# script: node-remove.ps1
param(
    [string]$NodeName,
    [string]$NodeAddress,
    [switch]$Force,
    [switch]$Verbose
)

function Remove-Cluster-Node {
    param($NodeName, $NodeAddress, $Force, $Verbose)
    
    $configPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../config/cluster.json"
    if (-not (Test-Path $configPath)) {
        Write-Error "Config file not found: $configPath"
        exit 1
    }
    
    $config = Get-Content $configPath | ConvertFrom-Json
    
    Write-Host "=== Runner Cluster - Remove Node ===" -ForegroundColor Cyan
    
    # Find node to remove
    $nodeToRemove = $null
    if ($NodeName) {
        $nodeToRemove = $config.nodes | Where-Object { $_.name -eq $NodeName }
    } elseif ($NodeAddress) {
        $nodeToRemove = $config.nodes | Where-Object { $_.address -eq $NodeAddress }
    }
    
    if (-not $nodeToRemove) {
        Write-Error "Node not found. Please specify NodeName or NodeAddress." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Node to remove:" -ForegroundColor Yellow
    Write-Host "  Name: $($nodeToRemove.name)" -ForegroundColor White
    Write-Host "  Address: $($nodeToRemove.address)" -ForegroundColor White
    Write-Host "  Type: $($nodeToRemove.type)" -ForegroundColor White
    Write-Host "  Status: $($nodeToRemove.status)" -ForegroundColor White
    Write-Host ""
    
    if (-not $Force) {
        $confirmation = Read-Host "Are you sure you want to remove this node? (y/n)"
        if ($confirmation -ne "y" -and $confirmation -ne "Y") {
            Write-Host "Node removal cancelled." -ForegroundColor Yellow
            exit 0
        }
    }
    
    # Check if removing leader
    if ($nodeToRemove.name -eq $config.leader) {
        Write-Host "Removing leader node. Cluster will need to elect new leader." -ForegroundColor Red
        
        # Find new leader
        $newLeader = $config.nodes | Where-Object { $_.name -ne $nodeToRemove.name -and $_.type -eq "master" } | Select-Object -First 1
        if (-not $newLeader) {
            $newLeader = $config.nodes | Where-Object { $_.name -ne $nodeToRemove.name } | Select-Object -First 1
        }
        
        if ($newLeader) {
            $config.leader = $newLeader.name
            Write-Host "New leader elected: $($newLeader.name)" -ForegroundColor Green
        } else {
            $config.leader = ""
            Write-Host "No new leader available. Cluster will be inactive." -ForegroundColor Red
        }
    }
    
    # Remove node
    $config.nodes = $config.nodes | Where-Object { $_.name -ne $nodeToRemove.name }
    $config.node_count = $config.nodes.Count
    
    # Update cluster status
    if ($config.node_count -eq 0) {
        $config.status = "INACTIVE"
        $config.leader = ""
    }
    
    # Save configuration
    $config | ConvertTo-Json -Depth 10 | Set-Content $configPath
    
    Write-Host ""
    Write-Host "Node removed successfully!" -ForegroundColor Green
    Write-Host "Cluster Status:" -ForegroundColor Yellow
    Write-Host "  Node Count: $($config.node_count)" -ForegroundColor White
    Write-Host "  Leader: $($config.leader)" -ForegroundColor White
    Write-Host "  Status: $($config.status)" -ForegroundColor White
    
    # Save removal log
    $logDir = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../logs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    $logFile = "node_remove_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    $logPath = Join-Path $logDir $logFile
    
    $logEntry = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        action = "NODE_REMOVE"
        node_name = $nodeToRemove.name
        node_address = $nodeToRemove.address
        node_type = $nodeToRemove.type
        node_role = $nodeToRemove.role
        status = "SUCCESS"
        config_version = $config.cluster_version
    }
    
    $logEntry | ConvertTo-Json | Out-File $logPath
    
    if ($Verbose) {
        Write-Host "Log saved to: $logPath" -ForegroundColor Cyan
    }
    
    exit 0
}

Remove-Cluster-Node -NodeName $NodeName -NodeAddress $NodeAddress -Force:$Force -Verbose:$Verbose