# Cycle 0 Asset Inventory

## Source Inventory

Primary assets currently live under `MilsimPonyGame/Assets/PrimaryAssets/`.

| Category | Models (`.obj`) | Materials (`.mtl`) | Notes |
| --- | ---: | ---: | --- |
| `Characters` | 4 | 4 | Human character meshes for placeholder NPC and scale validation |
| `Guns` | 5 | 5 | Weapon meshes for prop staging and later interaction hooks |
| `Props` | 6 | 6 | Backpack, compass, knife, batteries, and survival props |
| `Accessories` | 4 | 4 | Attachment set for later weapon customization or scene dressing |
| **Total** | **19** | **19** | Current bootstrap inventory |

## Cycle 0 Import Rules

1. Treat each `.obj` and matching `.mtl` file as a single import unit and keep basenames aligned.
2. Preserve the existing category folders as stable asset namespaces such as `Props/Knife` or `Characters/Characters_Sam`.
3. Keep source files immutable. Future engine-native caches should be generated into a derived directory instead of rewriting `PrimaryAssets`.
4. Fail fast on missing materials, missing pairs, or duplicate basenames during importer work.
5. Validate scale, forward axis, and pivot placement during cycle `1` before broad world dressing begins.
6. Start render-path validation with `Props` and `Accessories` first because they are the lowest-risk meshes for early scene tests.

## Recommended Next Asset Tasks

- Build a lightweight asset manifest format keyed by category and basename.
- Add a mesh inspection utility that reports bounds, triangle counts, and material linkage.
- Pick one prop and one weapon as the cycle `1` render validation pair.
