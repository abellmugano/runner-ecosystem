# script: create.ps1
param(
    [string]$Type,
    [string]$Name,
    [string]$Destination = ".",
    [string]$Author = "",
    [switch]$Force,
    [switch]$Verbose
)

function Create-Project {
    param($Type, $Name, $Destination, $Author, $Force, $Verbose)
    
    Write-Host "=== Runner SDK - Project Creation ===" -ForegroundColor Cyan
    Write-Host "Type: $Type" -ForegroundColor Yellow
    Write-Host "Name: $Name" -ForegroundColor Yellow
    Write-Host "Destination: $Destination" -ForegroundColor Yellow
    Write-Host ""
    
    # Validate inputs
    if (-not $Type) {
        Write-Error "Project type is required" -ForegroundColor Red
        exit 1
    }
    
    if (-not $Name) {
        Write-Error "Project name is required" -ForegroundColor Red
        exit 1
    }
    
    # Check if destination exists
    if (-not (Test-Path $Destination)) {
        Write-Host "Creating destination directory: $Destination" -ForegroundColor Cyan
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }
    
    $projectPath = Join-Path $Destination $Name
    
    if (Test-Path $projectPath) {
        if (-not $Force) {
            Write-Error "Project directory already exists: $projectPath" -ForegroundColor Red
            Write-Host "Use -Force to overwrite" -ForegroundColor Yellow
            exit 1
        } else {
            Write-Host "Overwriting existing project: $projectPath" -ForegroundColor Yellow
            Remove-Item $projectPath -Recurse -Force
        }
    }
    
    # Create project directory
    New-Item -ItemType Directory -Path $projectPath -Force | Out-Null
    
    # Create project structure based on type
    switch ($Type.ToLower()) {
        "service" {
            Create-Service-Project -Name $Name -Path $projectPath -Author $Author -Verbose:$Verbose
        }
        "api" {
            Create-Api-Project -Name $Name -Path $projectPath -Author $Author -Verbose:$Verbose
        }
        "worker" {
            Create-Worker-Project -Name $Name -Path $projectPath -Author $Author -Verbose:$Verbose
        }
        "cli" {
            Create-Cli-Project -Name $Name -Path $projectPath -Author $Author -Verbose:$Verbose
        }
        "library" {
            Create-Library-Project -Name $Name -Path $projectPath -Author $Author -Verbose:$Verbose
        }
        default {
            Write-Error "Unknown project type: $Type" -ForegroundColor Red
            Write-Host "Available types: service, api, worker, cli, library" -ForegroundColor Yellow
            exit 1
        }
    }
    
    Write-Host ""
    Write-Host "Project created successfully!" -ForegroundColor Green
    Write-Host "Path: $projectPath" -ForegroundColor Yellow
    
    if ($Verbose) {
        Write-Host ""
        Write-Host "Project structure:" -ForegroundColor Cyan
        Get-ChildItem $projectPath -Recurse | ForEach-Object { Write-Host "  $($_.FullName)" -ForegroundColor White }
    }
    
    exit 0
}

