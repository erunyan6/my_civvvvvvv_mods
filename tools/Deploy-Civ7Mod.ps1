param(
    [Parameter(Mandatory = $true)]
    [string]$ModName,

    [string]$WorkspaceRoot = (Resolve-Path "$PSScriptRoot\..").Path,

    [string]$Civ7UserRoot = "$env:LOCALAPPDATA\Firaxis Games\Sid Meier's Civilization VII",

    [switch]$Clean
)

$ErrorActionPreference = "Stop"

$source = Join-Path (Join-Path $WorkspaceRoot "mods") $ModName
$modsRoot = Join-Path $Civ7UserRoot "Mods"
$target = Join-Path $modsRoot $ModName

if (-not (Test-Path -LiteralPath $source)) {
    throw "Mod source does not exist: $source"
}

if (-not (Get-ChildItem -LiteralPath $source -Filter "*.modinfo" -File -ErrorAction SilentlyContinue)) {
    throw "Mod source has no .modinfo file: $source"
}

& powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Test-Civ7Workspace.ps1") -WorkspaceRoot $WorkspaceRoot
if ($LASTEXITCODE -ne 0) {
    throw "Workspace validation failed."
}

New-Item -ItemType Directory -Force -Path $modsRoot | Out-Null

if ($Clean -and (Test-Path -LiteralPath $target)) {
    Remove-Item -LiteralPath $target -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $target | Out-Null
Copy-Item -LiteralPath (Join-Path $source "*") -Destination $target -Recurse -Force
Set-Content -LiteralPath (Join-Path $target ".codex-managed") -Value "Managed by Codex Civ VII workspace." -Encoding ascii

Write-Host "Deployed $ModName to $target"
