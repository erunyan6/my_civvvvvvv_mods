# Global Modding Profile: Civilization VII Suite

## 1. Response & Communication Constraints
- Keep explanations under 3-4 sentences.
- If a mod request is ambiguous, missing required database keys, or lacks specific parameters, stop and ask for the missing details.
- When a task finishes or hits a blocker, output a single-line summary of what changed and what step is required next.

## 2. Quality Control & Testing Protocol
- Run static analysis and validation checks on all code edits before declaring a task complete.
- Cross-reference database mutations against `Civ7BaseAssets`, which links to the base game `base-standard` module.
- Check for missing foreign keys, duplicate primary keys, invalid table names, and malformed XML or modinfo files.
- TypeScript UI scripts must compile cleanly without implicit `any` types when a TypeScript toolchain is present.
- Run local validation before returning.

## 3. Tech Stack & Environment Architecture
- `Civ7BaseAssets/` maps to Steam's base game module at `Base/modules/base-standard`.
- Keep deployable mod files in `mods/`, one mod per subdirectory.
- Keep notes in `docs/`, references in `references/`, and temporary experiments in `work/`.
- Never use placeholders or partial updates in mod files.
- Keep compiled outputs isolated and ready for immediate game loading.
