param(
    [Parameter(Mandatory = $true)]
    [string]$ModName,

    [string]$Version = "0.1.0",
    [string]$WorkspaceRoot = (Resolve-Path "$PSScriptRoot\..").Path
)

$ErrorActionPreference = "Stop"

$source = Join-Path (Join-Path $WorkspaceRoot "mods") $ModName
$releaseRoot = Join-Path (Join-Path (Join-Path $WorkspaceRoot "outputs") "releases") (Join-Path $ModName $Version)
$packagePath = Join-Path $releaseRoot "$ModName-$Version.zip"

if (-not (Test-Path -LiteralPath $source)) {
    throw "Mod source does not exist: $source"
}

& powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Test-Civ7Workspace.ps1") -WorkspaceRoot $WorkspaceRoot
if ($LASTEXITCODE -ne 0) {
    throw "Workspace validation failed."
}

New-Item -ItemType Directory -Force -Path $releaseRoot | Out-Null
if (Test-Path -LiteralPath $packagePath) {
    Remove-Item -LiteralPath $packagePath -Force
}

Compress-Archive -LiteralPath $source -DestinationPath $packagePath
Write-Host "Packaged $ModName $Version to $packagePath"