function Create-Service-Project {
    param($Name, $Path, $Author, $Verbose)
    
    Write-Host "Creating service project: $Name" -ForegroundColor Cyan
    
    # Create directory structure
    $servicePath = Join-Path $Path $Name
    New-Item -ItemType Directory -Path $servicePath -Force | Out-Null
    
    $srcPath = Join-Path $servicePath "src"
    $testsPath = Join-Path $servicePath "tests"
    $logsPath = Join-Path $servicePath "logs"
    $configPath = Join-Path $servicePath "config"
    $docsPath = Join-Path $servicePath "docs"
    
    New-Item -ItemType Directory -Path $srcPath -Force | Out-Null
    New-Item -ItemType Directory -Path $testsPath -Force | Out-Null
    New-Item -ItemType Directory -Path $logsPath -Force | Out-Null
    New-Item -ItemType Directory -Path $configPath -Force | Out-Null
    New-Item -ItemType Directory -Path $docsPath -Force | Out-Null
    
    # Get current date
    $currentDate = Get-Date -Format "yyyy-MM-dd"
    if (-not $Author) {
        $Author = $env:USERNAME
    }
    
    # Create main service file from template
    $templatePath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../../templates/basic-service.ps1"
    if (Test-Path $templatePath) {
        $templateContent = Get-Content $templatePath -Raw
        
        # Replace placeholders
        $templateContent = $templateContent -replace "\{SERVICE_NAME\}", $Name
        $templateContent = $templateContent -replace "\{SERVICE_DESCRIPTION\}", "Basic service for $Name"
        $templateContent = $templateContent -replace "\{AUTHOR\}", $Author
        $templateContent = $templateContent -replace "\{DATE\}", $currentDate
        
        # Save service file
        $serviceFile = "$Name.ps1"
        $serviceFilePath = Join-Path $srcPath $serviceFile
        $templateContent | Out-File $serviceFilePath
        
        Write-Host "  Created: $serviceFilePath" -ForegroundColor Green
    }
    
    # Create configuration file
    $configContent = @{
        name = $Name
        version = "1.0.0"
        description = "Basic service for $Name"
        author = $Author
        created_date = $currentDate
        environment = "development"
        logging = @{
            level = "INFO"
            file = "$Name.log"
            max_size = "10MB"
            retention_days = 30
        }
        health_check = @{
            endpoint = "/health"
            interval = 30
            timeout = 5
        }
        metrics = @{
            enabled = $true
            interval = 60
            retention_days = 7
        }
    }
    
    $configFilePath = Join-Path $configPath "config.json"
    $configContent | ConvertTo-Json -Depth 10 | Out-File $configFilePath
    Write-Host "  Created: $configFilePath" -ForegroundColor Green
    
    # Create README
    $readmeContent = @"
# $Name

Basic service for the Runner Ecosystem.

## Description
$Name is a service that provides basic functionality for the Runner Ecosystem.

## Installation
```powershell
# Clone the repository
git clone https://github.com/your-org/$Name.git
cd $Name

# Install dependencies
# (Add your dependency installation commands here)
```

## Usage
```powershell
# Start the service
./src/$Name.ps1 start

# Check status
./src/$Name.ps1 status

# Get health
./src/$Name.ps1 health

# Get metrics
./src/$Name.ps1 metrics
```

## Configuration
Configuration is stored in `config/config.json`.

## Contributing
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License
MIT License

## Author
$Author
Created on: $currentDate
"@
    
    $readmeFilePath = Join-Path $servicePath "README.md"
    $readmeContent | Out-File $readmeFilePath
    Write-Host "  Created: $readmeFilePath" -ForegroundColor Green
    
    # Create .gitignore
    $gitignoreContent = @"
# Logs
logs/
*.log

# Dependencies
*.dll
*.exe
*.so
*.dylib

# Build outputs
build/
dist/
out/

# Environment variables
.env
.env.local
.env.*.local

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# OS files
.DS_Store
Thumbs.db

# Temporary files
temp/
tmp/

# Configuration files (user-specific)
config/config.user.json
config/*.local.json
"
    
    $gitignoreFilePath = Join-Path $servicePath ".gitignore"
    $gitignoreContent | Out-File $gitignoreFilePath
    Write-Host "  Created: $gitignoreFilePath" -ForegroundColor Green
    
    # Create example config
    $exampleConfigContent = @{
        name = "${Name}_example"
        version = "1.0.0"
        description = "Example configuration for $Name"
        settings = @{
            example_setting = "value"
            another_setting = 123
        }
    }
    
    $exampleConfigFilePath = Join-Path $configPath "config.example.json"
    $exampleConfigContent | ConvertTo-Json -Depth 10 | Out-File $exampleConfigFilePath
    Write-Host "  Created: $exampleConfigFilePath" -ForegroundColor Green
}

function Create-Api-Project {
    param($Name, $Path, $Author, $Verbose)
    
    Write-Host "Creating API project: $Name" -ForegroundColor Cyan
    # Implementation for API project
}

function Create-Worker-Project {
    param($Name, $Path, $Author, $Verbose)
    
    Write-Host "Creating worker project: $Name" -ForegroundColor Cyan
    # Implementation for worker project
}

function Create-Cli-Project {
    param($Name, $Path, $Author, $Verbose)
    
    Write-Host "Creating CLI project: $Name" -ForegroundColor Cyan
    # Implementation for CLI project
}

function Create-Library-Project {
    param($Name, $Path, $Author, $Verbose)
    
    Write-Host "Creating library project: $Name" -ForegroundColor Cyan
    # Implementation for library project
}

Create-Project -Type $Type -Name $Name -Destination $Destination -Author $Author -Force:$Force -Verbose:$Verbose