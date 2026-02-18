# OpenCode PowerShell Skeleton

This repository contains a minimal PowerShell module scaffold to bootstrap PowerShell automation tasks.

What you'll find:
- A small module exposing HTTP GET helper, JSON writer, and file-summary utilities.
- A basic Pester test skeleton for the module.
- Documentation placeholder for usage and contribution.

Usage example:
- Import the module and call provided functions:
  - Import-Module ./src/OpenCode.Common.psd1
  - Get-ApiJson -Uri 'https://api.example.com/data'

Next steps:
- Flesh out tests, add CI workflow, and expand module surface.
