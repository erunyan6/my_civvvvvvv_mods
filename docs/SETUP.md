# Civilization VII Setup Notes

## Detected Paths

- Game install: `C:\Program Files (x86)\Steam\steamapps\common\Sid Meier's Civilization VII`
- Base module: `C:\Program Files (x86)\Steam\steamapps\common\Sid Meier's Civilization VII\Base\modules\base-standard`
- Workspace base reference: `Civ7BaseAssets`

## Working Pattern

1. Create each mod under `mods/<mod-name>/`.
2. Use `Civ7BaseAssets/data`, `Civ7BaseAssets/config`, `Civ7BaseAssets/text`, and `Civ7BaseAssets/ui` as the source of truth.
3. Validate before testing in game:

```powershell
powershell -ExecutionPolicy Bypass -File tools\Test-Civ7Workspace.ps1
```

## Notes For Future Sessions

- Ask for exact gameplay targets before changing balance, units, buildings, leaders, civilizations, ages, text, or UI.
- Do not edit the Steam game files directly.
- Prefer adding new isolated mod files over overwriting base game files.
- Keep every mod self-contained with a `.modinfo` file at its root.
