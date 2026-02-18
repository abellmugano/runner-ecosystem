# script: marketplace.ps1
param(
    [string]$Action = "list",
    [string]$Module = "",
    [string]$Version = "",
    [string]$Category = "",
    [string]$Tag = "",
    [string]$Author = "",
    [string]$Destination = ".",
    [switch]$Force,
    [switch]$Verbose,
    [switch]$Search,
    [switch]$Info,
    [switch]$Install,
    [switch]$Remove,
    [switch]$Update
)

function Get-Marketplace-Registry {
    param($Verbose)
    
    $registryPath = "$(Split-Path $script:MyInvocation.MyCommand.Path)/../registry/modules.json"
    
    if (-not (Test-Path $registryPath)) {
        Write-Error "Registry file not found: $registryPath" -ForegroundColor Red
        exit 1
    }
    
    try {
        $registry = Get-Content $registryPath | ConvertFrom-Json
        return $registry
    } catch {
        Write-Error "Failed to parse registry: $_" -ForegroundColor Red
        exit 1
    }
}

function Search-Modules {
    param($Query, $Category, $Tag, $Author, $Verbose)
    
    $registry = Get-Marketplace-Registry -Verbose:$Verbose
    
    Write-Host "=== Runner Marketplace Search ===" -ForegroundColor Cyan
    Write-Host "Query: $Query" -ForegroundColor Yellow
    Write-Host "Category: $Category" -ForegroundColor Yellow
    Write-Host "Tag: $Tag" -ForegroundColor Yellow
    Write-Host "Author: $Author" -ForegroundColor Yellow
    Write-Host ""
    
    $results = @()
    
    foreach ($module in $registry.modules) {
        $match = $false
        
        # Search by query
        if ($Query) {
            if ($module.name -like "*$Query*" -or $module.description -like "*$Query*" -or $module.author -like "*$Query*") {
                $match = $true
            }
        }
        
        # Filter by category
        if ($Category -and $module.category -ne $Category) {
            $match = $false
        }
        
        # Filter by tag
        if ($Tag -and $Tag -notin $module.tags) {
            $match = $false
        }
        
        # Filter by author
        if ($Author -and $module.author -ne $Author) {
            $match = $false
        }
        
        if ($match -or (-not $Query -and -not $Category -and -not $Tag -and -not $Author)) {
            $results += $module
        }
    }
    
    if ($results.Count -eq 0) {
        Write-Host "No modules found matching your criteria." -ForegroundColor Yellow
        Write-Host "Available categories: $(($registry.categories.GetEnumerator() | ForEach-Object { $_.Name }) -join ", ")" -ForegroundColor White
        exit 0
    }
    
    Write-Host "Found $($results.Count) modules:" -ForegroundColor Green
    Write-Host ""
    
    foreach ($module in $results) {
        $ratingColor = switch ($module.rating) {
            { $_ -ge 4.5 } { "Green" }
            { $_ -ge 4.0 } { "Yellow" }
            Default { "White" }
        }
        
        Write-Host "Module: $($module.name) v$($module.version)" -ForegroundColor Cyan
        Write-Host "  Description: $($module.description)" -ForegroundColor White
        Write-Host "  Author: $($module.author) | Category: $($module.category)" -ForegroundColor Yellow
        Write-Host "  Tags: $($module.tags -join ", ")" -ForegroundColor White
        Write-Host "  Rating: $($module.rating) ($($module.downloads) downloads)" -ForegroundColor $ratingColor
        Write-Host "  Size: $($module.size) | Last Updated: $($module.last_updated)" -ForegroundColor White
        Write-Host "  Requires: $($module.requires -join ", ")" -ForegroundColor Yellow
        Write-Host "  Provides: $($module.provides -join ", ")" -ForegroundColor White
        Write-Host "  Documentation: $($module.documentation)" -ForegroundColor Cyan
        Write-Host "  Source: $($module.source)" -ForegroundColor Cyan
        Write-Host ""
    }
    
    exit 0
}

