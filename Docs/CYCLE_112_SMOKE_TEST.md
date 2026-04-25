# Cycle 112 Smoke Test - District Texture Closeout

Verify that the Canberra demo behaves as a cycle `112` Black Mountain and West Basin texture closeout while preserving the cycle `99` through `111` REVIEW recovery work.

## Build And Launch

- Build the `MilsimPonyGame` scheme.
- Confirm the HUD title reads `Cycle 112 District Texture Closeout`.
- Confirm the release display reports `v1.12.0 (112)`.

## Texture Coverage

- Reach `West Basin Promenade Review` and confirm `West Basin Materials:` reports shoreline, water, vegetation, asphalt, hardscape, and facade acceptance framing.
- Reach or scope toward `Black Mountain Scope Lane` and confirm `Black Mountain Materials:` reports Telstra/Bruce/Belconnen source-backed material framing.
- Confirm West Basin roads and Black Mountain/Bruce/Belconnen approach roads use the Canberra arterial asphalt material rather than flat road color only.
- Confirm Black Mountain/Bruce slopes use dry-grass texture coverage and tower/perch retaining walls use concrete texture coverage.
- Confirm Bruce/AIS, Belconnen, Yarralumla, and shoreline support masses use facade breakup instead of plain graybox color.
- Cross-check the acceptance notes in `Docs/CYCLE_112_TEXTURE_ACCEPTANCE.md`.

## Regression

- Preserve Cycle 111 patrol-pair movement and `Patrol Pairs:` readouts.
- Preserve Cycle 110 scoped firing feedback and `Shot Feedback:` readouts.
- Preserve Cycle 109 authored audio mix and `Audio Mix:` readouts.
- Preserve capture and package validation paths.
