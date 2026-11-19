param(
  [string]$ApplicationPath = (Join-Path $PSScriptRoot "..\applications\digital_estate_assessment"),
  [string]$IntegrationPath = (Join-Path $PSScriptRoot "..\integrations\drupal")
)

$ErrorActionPreference = "Stop"

$application = (Resolve-Path -LiteralPath $ApplicationPath).Path
$integration = (Resolve-Path -LiteralPath $IntegrationPath).Path
$platform = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\platform")).Path

Push-Location $application
try {
  mix compile
  if ($LASTEXITCODE -ne 0) { throw "Application compilation failed." }
} finally {
  Pop-Location
}

Push-Location $integration
try {
  mix compile
  if ($LASTEXITCODE -ne 0) { throw "Integration compilation failed." }
} finally {
  Pop-Location
}

$applicationEbin = Join-Path $application "_build\dev\lib\contexla_estate\ebin"
$integrationEbin = Join-Path $integration "_build\dev\lib\contexla_drupal\ebin"

$env:CONTEXLA_APPLICATION_PACKAGES = "$applicationEbin|Contexla.Estate"
$env:CONTEXLA_INTEGRATION_PACKAGES = "$integrationEbin|Contexla.Drupal"

Push-Location $platform
try {
  mix phx.server
} finally {
  Pop-Location
}
