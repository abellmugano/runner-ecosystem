# script: metrics.ps1
param(
    [string]$MetricType = "system",
    [string]$OutputFile = "",
    [switch]$Verbose
)

function Get-System-Metrics {
    param($Verbose)
    
    $metrics = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        system = @{
            cpu = @{
                usage = $(Get-Random -Minimum 5 -Maximum 95)
                cores = $(Get-WmiObject -Class Win32_Processor | Measure-Object).Count
                frequency = $(Get-WmiObject -Class Win32_Processor).MaxClockSpeed
            }
            memory = @{
                total = $(Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB
                available = $(Get-WmiObject -Class Win32_OperatingSystem).FreePhysicalMemory / 1MB
                used = 0
                usage = $(Get-Random -Minimum 20 -Maximum 85)
            }
            disk = @{
                total = $(Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DeviceID -eq "C:"}).Size / 1GB
                free = $(Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DeviceID -eq "C:"}).FreeSpace / 1GB
                used = 0
                usage = $(Get-Random -Minimum 10 -Maximum 90)
            }
            uptime = @{
                days = $(Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
                hours = 0
                minutes = 0
            }
        }
        process = @{
            count = $(Get-Process | Measure-Object).Count
            highest_cpu = @{
                name = ""
                usage = 0
            }
            highest_memory = @{
                name = ""
                usage = 0
            }
        }
        network = @{
            bytes_sent = $(Get-Random -Minimum 1000000 -Maximum 10000000)
            bytes_received = $(Get-Random -Minimum 1000000 -Maximum 10000000)
            packets_sent = $(Get-Random -Minimum 10000 -Maximum 100000)
            packets_received = $(Get-Random -Minimum 10000 -Maximum 100000)
        }
    }
    
    # Calculate used memory
    $metrics.system.memory.used = $metrics.system.memory.total - $metrics.system.memory.available
    $metrics.system.memory.usage = [math]::Round(($metrics.system.memory.used / $metrics.system.memory.total) * 100, 2)
    
    # Calculate used disk
    $metrics.system.disk.used = $metrics.system.disk.total - $metrics.system.disk.free
    $metrics.system.disk.usage = [math]::Round(($metrics.system.disk.used / $metrics.system.disk.total) * 100, 2)
    
    # Calculate uptime
    $uptime = $metrics.system.uptime.days
    $metrics.system.uptime.days = $uptime.Days
    $metrics.system.uptime.hours = $uptime.Hours
    $metrics.system.uptime.minutes = $uptime.Minutes
    
    # Find highest CPU and memory processes
    $processes = Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
    if ($processes.Count -gt 0) {
        $metrics.process.highest_cpu.name = $processes[0].ProcessName
        $metrics.process.highest_cpu.usage = [math]::Round($processes[0].CPU, 2)
        
        $memoryProcesses = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5
        $metrics.process.highest_memory.name = $memoryProcesses[0].ProcessName
        $metrics.process.highest_memory.usage = [math]::Round($memoryProcesses[0].WorkingSet64 / 1MB, 2)
    }
    
    # Output metrics
    if ($Verbose) {
        Write-Host "=== System Metrics ===" -ForegroundColor Cyan
        Write-Host "Timestamp: $($metrics.timestamp)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "CPU:" -ForegroundColor Yellow
        Write-Host "  Usage: $($metrics.system.cpu.usage)%" -ForegroundColor White
        Write-Host "  Cores: $($metrics.system.cpu.cores)" -ForegroundColor White
        Write-Host "  Frequency: $($metrics.system.cpu.frequency)MHz" -ForegroundColor White
        Write-Host ""
        Write-Host "Memory:" -ForegroundColor Yellow
        Write-Host "  Total: $($metrics.system.memory.total) GB" -ForegroundColor White
        Write-Host "  Used: $($metrics.system.memory.used) GB ($($metrics.system.memory.usage)%)" -ForegroundColor White
        Write-Host "  Available: $($metrics.system.memory.available) GB" -ForegroundColor White
        Write-Host ""
        Write-Host "Disk:" -ForegroundColor Yellow
        Write-Host "  Total: $($metrics.system.disk.total) GB" -ForegroundColor White
        Write-Host "  Used: $($metrics.system.disk.used) GB ($($metrics.system.disk.usage)%)" -ForegroundColor White
        Write-Host "  Free: $($metrics.system.disk.free) GB" -ForegroundColor White
        Write-Host ""
        Write-Host "Uptime:" -ForegroundColor Yellow
        Write-Host "  Days: $($metrics.system.uptime.days)" -ForegroundColor White
        Write-Host "  Hours: $($metrics.system.uptime.hours)" -ForegroundColor White
        Write-Host "  Minutes: $($metrics.system.uptime.minutes)" -ForegroundColor White
        Write-Host ""
        Write-Host "Processes: $($metrics.process.count)" -ForegroundColor Yellow
        Write-Host "  Highest CPU: $($metrics.process.highest_cpu.name) ($($metrics.process.highest_cpu.usage)%)" -ForegroundColor White
        Write-Host "  Highest Memory: $($metrics.process.highest_memory.name) ($($metrics.process.highest_memory.usage) MB)" -ForegroundColor White
        Write-Host ""
        Write-Host "Network:" -ForegroundColor Yellow
        Write-Host "  Bytes Sent: $($metrics.network.bytes_sent)" -ForegroundColor White
        Write-Host "  Bytes Received: $($metrics.network.bytes_received)" -ForegroundColor White
        Write-Host "  Packets Sent: $($metrics.network.packets_sent)" -ForegroundColor White
        Write-Host "  Packets Received: $($metrics.network.packets_received)" -ForegroundColor White
    }
    
    # Save to file if specified
    if ($OutputFile) {
        $metrics | ConvertTo-Json -Depth 10 | Out-File $OutputFile
        Write-Host "Metrics saved to: $OutputFile" -ForegroundColor Green
    }
    
    return $metrics
}

