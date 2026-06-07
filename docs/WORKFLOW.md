# Civilization VII Modding Workflow

## Create

```powershell
powershell -ExecutionPolicy Bypass -File tools\New-Civ7Mod.ps1 -Name better-town-growth -DisplayName "Better Town Growth" -Description "Adjusts town growth pacing."
```

## Edit

Change files under:

```text
mods\<mod-name>
```

Use `Civ7BaseAssets` as the reference source for table names, XML structure, text keys, and UI patterns.

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File tools\Test-Civ7Workspace.ps1
```

## Deploy One Mod

```powershell
powershell -ExecutionPolicy Bypass -File tools\Deploy-Civ7Mod.ps1 -ModName better-town-growth -Clean
```

## Deploy All Mods

```powershell
powershell -ExecutionPolicy Bypass -File tools\Deploy-All-Civ7Mods.ps1 -Clean
```

## Clean Workspace-Managed Deployed Mods

Preview:

```powershell
powershell -ExecutionPolicy Bypass -File tools\Clean-Civ7DeployedMods.ps1 -WhatIfOnly
```

Remove:

```powershell
powershell -ExecutionPolicy Bypass -File tools\Clean-Civ7DeployedMods.ps1
```

## Package A Release

```powershell
powershell -ExecutionPolicy Bypass -File tools\Package-Civ7Mod.ps1 -ModName better-town-growth -Version 0.1.0
```

## Commit

```powershell
git status
git add .
git commit -m "Describe the mod change"
git push
```