function Show-Module-Info {
    param($ModuleName, $Version, $Verbose)
    
    $registry = Get-Marketplace-Registry -Verbose:$Verbose
    
    $module = $registry.modules | Where-Object { $_.name -eq $ModuleName }
    if (-not $module) {
        Write-Error "Module '$ModuleName' not found in registry." -ForegroundColor Red
        exit 1
    }
    
    if ($Version) {
        $module = $module | Where-Object { $_.version -eq $Version }
        if (-not $module) {
            Write-Error "Version $Version of module '$ModuleName' not found." -ForegroundColor Red
            exit 1
        }
    }
    
    Write-Host "=== Module Information ===" -ForegroundColor Cyan
    Write-Host "Module: $($module.name) v$($module.version)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Description:" -ForegroundColor Cyan
    Write-Host "  $($module.description)" -ForegroundColor White
    Write-Host ""
    Write-Host "Details:" -ForegroundColor Cyan
    Write-Host "  Author: $($module.author)" -ForegroundColor White
    Write-Host "  Category: $($module.category)" -ForegroundColor White
    Write-Host "  Tags: $($module.tags -join ", ")" -ForegroundColor White
    Write-Host "  Rating: $($module.rating) ($($module.downloads) downloads)" -ForegroundColor $(if ($module.rating -ge 4.5) { "Green" } else { "Yellow" })
    Write-Host "  Size: $($module.size) | Last Updated: $($module.last_updated)" -ForegroundColor White
    Write-Host "  License: $($module.license)" -ForegroundColor White
    Write-Host ""
    Write-Host "Requirements:" -ForegroundColor Cyan
    Write-Host "  Requires: $($module.requires -join ", ")" -ForegroundColor White
    Write-Host "  Provides: $($module.provides -join ", ")" -ForegroundColor White
    Write-Host ""
    Write-Host "Links:" -ForegroundColor Cyan
    Write-Host "  Documentation: $($module.documentation)" -ForegroundColor White
    Write-Host "  Source: $($module.source)" -ForegroundColor White
    Write-Host ""
    Write-Host "Dependencies:" -ForegroundColor Cyan
    foreach ($dep in $module.dependencies.GetEnumerator()) {
        Write-Host "  $($dep.Name): $($dep.Value)" -ForegroundColor White
    }
    
    exit 0
}

function Install-Module {
    param($ModuleName, $Version, $Destination, $Force, $Verbose)
    
    $registry = Get-Marketplace-Registry -Verbose:$Verbose
    
    $module = $registry.modules | Where-Object { $_.name -eq $ModuleName }
    if (-not $module) {
        Write-Error "Module '$ModuleName' not found in registry." -ForegroundColor Red
        exit 1
    }
    
    if ($Version) {
        $module = $module | Where-Object { $_.version -eq $Version }
        if (-not $module) {
            Write-Error "Version $Version of module '$ModuleName' not found." -ForegroundColor Red
            exit 1
        }
    }
    
    Write-Host "=== Installing Module ===" -ForegroundColor Cyan
    Write-Host "Module: $($module.name) v$($module.version)" -ForegroundColor Yellow
    Write-Host "Destination: $Destination" -ForegroundColor Yellow
    Write-Host ""
    
    # Validate destination
    if (-not (Test-Path $Destination)) {
        Write-Host "Creating destination directory: $Destination" -ForegroundColor Cyan
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }
    
    $modulePath = Join-Path $Destination $module.name
    if (Test-Path $modulePath) {
        if (-not $Force) {
            Write-Error "Module directory already exists: $modulePath" -ForegroundColor Red
            Write-Host "Use -Force to overwrite" -ForegroundColor Yellow
            exit 1
        } else {
            Write-Host "Overwriting existing module: $modulePath" -ForegroundColor Yellow
            Remove-Item $modulePath -Recurse -Force
        }
    }
    
    # Create module directory structure
    New-Item -ItemType Directory -Path $modulePath -Force | Out-Null
    
    # Create module files (simulated)
    foreach ($file in $module.files) {
        $filePath = Join-Path $modulePath $file
        $fileDir = Split-Path $filePath -Parent
        
        if (-not (Test-Path $fileDir)) {
            New-Item -ItemType Directory -Path $fileDir -Force | Out-Null
        }
        
        # Create placeholder file
        "# Module file: $file
# Version: $($module.version)
# Created: $(Get-Date -Format "yyyy-MM-dd")
# Author: $($module.author)

# This is a placeholder for the actual module file.
# The real module would contain PowerShell scripts, configurations, and other resources.

Write-Host 'Module '$($module.name)' v$($module.version) installed successfully!' -ForegroundColor Green
Write-Host 'Module path: $PSScriptRoot' -ForegroundColor Yellow
" | Out-File $filePath
        
        Write-Host "  Created: $filePath" -ForegroundColor Green
    }
    
    # Create module manifest
    $manifestContent = @{
        ModuleName = $module.name
        ModuleVersion = $module.version
        Description = $module.description
        Author = $module.author
        CompanyName = "Runner Marketplace"
        Copyright = "(c) $(Get-Date -Format "yyyy") Runner Marketplace. All rights reserved."
        GUID = [guid]::NewGuid().ToString()
        PowerShellVersion = "7.0"
        DotNetFrameworkVersion = "4.7.2"
        RequiredModules = @()
        FunctionsToExport = @("Install-$($module.name)", "Uninstall-$($module.name)", "Get-$($module.name)-Info")
        AliasesToExport = @()
        PrivateData = @{
            Tags = $module.tags
            License = $module.license
            ProjectUri = $module.source
            IconUri = ""
            ReleaseNotes = "Initial release"
        }
    }
    
    $manifestPath = Join-Path $modulePath "$($module.name).psd1"
    $manifestContent | ConvertTo-Json -Depth 10 | Out-File $manifestPath
    Write-Host "  Created: $manifestPath" -ForegroundColor Green
    
    # Create README
    $readmeContent = @"
# $($module.name)

## Description
$($module.description)

## Installation
```powershell
# Install via Runner Marketplace
orbit marketplace install $($module.name)

# Or manually
Import-Module '$($module.name)'
```

## Usage
```powershell
# Import the module
Import-Module '$($module.name)'

# Use module functions
Install-$($module.name)
Get-$($module.name)-Info
```

## Requirements
- PowerShell 7.0+
- Runner 1.0.0
- $($module.requires -join ", ")

## Version
v$($module.version)

## Author
$($module.author)

## License
$($module.license)

## Links
- [Documentation]($($module.documentation))
- [Source]($($module.source))

## Tags
$($module.tags -join ", ")

## Rating
$($module.rating) stars ($($module.downloads) downloads)

## Last Updated
$($module.last_updated)
"@
    
    $readmePath = Join-Path $modulePath "README.md"
    $readmeContent | Out-File $readmePath
    Write-Host "  Created: $readmePath" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Module installed successfully!" -ForegroundColor Green
    Write-Host "Path: $modulePath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To use the module:" -ForegroundColor Cyan
    Write-Host "  Import-Module '$modulePath'" -ForegroundColor White
    Write-Host "  Get-Command -Module $($module.name)" -ForegroundColor White
    
    # Save installation log
    $logDir = Join-Path $Destination "logs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    $logFile = "marketplace_install_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    $logPath = Join-Path $logDir $logFile
    
    $logEntry = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        action = "MODULE_INSTALL"
        module_name = $module.name
        module_version = $module.version
        destination = $modulePath
        status = "SUCCESS"
        files_created = $module.files.Count + 2
    }
    
    $logEntry | ConvertTo-Json | Out-File $logPath
    
    if ($Verbose) {
        Write-Host "Installation log saved to: $logPath" -ForegroundColor Cyan
    }
    
    exit 0
}

