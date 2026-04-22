# NPC Traversal Audit

Generated on 2026-04-22T04:47:39Z from `/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/world_manifest.json`.

This audit drives reusable `GameNPCState` movement through the Canberra world package and records where the agent cannot start, cannot plan a path, gets stuck, or times out.

Anchor set: authored spawns, route checkpoints, and cover points that should all be valid actor locations.

Generated bug blacklists:
- Markdown: `/Users/barbalet/github/milsim-pony/Docs/NPC_TRAVERSAL_BLACKLIST.md`
- JSON: `/Users/barbalet/github/milsim-pony/Docs/NPC_TRAVERSAL_BLACKLIST.json`

Every blacklist entry is a bug to check and fix. None of these failures are treated as acceptable behavior.

## Summary

| Metric | Value |
| --- | --- |
| Iterations requested | 256 |
| Iterations executed | 256 |
| Anchors audited | 24 |
| Blacklisted anchors | 0 |
| Blacklisted links | 63 |
| Successful traversals | 193 |
| Failed traversals | 63 |
| `invalid_start` | 0 |
| `invalid_goal` | 0 |
| `no_path` | 0 |
| `stuck` | 63 |
| `time_limit` | 0 |
| Average successful planned distance | 87.4 m |
| Average successful elapsed time | 14.2 s |

## Frequent Failures

| Path | Failures | Dominant Outcome |
| --- | ---: | --- |
| Anzac Parade North Review -> Barton Foreshore Review | 1 | stuck |
| Anzac Parade North Review -> Scope Terrace Wall | 1 | stuck |
| Anzac Parade Screen -> Barton Foreshore Screen | 1 | stuck |
| Anzac Parade Screen -> East Basin Scope Terrace | 1 | stuck |
| Anzac Parade Screen -> Scope Terrace Wall | 1 | stuck |
| Anzac Parade Start -> East Basin Scope Perch | 1 | stuck |
| Barton Foreshore Review -> Anzac Parade North Review | 1 | stuck |
| Barton Foreshore Review -> Anzac Parade Start | 1 | stuck |
| Barton Foreshore Review -> Barton Foreshore Start | 1 | stuck |
| Barton Foreshore Review -> City Hill Civic Screen | 1 | stuck |
| Barton Foreshore Review -> City Hill Civic Start | 1 | stuck |
| Barton Foreshore Review -> Civic Grid Screen | 1 | stuck |
| Barton Foreshore Review -> Civic Grid Start | 1 | stuck |
| Barton Foreshore Review -> Parliament Axis Scope Test | 1 | stuck |
| Barton Foreshore Review -> Parliament Axis Start | 1 | stuck |
| Barton Foreshore Screen -> Civic Grid Screen | 1 | stuck |
| Barton Foreshore Screen -> Kings Avenue Bridge Review | 1 | stuck |
| Barton Foreshore Screen -> Kings Bridge Screen | 1 | stuck |
| Barton Foreshore Start -> Barton Foreshore Review | 1 | stuck |
| Barton Foreshore Start -> East Basin Scope Terrace | 1 | stuck |

## Failure Table

