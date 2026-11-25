param(
  [ValidateRange(1, 65535)]
  [int]$Port = 4100
)

$ErrorActionPreference = "Stop"

$application = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\applications\content_integrity_monitor")).Path
$platform = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\platform")).Path

Push-Location $application
try {
  mix compile
  if ($LASTEXITCODE -ne 0) { throw "Content Integrity Application compilation failed." }
} finally {
  Pop-Location
}

$applicationEbin = Join-Path $application "_build\dev\lib\content_integrity_monitor\ebin"
$env:CONTEXLA_APPLICATION_PACKAGES = "$applicationEbin|Contexla.Applications.ContentIntegrityMonitor.Package"
$env:CONTEXLA_INTEGRATION_PACKAGES = ""
$env:PORT = $Port.ToString()

Push-Location $platform
try {
  mix ecto.migrate
  if ($LASTEXITCODE -ne 0) { throw "Platform migration failed." }

  mix contexla.packages.migrate
  if ($LASTEXITCODE -ne 0) { throw "Content Integrity Application migration failed." }

  mix phx.server
} finally {
  Pop-Location
}
