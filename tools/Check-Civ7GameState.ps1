param(
    [string]$WorkspaceRoot = (Resolve-Path "$PSScriptRoot\..").Path,
    [string]$Civ7UserRoot = "$env:LOCALAPPDATA\Firaxis Games\Sid Meier's Civilization VII"
)

$ErrorActionPreference = "Stop"

$gameInstall = "C:\Program Files (x86)\Steam\steamapps\common\Sid Meier's Civilization VII"
$baseReference = Join-Path $WorkspaceRoot "Civ7BaseAssets"
$steamManifest = "C:\Program Files (x86)\Steam\steamapps\appmanifest_1295660.acf"
$modsFolder = Join-Path $Civ7UserRoot "Mods"
$buildId = "unknown"

if (Test-Path -LiteralPath $steamManifest) {
    $match = Select-String -LiteralPath $steamManifest -Pattern '"buildid"\s+"([^"]+)"' | Select-Object -First 1
    if ($match) {
        $buildId = $match.Matches[0].Groups[1].Value
    }
}

$state = [ordered]@{
    gameInstallExists = Test-Path -LiteralPath $gameInstall
    baseReferenceExists = Test-Path -LiteralPath $baseReference
    steamBuildId = $buildId
    civ7UserRootExists = Test-Path -LiteralPath $Civ7UserRoot
    modsFolderExists = Test-Path -LiteralPath $modsFolder
    workspaceMods = @()
    deployedManagedMods = @()
    warnings = @()
}

$workspaceModsRoot = Join-Path $WorkspaceRoot "mods"
if (Test-Path -LiteralPath $workspaceModsRoot) {
    $state.workspaceMods = @(Get-ChildItem -LiteralPath $workspaceModsRoot -Directory |
        Where-Object { $_.Name -ne "_template" } |
        Select-Object -ExpandProperty Name)
}

if (Test-Path -LiteralPath $modsFolder) {
    try {
        $state.deployedManagedMods = @(Get-ChildItem -LiteralPath $modsFolder -Directory |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName ".codex-managed") } |
            Select-Object -ExpandProperty Name)
    }
    catch {
        $state.warnings = @("Could not read deployed mods folder: $modsFolder :: $($_.Exception.Message)")
    }
}

$state | ConvertTo-Json -Depth 4
