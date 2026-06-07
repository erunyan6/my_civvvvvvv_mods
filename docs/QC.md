# Civilization VII QC Checklist

Run before any in-game test:

```powershell
powershell -ExecutionPolicy Bypass -File tools\Test-Civ7Workspace.ps1
```

The checker verifies:

- `Civ7BaseAssets` exists.
- XML and `.modinfo` files are well-formed.
- every mod has exactly one root `.modinfo`.
- every non-template mod has a `manifest.json`.
- `.modinfo` IDs match manifest IDs.
- `.modinfo` `Item` paths exist.
- localized text file references exist.
- duplicate local `Row` keys are caught.
- template placeholders are not left in real mods.
- SQL table names are checked against base XML containers when SQL exists.
- Steam build ID mismatches are shown as warnings.

After deployment, use:

```powershell
powershell -ExecutionPolicy Bypass -File tools\Check-Civ7GameState.ps1
```
