# Civilization VII Modding Workspace

This workspace is set up as a long-term home for Civilization VII modding.

- `Civ7BaseAssets/` is a local junction to the Steam base game module.
- `mods/` is where active mod projects should live.
- `docs/` stores setup notes and decisions.
- `tools/` stores repeatable validation helpers.
- `work/` is scratch space.
- `outputs/` is for finished deliverables.

Run the workspace checker before treating a mod as ready:

```powershell
powershell -ExecutionPolicy Bypass -File tools\Test-Civ7Workspace.ps1
```

Deploy a local mod to Civilization VII's user mods folder:

```powershell
powershell -ExecutionPolicy Bypass -File tools\Deploy-Civ7Mod.ps1 -ModName your-mod-name -Clean
```

The deploy script uses this default target:

```text
%LOCALAPPDATA%\Firaxis Games\Sid Meier's Civilization VII\Mods
```

Create a new mod from the template:

```powershell
powershell -ExecutionPolicy Bypass -File tools\New-Civ7Mod.ps1 -Name better-town-growth -DisplayName "Better Town Growth"
```

Check game/workspace state:

```powershell
powershell -ExecutionPolicy Bypass -File tools\Check-Civ7GameState.ps1
```

See also:

- `docs/WORKFLOW.md`
- `docs/MOD_ID_RULES.md`
- `docs/QC.md`
- `docs/RELEASES.md`

Steam install detected:

```text
C:\Program Files (x86)\Steam\steamapps\common\Sid Meier's Civilization VII
```