| # | Start | Goal | Outcome | Planned m | Travelled m | Last Position | Note |
| ---: | --- | --- | --- | ---: | ---: | --- | --- |
| 1 | East Basin Scope Perch | Kings Avenue Bridge Review | stuck | 40.2 | 16.6 | (77.8, 1.9) | NPC stuck while approaching waypoint 3 / 7 |
| 2 | Kings Avenue Bridge Review | East Basin Scope Perch | stuck | 40.2 | 81.3 | (73.2, 2.0) | NPC stuck while approaching waypoint 5 / 7 |
| 7 | Barton Foreshore Review | Parliament Axis Scope Test | stuck | 103.5 | 68.0 | (77.9, 2.0) | NPC stuck while approaching waypoint 4 / 17 |
| 8 | Parliament Axis Scope Test | Barton Foreshore Review | stuck | 103.5 | 127.0 | (73.2, 2.0) | NPC stuck while approaching waypoint 14 / 17 |
| 19 | Barton Foreshore Start | Barton Foreshore Review | stuck | 20.5 | 23.0 | (79.2, -3.8) | NPC stuck while approaching waypoint 3 / 5 |
| 20 | Barton Foreshore Review | Barton Foreshore Start | stuck | 20.5 | 20.0 | (81.9, 0.2) | NPC stuck while approaching waypoint 3 / 5 |
| 32 | Civic Centre Grid Review | Barton Foreshore Screen | stuck | 174.1 | 164.3 | (79.9, -3.9) | NPC stuck while approaching waypoint 25 / 28 |
| 33 | East Basin Scope Perch | Russell Bridge Screen | stuck | 78.2 | 37.7 | (78.9, 0.5) | NPC stuck while approaching waypoint 3 / 12 |
| 36 | East Basin Scope Perch | Civic Grid Start | stuck | 162.1 | 37.7 | (78.9, 0.5) | NPC stuck while approaching waypoint 3 / 26 |
| 37 | Scope Terrace Wall | City Hill Civic Screen | stuck | 145.1 | 30.3 | (78.7, 0.6) | NPC stuck while approaching waypoint 3 / 23 |
| 38 | City Hill Arterial Review | Barton Foreshore Review | stuck | 147.6 | 150.2 | (79.9, -3.9) | NPC stuck while approaching waypoint 21 / 23 |
| 44 | Parliament Axis Scope Test | Barton Foreshore Screen | stuck | 109.5 | 127.0 | (73.2, 2.0) | NPC stuck while approaching waypoint 14 / 18 |
| 48 | Barton Foreshore Review | Civic Grid Screen | stuck | 170.6 | 20.0 | (81.9, 0.2) | NPC stuck while approaching waypoint 3 / 27 |
| 49 | Civic Grid Start | Barton Foreshore Screen | stuck | 168.1 | 156.7 | (79.7, -3.9) | NPC stuck while approaching waypoint 24 / 27 |
| 52 | East Basin Scope Perch | Russell Causeway Review | stuck | 74.8 | 37.7 | (78.9, 0.5) | NPC stuck while approaching waypoint 3 / 11 |
| 54 | East Basin Scope Perch | Civic Centre Grid Review | stuck | 168.1 | 37.7 | (78.9, 0.5) | NPC stuck while approaching waypoint 3 / 27 |
| 61 | Scope Terrace Wall | City Hill Arterial Review | stuck | 147.6 | 30.3 | (78.7, 0.6) | NPC stuck while approaching waypoint 3 / 23 |
| 67 | East Basin Scope Terrace | Anzac Parade Screen | stuck | 123.8 | 27.9 | (81.9, 0.2) | NPC stuck while approaching waypoint 4 / 20 |
| 72 | Mount Ainslie Rise Review | Scope Terrace Wall | stuck | 173.5 | 212.7 | (78.0, -3.7) | NPC stuck while approaching waypoint 25 / 27 |
| 77 | East Basin Scope Perch | City Hill Arterial Review | stuck | 147.6 | 37.7 | (78.9, 0.5) | NPC stuck while approaching waypoint 3 / 23 |
| 78 | Barton Foreshore Review | Parliament Axis Start | stuck | 104.4 | 68.0 | (77.9, 2.0) | NPC stuck while approaching waypoint 4 / 17 |
| 95 | Barton Foreshore Review | City Hill Civic Screen | stuck | 145.1 | 20.0 | (81.9, 0.2) | NPC stuck while approaching waypoint 3 / 23 |
| 96 | Barton Foreshore Review | Civic Grid Start | stuck | 162.1 | 20.0 | (81.9, 0.2) | NPC stuck while approaching waypoint 3 / 26 |
| 101 | East Basin Scope Perch | Anzac Parade Start | stuck | 112.8 | 37.7 | (78.9, 0.5) | NPC stuck while approaching waypoint 3 / 19 |
| 109 | East Basin Scope Perch | Kings Bridge Screen | stuck | 50.0 | 25.9 | (77.6, 0.7) | NPC stuck while approaching waypoint 3 / 7 |
| 111 | Parliament Axis Start | Scope Terrace Wall | stuck | 100.9 | 128.7 | (73.2, 2.0) | NPC stuck while approaching waypoint 14 / 16 |
| 115 | East Basin Scope Terrace | Kings Bridge Screen | stuck | 64.3 | 27.9 | (81.9, 0.2) | NPC stuck while approaching waypoint 4 / 9 |
| 117 | Anzac Parade Start | East Basin Scope Perch | stuck | 112.8 | 136.8 | (78.0, -3.7) | NPC stuck while approaching waypoint 17 / 19 |
| 123 | East Basin Scope Terrace | Parliament Axis Scope Test | stuck | 114.4 | 76.9 | (77.8, 2.0) | NPC stuck while approaching waypoint 5 / 18 |
| 125 | East Basin Scope Perch | Parliament Axis Scope Test | stuck | 100.0 | 16.6 | (77.8, 1.9) | NPC stuck while approaching waypoint 3 / 16 |
| 127 | Anzac Parade North Review | Scope Terrace Wall | stuck | 104.3 | 139.3 | (78.0, -3.7) | NPC stuck while approaching waypoint 16 / 18 |
| 134 | East Basin Scope Terrace | City Hill Arterial Review | stuck | 158.5 | 27.9 | (81.9, 0.2) | NPC stuck while approaching waypoint 4 / 24 |
| 135 | Anzac Parade North Review | Barton Foreshore Review | stuck | 104.3 | 114.6 | (79.9, -3.9) | NPC stuck while approaching waypoint 16 / 18 |
| 137 | Barton Foreshore Screen | Kings Avenue Bridge Review | stuck | 49.7 | 25.9 | (81.9, 0.2) | NPC stuck while approaching waypoint 4 / 9 |
| 142 | Russell Causeway Start | Scope Terrace Wall | stuck | 83.3 | 74.7 | (77.9, -3.7) | NPC stuck while approaching waypoint 10 / 12 |
| 147 | Barton Foreshore Start | East Basin Scope Terrace | stuck | 31.5 | 23.0 | (79.2, -3.8) | NPC stuck while approaching waypoint 3 / 6 |
| 148 | Scope Terrace Wall | Civic Grid Screen | stuck | 170.6 | 30.3 | (78.7, 0.6) | NPC stuck while approaching waypoint 3 / 27 |
| 149 | Civic Grid Screen | East Basin Scope Perch | stuck | 170.6 | 198.5 | (78.0, -3.7) | NPC stuck while approaching waypoint 25 / 27 |
| 150 | East Basin Scope Terrace | Kings Avenue Bridge Review | stuck | 54.6 | 27.9 | (81.9, 0.2) | NPC stuck while approaching waypoint 4 / 9 |
| 154 | Scope Terrace Wall | Russell Causeway Start | stuck | 83.3 | 30.3 | (78.7, 0.6) | NPC stuck while approaching waypoint 3 / 12 |
| 158 | Barton Foreshore Screen | Kings Bridge Screen | stuck | 59.4 | 25.9 | (81.9, 0.2) | NPC stuck while approaching waypoint 4 / 9 |
| 164 | Anzac Parade Screen | Barton Foreshore Screen | stuck | 118.8 | 123.4 | (79.9, -3.9) | NPC stuck while approaching waypoint 17 / 20 |
| 169 | Anzac Parade Screen | East Basin Scope Terrace | stuck | 123.8 | 123.4 | (79.9, -3.9) | NPC stuck while approaching waypoint 17 / 20 |
| 172 | East Basin Scope Perch | Mount Ainslie Rise Review | stuck | 173.5 | 37.7 | (78.9, 0.5) | NPC stuck while approaching waypoint 3 / 27 |
| 173 | Scope Terrace Wall | Russell Bridge Screen | stuck | 78.2 | 30.3 | (78.7, 0.6) | NPC stuck while approaching waypoint 3 / 12 |
| 175 | Parliament Axis Scope Test | East Basin Scope Terrace | stuck | 114.4 | 127.0 | (73.2, 2.0) | NPC stuck while approaching waypoint 14 / 18 |
| 176 | East Basin Scope Terrace | Parliament Axis Start | stuck | 115.4 | 76.9 | (77.8, 2.0) | NPC stuck while approaching waypoint 5 / 18 |
| 189 | East Basin Scope Perch | Parliament Axis Start | stuck | 100.9 | 16.6 | (77.8, 1.9) | NPC stuck while approaching waypoint 3 / 16 |
| 191 | Civic Centre Grid Review | Scope Terrace Wall | stuck | 168.1 | 193.3 | (78.0, -3.7) | NPC stuck while approaching waypoint 25 / 27 |
| 195 | Kings Bridge Screen | Barton Foreshore Review | stuck | 53.4 | 41.7 | (78.7, -3.8) | NPC stuck while approaching waypoint 6 / 8 |
| 198 | East Basin Scope Terrace | Civic Centre Grid Review | stuck | 179.1 | 27.9 | (81.9, 0.2) | NPC stuck while approaching waypoint 4 / 28 |
| 199 | Barton Foreshore Review | Anzac Parade Start | stuck | 112.8 | 20.0 | (81.9, 0.2) | NPC stuck while approaching waypoint 3 / 19 |
| 202 | East Basin Scope Terrace | Civic Grid Screen | stuck | 181.6 | 27.9 | (81.9, 0.2) | NPC stuck while approaching waypoint 4 / 28 |
| 217 | East Basin Scope Perch | Mount Ainslie Rise Screen | stuck | 182.0 | 37.7 | (78.9, 0.5) | NPC stuck while approaching waypoint 3 / 28 |
| 228 | Barton Foreshore Screen | Civic Grid Screen | stuck | 176.6 | 25.9 | (81.9, 0.2) | NPC stuck while approaching waypoint 4 / 28 |
| 229 | City Hill Civic Start | Barton Foreshore Screen | stuck | 151.1 | 140.9 | (79.6, -3.9) | NPC stuck while approaching waypoint 21 / 24 |
| 238 | Barton Foreshore Review | Anzac Parade North Review | stuck | 104.3 | 20.0 | (81.9, 0.2) | NPC stuck while approaching waypoint 3 / 18 |
| 239 | Barton Foreshore Review | City Hill Civic Start | stuck | 145.1 | 20.0 | (81.9, 0.2) | NPC stuck while approaching waypoint 3 / 23 |
| 240 | East Basin Scope Terrace | Anzac Parade North Review | stuck | 115.3 | 27.9 | (81.9, 0.2) | NPC stuck while approaching waypoint 4 / 19 |
| 247 | Civic Grid Screen | Barton Foreshore Screen | stuck | 176.6 | 169.9 | (79.9, -3.9) | NPC stuck while approaching waypoint 25 / 28 |
| 248 | East Basin Scope Perch | City Hill Civic Start | stuck | 145.1 | 37.7 | (78.9, 0.5) | NPC stuck while approaching waypoint 3 / 23 |
| 251 | Anzac Parade Screen | Scope Terrace Wall | stuck | 112.8 | 149.8 | (78.0, -3.7) | NPC stuck while approaching waypoint 17 / 19 |
| 253 | Kings Bridge Screen | East Basin Scope Perch | stuck | 50.0 | 37.0 | (73.2, -3.2) | NPC stuck while approaching waypoint 5 / 7 |

## Notes

- The audit used a `6.0m` planning grid with the same ground and collision queries that the live `GameCore` world uses.
- Successful paths only confirm that an NPC can follow the planned route under the current collision and ground setup.
- Every blacklist entry is a real bug candidate to fix in world data, authored anchor placement, or NPC traversal logic. The audit no longer treats these failures as expected.
- The agent movement runs in `GameNPCState` so the audit exercises reusable NPC traversal logic instead of a test-only teleport script.
