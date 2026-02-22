Describe "Security System" {
  It "Should return healthy on health check" {
    $r = & "$PSScriptRoot/../commands/audit.ps1" -Verbose
    $LASTEXITCODE | Should -Be 0
  }
}