function Remove-Module {
    param($ModuleName, $Destination, $Force, $Verbose)
    
    $registry = Get-Marketplace-Registry -Verbose:$Verbose
    
    $module = $registry.modules | Where-Object { $_.name -eq $ModuleName }
    if (-not $module) {
        Write-Error "Module '$ModuleName' not found in registry." -ForegroundColor Red
        exit 1
    }
    
    $modulePath = Join-Path $Destination $module.name
    if (-not (Test-Path $modulePath)) {
        Write-Error "Module not found at: $modulePath" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "=== Removing Module ===" -ForegroundColor Cyan
    Write-Host "Module: $($module.name)" -ForegroundColor Yellow
    Write-Host "Path: $modulePath" -ForegroundColor Yellow
    Write-Host ""
    
    if (-not $Force) {
        $confirmation = Read-Host "Are you sure you want to remove this module? (y/n)"
        if ($confirmation -ne "y" -and $confirmation -ne "Y") {
            Write-Host "Module removal cancelled." -ForegroundColor Yellow
            exit 0
        }
    }
    
    # Remove module directory
    Remove-Item $modulePath -Recurse -Force
    Write-Host "Module removed successfully!" -ForegroundColor Green
    
    # Save removal log
    $logDir = Join-Path $Destination "logs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    $logFile = "marketplace_remove_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    $logPath = Join-Path $logDir $logFile
    
    $logEntry = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        action = "MODULE_REMOVE"
        module_name = $module.name
        module_version = $module.version
        path = $modulePath
        status = "SUCCESS"
    }
    
    $logEntry | ConvertTo-Json | Out-File $logPath
    
    if ($Verbose) {
        Write-Host "Removal log saved to: $logPath" -ForegroundColor Cyan
    }
    
    exit 0
}

