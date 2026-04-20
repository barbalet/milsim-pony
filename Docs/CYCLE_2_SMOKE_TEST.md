# Cycle 2 Smoke Test

## Build

Use:

```sh
xcodebuild -project MilsimPonyGame.xcodeproj -scheme MilsimPonyGame -configuration Debug -derivedDataPath /tmp/MilsimPonyDerived CODE_SIGNING_ALLOWED=NO build
```

## Launch Checks

1. The app opens into the same lit 3D bootstrap area, but the scene is now loaded from `Assets/WorldData/CanberraBootstrap`.
2. The overlay shows a scene summary, manifest/grid/sector debug lines, and live frame timing.
3. Additional props and graybox masses from the sector files are visible instead of only the hardcoded two-prop pad.
4. The spawn position and initial look angle come from the scene JSON rather than only C defaults.

## Data Checks

1. `MilsimPonyGame/Assets/WorldData/CanberraBootstrap/world_manifest.json` resolves the scene, coordinate system, and sector files.
2. The scene file drives procedural elements, imported asset instances, and included sector IDs.
3. The sector files contribute graybox blocks that render in the live scene.

## Exit Gate

Cycle `2` is complete when the bootstrap scene is authored from data files, Canberra sector stubs exist on disk, and the running app reports frame timing plus loaded world-data context in the HUD.
