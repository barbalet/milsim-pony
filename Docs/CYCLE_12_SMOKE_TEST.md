# Cycle 12 Smoke Test

## Goal

Verify that the Canberra demo now behaves as a cycle `12` scope-and-resolution pass: higher-resolution local perch sectors stream in around the authored review lanes, the player can raise a 4x optic in live play, and distant Canberra landmarks remain readable through the scoped render path.

## Build

Run:

```bash
xcodebuild -project MilsimPonyGame.xcodeproj -scheme MilsimPonyGame -configuration Debug -derivedDataPath /tmp/MilsimPonyDerived CODE_SIGNING_ALLOWED=NO build
```

Expected result:

- Build completes successfully.
- `MilsimPonyGame.app` is produced under `/tmp/MilsimPonyDerived/Build/Products/Debug/`.

## Launch

Run:

```bash
open /tmp/MilsimPonyDerived/Build/Products/Debug/MilsimPonyGame.app
```

Expected result:

- The HUD title reads `Cycle 12 Scope And Resolution Foundation`.
- The title shell title reads `Canberra Scope Validation Review`.
- The route card describes `Canberra Scope Landmark Validation`.
- The world readout still frames the package as `Canberra Woden-Belconnen Basin`.

## Scope Path

Expected result:

- The player spawns at `East Basin Scope Terrace`.
- Pressing `Space` or `Return` during live play raises a circular scope overlay with a reticle and status label.
- Pressing `Space` again lowers the scope and restores the normal view.
- While scoped, distant Canberra landmarks remain visible instead of clipping away at the old short far plane.

## Resolution And Streaming

Expected result:

- The overlay `Sectors:` detail lists the new local scope sectors: `East Basin Scope Lane`, `Central Basin Scope Lane`, `Woden Scope Perch`, and `Black Mountain Scope Perch`.
- The overlay `Residency:` detail reports `1 always / 2 far-field / 7 local`.
- The streaming summary reports both near sectors and resident sectors while moving between the authored perches.
- Central basin, Woden, and Black Mountain review areas show denser local pads, roads, walls, and landmark massing than the previous macro-only pass.

## Validation Route

Expected result:

- The five review markers are `East Basin Scope Perch`, `Parliament Axis Scope Test`, `Woden Tower Scope Test`, `Black Mountain Scope Test`, and `Belconnen Horizon Scope Test`.
- Guidance markers include `Lake Basin Scope Lane`, `Parliament Scope Axis`, `Woden Scope Frame`, `Black Mountain Scope Frame`, `Belconnen Horizon Frame`, and `Raise 4x Scope`.
- Restarting from a checkpoint returns the player to the current scope-validation flow without losing the ability to raise the optic.

## Regression Check

Expected result:

- `W A S D`, mouse look, `Shift`, `Esc`, restart, and return-to-briefing still work.
- The app still loads world data through the scene package path without falling back to the procedural error scene.
- Frame timing, route metrics, sector residency, scope state, and camera telemetry continue updating in the HUD during the review pass.
