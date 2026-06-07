param(
    [string]$WorkspaceRoot = (Resolve-Path "$PSScriptRoot\..").Path,
    [string]$Civ7UserRoot = "$env:LOCALAPPDATA\Firaxis Games\Sid Meier's Civilization VII",
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$modsRoot = Join-Path $WorkspaceRoot "mods"

& powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Test-Civ7Workspace.ps1") -WorkspaceRoot $WorkspaceRoot -Civ7UserRoot $Civ7UserRoot
if ($LASTEXITCODE -ne 0) {
    throw "Workspace validation failed."
}

Get-ChildItem -LiteralPath $modsRoot -Directory |
    Where-Object { $_.Name -ne "_template" } |
    ForEach-Object {
        & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Deploy-Civ7Mod.ps1") -ModName $_.Name -WorkspaceRoot $WorkspaceRoot -Civ7UserRoot $Civ7UserRoot -Clean:$Clean
    }
