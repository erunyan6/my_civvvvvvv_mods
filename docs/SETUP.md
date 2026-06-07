# Civilization VII Setup Notes

## Detected Paths

- Game install: `C:\Program Files (x86)\Steam\steamapps\common\Sid Meier's Civilization VII`
- Base module: `C:\Program Files (x86)\Steam\steamapps\common\Sid Meier's Civilization VII\Base\modules\base-standard`
- Workspace base reference: `Civ7BaseAssets`
- Expected user data root: `%LOCALAPPDATA%\Firaxis Games\Sid Meier's Civilization VII`
- Expected local mods folder: `%LOCALAPPDATA%\Firaxis Games\Sid Meier's Civilization VII\Mods`
- GitHub repo: `https://github.com/erunyan6/my_civvvvvvv_mods`

## Working Pattern

1. Create each mod under `mods/<mod-name>/`.
2. Use `Civ7BaseAssets/data`, `Civ7BaseAssets/config`, `Civ7BaseAssets/text`, and `Civ7BaseAssets/ui` as the source of truth.
3. Validate before testing in game:

```powershell
powershell -ExecutionPolicy Bypass -File tools\Test-Civ7Workspace.ps1
```

4. Deploy a finished local mod:

```powershell
powershell -ExecutionPolicy Bypass -File tools\Deploy-Civ7Mod.ps1 -ModName <mod-folder-name> -Clean
```

The deploy helper creates the user mods folder if needed.

## Notes For Future Sessions

- Ask for exact gameplay targets before changing balance, units, buildings, leaders, civilizations, ages, text, or UI.
- Do not edit the Steam game files directly.
- Prefer adding new isolated mod files over overwriting base game files.
- Keep every mod self-contained with a `.modinfo` file at its root.
- Use `mods/_template` as the starting point for each new mod.
