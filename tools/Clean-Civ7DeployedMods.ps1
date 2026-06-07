param(
    [string]$Civ7UserRoot = "$env:LOCALAPPDATA\Firaxis Games\Sid Meier's Civilization VII",
    [switch]$WhatIfOnly
)

$ErrorActionPreference = "Stop"
$modsRoot = Join-Path $Civ7UserRoot "Mods"

if (-not (Test-Path -LiteralPath $modsRoot)) {
    Write-Host "No Civ VII Mods folder found: $modsRoot"
    exit 0
}

$managedMods = @(Get-ChildItem -LiteralPath $modsRoot -Directory | Where-Object {
    Test-Path -LiteralPath (Join-Path $_.FullName ".codex-managed")
})

foreach ($mod in $managedMods) {
    if ($WhatIfOnly) {
        Write-Host "Would remove $($mod.FullName)"
    }
    else {
        Remove-Item -LiteralPath $mod.FullName -Recurse -Force
        Write-Host "Removed $($mod.FullName)"
    }
}

if ($managedMods.Count -eq 0) {
    Write-Host "No workspace-managed deployed mods found."
}
