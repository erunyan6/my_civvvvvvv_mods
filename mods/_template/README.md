# Civilization VII Mod Template

Copy this folder to a new mod folder, then update:

- folder name
- `.modinfo` file name
- `<Mod id="...">`
- localized name and description tags
- data and text files

Deploy with:

```powershell
powershell -ExecutionPolicy Bypass -File tools\Deploy-Civ7Mod.ps1 -ModName your-mod-name -Clean
```
