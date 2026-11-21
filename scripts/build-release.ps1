param(
  [ValidateSet("prod")]
  [string]$Environment = "prod",
  [switch]$SkipDependencyFetch
)

$ErrorActionPreference = "Stop"
$platform = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\platform")).Path
$previousMixEnv = $env:MIX_ENV
$env:MIX_ENV = $Environment

Push-Location $platform
try {
  if (-not $SkipDependencyFetch) {
    mix deps.get --only $Environment
    if ($LASTEXITCODE -ne 0) { throw "Dependency fetch failed." }
  }

  mix assets.setup
  if ($LASTEXITCODE -ne 0) { throw "Asset setup failed." }

  mix assets.deploy
  if ($LASTEXITCODE -ne 0) { throw "Asset build failed." }

  mix release contexla --overwrite
  if ($LASTEXITCODE -ne 0) { throw "Release build failed." }

  $releasePath = Join-Path $platform "_build\$Environment\rel\contexla"
  Write-Host "Built Contexla release at $releasePath"
} finally {
  Pop-Location

  if ($null -eq $previousMixEnv) {
    Remove-Item Env:MIX_ENV -ErrorAction SilentlyContinue
  } else {
    $env:MIX_ENV = $previousMixEnv
  }
}
