# Cycle 21 Contact Rehearsal

## Build Framing

- Live build: [MilsimPonyGame.xcodeproj](/Users/barbalet/github/milsim-pony/MilsimPonyGame.xcodeproj)
- Smoke test: [Docs/CYCLE_21_SMOKE_TEST.md](/Users/barbalet/github/milsim-pony/Docs/CYCLE_21_SMOKE_TEST.md)
- Review baseline: [Docs/CYCLE_20_REVIEW_PACK.md](/Users/barbalet/github/milsim-pony/Docs/CYCLE_20_REVIEW_PACK.md)
- Reference gallery: [Docs/CanberraReferenceGallery/README.md](/Users/barbalet/github/milsim-pony/Docs/CanberraReferenceGallery/README.md)
- Texture audit: [MilsimPonyGame/Assets/Textures/README.md](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/Textures/README.md)

## Rehearsal Goal

- Keep the cycle `20` Woden-to-Belconnen review route intact.
- Add enough live observer pressure that the route can fail and recover.
- Surface the next contact lane, cover hint, and recovery rule directly in the HUD and overhead map.

## Contact Stops

- `Woden Scope Perch`: southern basin overwatch lane, medium exposure, break at Woden Interchange Screen and Woden Scope Wall.
- `State Circle Transfer`: Parliament south approach lane, medium exposure, break at State Circle Median.
- `Kings Avenue East Review`: Kings Avenue transfer lane, medium exposure, break at Kings Avenue Screen.
- `East Basin Lookout`: east-basin shoreline lane, high exposure, break at East Basin Survey Wall.
- `Constitution Axis Review`: Russell transfer lane, medium exposure, break at Constitution Axis Screen.
- `Civic Interchange Review`: city-centre response lane, high exposure, break at Civic Interchange Screen.
- `West Basin Promenade Review`: west-basin embankment lane, medium exposure, break at West Basin Screen.
- `Black Mountain Scope Perch`: north-west overwatch lane, high exposure, break at Tower Footing Screen.
- `Belconnen Town Centre Review`: Belconnen town-centre lane, medium exposure, break at Belconnen Median Screen.
- `Ginninderra Drive Review`: Ginninderra northern exit lane, medium exposure, break at Ginninderra Access Screen.

## Observer Set

- Live observers now sit in Woden, State Circle, east basin, Constitution Avenue, Civic, West Basin, Black Mountain, Belconnen, and Ginninderra.
- The rehearsal is tuned as pressure, not a firefight: each lane usually has one watcher, and the failure loop still resolves through checkpoint retry instead of a hard run reset.

## Exit Gate

- The route still reads as Canberra without developer narration.
- The HUD and map expose enough contact information that a reviewer can understand the next lane before stepping into it.
- Fail, retry, and completion states all still resolve cleanly while observer pressure is active.