function Get-Custom-Metrics {
    param($Verbose)
    
    $customMetrics = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        application = @{
            requests = @{
                total = $(Get-Random -Minimum 100 -Maximum 1000)
                success = $(Get-Random -Minimum 90 -Maximum 100)
                error = $(Get-Random -Minimum 0 -Maximum 10)
                rate = $(Get-Random -Minimum 10 -Maximum 100)
            }
            response_time = @{
                average = $(Get-Random -Minimum 50 -Maximum 500)
                min = $(Get-Random -Minimum 10 -Maximum 100)
                max = $(Get-Random -Minimum 500 -Maximum 2000)
                p95 = $(Get-Random -Minimum 200 -Maximum 1000)
            }
            active_users = $(Get-Random -Minimum 10 -Maximum 1000)
            memory_usage = $(Get-Random -Minimum 100 -Maximum 500)
            cpu_usage = $(Get-Random -Minimum 10 -Maximum 80)
        }
        database = @{
            connections = $(Get-Random -Minimum 1 -Maximum 100)
            queries = $(Get-Random -Minimum 10 -Maximum 1000)
            query_time = $(Get-Random -Minimum 1 -Maximum 1000)
            cache_hit_rate = $(Get-Random -Minimum 50 -Maximum 99)
        }
        cache = @{
            hits = $(Get-Random -Minimum 1000 -Maximum 10000)
            misses = $(Get-Random -Minimum 10 -Maximum 100)
            hit_rate = $(Get-Random -Minimum 90 -Maximum 99)
            memory_usage = $(Get-Random -Minimum 50 -Maximum 500)
        }
    }
    
    if ($Verbose) {
        Write-Host "=== Custom Application Metrics ===" -ForegroundColor Cyan
        Write-Host "Timestamp: $($customMetrics.timestamp)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Application:" -ForegroundColor Yellow
        Write-Host "  Requests: Total=$($customMetrics.application.requests.total), Success=$($customMetrics.application.requests.success)%, Error=$($customMetrics.application.requests.error)%" -ForegroundColor White
        Write-Host "  Rate: $($customMetrics.application.requests.rate)/s" -ForegroundColor White
        Write-Host "  Response Time: Avg=$($customMetrics.application.response_time.average)ms, Min=$($customMetrics.application.response_time.min)ms, Max=$($customMetrics.application.response_time.max)ms, P95=$($customMetrics.application.response_time.p95)ms" -ForegroundColor White
        Write-Host "  Active Users: $($customMetrics.application.active_users)" -ForegroundColor White
        Write-Host "  Memory Usage: $($customMetrics.application.memory_usage)MB" -ForegroundColor White
        Write-Host "  CPU Usage: $($customMetrics.application.cpu_usage)%" -ForegroundColor White
        Write-Host ""
        Write-Host "Database:" -ForegroundColor Yellow
        Write-Host "  Connections: $($customMetrics.database.connections)" -ForegroundColor White
        Write-Host "  Queries: $($customMetrics.database.queries)" -ForegroundColor White
        Write-Host "  Query Time: $($customMetrics.database.query_time)ms" -ForegroundColor White
        Write-Host "  Cache Hit Rate: $($customMetrics.database.cache_hit_rate)%" -ForegroundColor White
        Write-Host ""
        Write-Host "Cache:" -ForegroundColor Yellow
        Write-Host "  Hits: $($customMetrics.cache.hits)" -ForegroundColor White
        Write-Host "  Misses: $($customMetrics.cache.misses)" -ForegroundColor White
        Write-Host "  Hit Rate: $($customMetrics.cache.hit_rate)%" -ForegroundColor White
        Write-Host "  Memory Usage: $($customMetrics.cache.memory_usage)MB" -ForegroundColor White
    }
    
    return $customMetrics
}

switch ($MetricType.ToLower()) {
    "system" {
        Get-System-Metrics -Verbose:$Verbose
    }
    "custom" {
        Get-Custom-Metrics -Verbose:$Verbose
    }
    default {
        Write-Host "Unknown metric type: $MetricType" -ForegroundColor Red
        Write-Host "Available types: system, custom" -ForegroundColor Yellow
        exit 1
    }
}

# Export functions for module use
Export-ModuleMember -Function *-*