function List-Categories {
    param($Verbose)
    
    $registry = Get-Marketplace-Registry -Verbose:$Verbose
    
    Write-Host "=== Marketplace Categories ===" -ForegroundColor Cyan
    foreach ($category in $registry.categories.GetEnumerator()) {
        Write-Host "  $($category.Name):" -ForegroundColor Green
        Write-Host "    Description: $($category.Value.description)" -ForegroundColor White
        Write-Host "    Modules: $($category.Value.modules -join ", ")" -ForegroundColor White
        Write-Host "    Count: $($category.Value.count)" -ForegroundColor Yellow
        Write-Host ""
    }
    
    exit 0
}

function Show-Registry-Info {
    param($Verbose)
    
    $registry = Get-Marketplace-Registry -Verbose:$Verbose
    
    Write-Host "=== Runner Marketplace Registry ===" -ForegroundColor Cyan
    Write-Host "Registry: $($registry.registry)" -ForegroundColor Yellow
    Write-Host "Version: $($registry.version)" -ForegroundColor White
    Write-Host "Last Updated: $($registry.last_updated)" -ForegroundColor White
    Write-Host ""
    Write-Host "Statistics:" -ForegroundColor Cyan
    Write-Host "  Total Modules: $($registry.modules.Count)" -ForegroundColor Green
    Write-Host "  Categories: $($registry.categories.Count)" -ForegroundColor Yellow
    Write-Host "  Featured Modules: $($registry.featured_modules.Count)" -ForegroundColor White
    Write-Host "  New Modules: $($registry.new_modules.Count)" -ForegroundColor White
    Write-Host "  Top Rated: $($registry.top_rated_modules.Count)" -ForegroundColor White
    Write-Host "  Most Downloaded: $($registry.most_downloaded_modules.Count)" -ForegroundColor White
    Write-Host ""
    Write-Host "Recent Updates:" -ForegroundColor Cyan
    foreach ($update in $registry.latest_updates) {
        Write-Host "  $($update.module) v$($update.version) - $($update.changes)" -ForegroundColor White
        Write-Host "    Date: $($update.date)" -ForegroundColor Yellow
    }
    
    exit 0
}

switch ($Action.ToLower()) {
    "search" {
        Search-Modules -Query $Module -Category $Category -Tag $Tag -Author $Author -Verbose:$Verbose
    }
    "info" {
        Show-Module-Info -ModuleName $Module -Version $Version -Verbose:$Verbose
    }
    "install" {
        Install-Module -ModuleName $Module -Version $Version -Destination $Destination -Force:$Force -Verbose:$Verbose
    }
    "remove" {
        Remove-Module -ModuleName $Module -Destination $Destination -Force:$Force -Verbose:$Verbose
    }
    "list" {
        List-Categories -Verbose:$Verbose
    }
    "registry" {
        Show-Registry-Info -Verbose:$Verbose
    }
    default {
        Write-Host "Usage: orbit marketplace {search|info|install|remove|list|registry} [options]" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor Cyan
        Write-Host "  search              Search modules (default)" -ForegroundColor White
        Write-Host "  info <module>       Show module information" -ForegroundColor White
        Write-Host "  install <module>   Install module" -ForegroundColor White
        Write-Host "  remove <module>    Remove module" -ForegroundColor White
        Write-Host "  list                List categories" -ForegroundColor White
        Write-Host "  registry            Show registry information" -ForegroundColor White
        Write-Host ""
        Write-Host "Search Options:" -ForegroundColor Cyan
        Write-Host "  -Query <term>       Search term" -ForegroundColor White
        Write-Host "  -Category <cat>    Filter by category" -ForegroundColor White
        Write-Host "  -Tag <tag>         Filter by tag" -ForegroundColor White
        Write-Host "  -Author <author>   Filter by author" -ForegroundColor White
        Write-Host ""
        Write-Host "Install Options:" -ForegroundColor Cyan
        Write-Host "  -Version <ver>     Specific version" -ForegroundColor White
        Write-Host "  -Destination <path> Installation path" -ForegroundColor White
        Write-Host "  -Force             Overwrite existing" -ForegroundColor White
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor Cyan
        Write-Host "  orbit marketplace search logging" -ForegroundColor White
        Write-Host "  orbit marketplace search -Category observability" -ForegroundColor White
        Write-Host "  orbit marketplace info logging-enhancer" -ForegroundColor White
        Write-Host "  orbit marketplace install logging-enhancer" -ForegroundColor White
        Write-Host "  orbit marketplace install gpu-monitor -Destination ./modules" -ForegroundColor White
        Write-Host "  orbit marketplace remove logging-enhancer" -ForegroundColor White
        Write-Host "  orbit marketplace list" -ForegroundColor White
        Write-Host "  orbit marketplace registry" -ForegroundColor White
        exit 1
    }
}

# Export functions for module use
Export-ModuleMember -Function *-*