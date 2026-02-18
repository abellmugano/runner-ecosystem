Import-Module -Name ./src/OpenCode.Common.psm1 -Force -PassThru | Out-Null

Describe 'Get-ApiJson' {
  It 'returns data when API call succeeds' {
    Mock -CommandName Invoke-RestMethod -MockWith { return @{ status = 'ok' } }
    $result = Get-ApiJson -Uri 'https://example.invalid/health'
    $result | Should -BeOfType 'Object'
  }

  It 'throws when all retries fail' {
    Mock -CommandName Invoke-RestMethod -MockWith { throw 'NetworkError' }
    { Get-ApiJson -Uri 'https://example.invalid/health' -RetryCount 2 -DelaySeconds 0 } | Should -Throw
  }
}
