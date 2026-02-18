# script: node-add.ps1
param(
    [string]$NodeName,
    [string]$NodeAddress,
    [string]$NodeType = "worker",
    [string]$NodeRole = "",
    [switch]$Force,
    [switch]$Verbose
)

function Add-Cluster-Node {
    param($NodeName, $NodeAddress, $NodeType, $NodeRole, $Force, $Verbose)
    
    $configPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../config/cluster.json"
    if (-not (Test-Path $configPath)) {
        Write-Error "Config file not found: $configPath"
        exit 1
    }
    
    $config = Get-Content $configPath | ConvertFrom-Json
    
    Write-Host "=== Runner Cluster - Add Node ===" -ForegroundColor Cyan
    Write-Host "Node Name: $NodeName" -ForegroundColor Yellow
    Write-Host "Node Address: $NodeAddress" -ForegroundColor Yellow
    Write-Host "Node Type: $NodeType" -ForegroundColor Yellow
    Write-Host "Node Role: $NodeRole" -ForegroundColor Yellow
    Write-Host ""
    
    # Validate node name
    if (-not $NodeName) {
        Write-Error "Node name is required" -ForegroundColor Red
        exit 1
    }
    
    if (-not $NodeAddress) {
        Write-Error "Node address is required" -ForegroundColor Red
        exit 1
    }
    
    # Check if node already exists
    $existingNode = $config.nodes | Where-Object { $_.name -eq $NodeName -or $_.address -eq $NodeAddress }
    if ($existingNode -and -not $Force) {
        Write-Host "Node already exists:" -ForegroundColor Yellow
        Write-Host "  Name: $($existingNode.name)" -ForegroundColor White
        Write-Host "  Address: $($existingNode.address)" -ForegroundColor White
        Write-Host "  Type: $($existingNode.type)" -ForegroundColor White
        Write-Host "  Status: $($existingNode.status)" -ForegroundColor White
        Write-Host "Use -Force to overwrite existing node" -ForegroundColor Yellow
        exit 1
    }
    
    # Create node object
    $newNode = @{
        name = $NodeName
        address = $NodeAddress
        type = $NodeType
        role = if ($NodeRole) { $NodeRole } else { if ($NodeType -eq "master") { "leader" } else { "worker" } }
        status = "ACTIVE"
        last_heartbeat = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        capabilities = @{
            cpu = $(Get-Random -Minimum 2 -Maximum 64)
            memory = $(Get-Random -Minimum 4 -Maximum 256)
            storage = $(Get-Random -Minimum 100 -Maximum 10000)
            network = $(Get-Random -Minimum 100 -Maximum 10000)
        }
        services = @()
        health = @{
            status = "HEALTHY"
            last_check = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            issues = @()
        }
    }
    
    # Simulate service discovery
    $services = @("supervisor", "build", "observability", "deploy", "security")
    $newNode.services = $services | Get-Random -Count $(Get-Random -Minimum 2 -Maximum ($services.Count))
    
    # Add or update node
    if ($existingNode) {
        Write-Host "Updating existing node: $NodeName" -ForegroundColor Cyan
        $index = $config.nodes.IndexOf($existingNode)
        $config.nodes[$index] = $newNode
    } else {
        Write-Host "Adding new node: $NodeName" -ForegroundColor Cyan
        $config.nodes += $newNode
    }
    
    # Update cluster status
    $config.node_count = $config.nodes.Count
    $config.status = "ACTIVE"
    
    # Set leader if this is master node or first node
    if ($NodeType -eq "master" -or $config.node_count -eq 1) {
        $config.leader = $NodeName
    }
    
    # Save configuration
    $config | ConvertTo-Json -Depth 10 | Set-Content $configPath
    
    Write-Host ""
    Write-Host "Node added successfully!" -ForegroundColor Green
    Write-Host "Cluster Status:" -ForegroundColor Yellow
    Write-Host "  Node Count: $($config.node_count)" -ForegroundColor White
    Write-Host "  Leader: $($config.leader)" -ForegroundColor White
    Write-Host "  Status: $($config.status)" -ForegroundColor White
    
    # Display node details
    Write-Host ""
    Write-Host "Node Details:" -ForegroundColor Cyan
    Write-Host "  Name: $($newNode.name)" -ForegroundColor White
    Write-Host "  Address: $($newNode.address)" -ForegroundColor White
    Write-Host "  Type: $($newNode.type)" -ForegroundColor White
    Write-Host "  Role: $($newNode.role)" -ForegroundColor White
    Write-Host "  Status: $($newNode.status)" -ForegroundColor White
    Write-Host "  Capabilities:" -ForegroundColor Yellow
    Write-Host "    CPU: $($newNode.capabilities.cpu) cores" -ForegroundColor White
    Write-Host "    Memory: $($newNode.capabilities.memory) GB" -ForegroundColor White
    Write-Host "    Storage: $($newNode.capabilities.storage) GB" -ForegroundColor White
    Write-Host "    Network: $($newNode.capabilities.network) Mbps" -ForegroundColor White
    Write-Host "  Services: $($newNode.services -join ", ")" -ForegroundColor Yellow
    
    # Save node addition log
    $logDir = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../logs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    $logFile = "node_add_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    $logPath = Join-Path $logDir $logFile
    
    $logEntry = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        action = "NODE_ADD"
        node_name = $NodeName
        node_address = $NodeAddress
        node_type = $NodeType
        node_role = $NodeRole
        status = "SUCCESS"
        config_version = $config.cluster_version
    }
    
    $logEntry | ConvertTo-Json | Out-File $logPath
    
    if ($Verbose) {
        Write-Host "Log saved to: $logPath" -ForegroundColor Cyan
    }
    
    exit 0
}

Add-Cluster-Node -NodeName $NodeName -NodeAddress $NodeAddress -NodeType $NodeType -NodeRole $NodeRole -Force:$Force -Verbose:$Verbose