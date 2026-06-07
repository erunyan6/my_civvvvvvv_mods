# Release Packaging

Use release folders only for tested builds that are ready to share or archive.

Package a mod:

```powershell
powershell -ExecutionPolicy Bypass -File tools\Package-Civ7Mod.ps1 -ModName better-town-growth -Version 0.1.0
```

Output goes to:

```text
outputs\releases\<mod-name>\<version>\<mod-name>-<version>.zip
```

Before packaging, update the mod's `manifest.json`:

- `status`: `ready` or `released`
- `lastValidatedGameBuild`: current Steam build ID
