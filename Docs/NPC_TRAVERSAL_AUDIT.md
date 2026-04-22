# NPC Traversal Audit

Generated on 2026-04-22T03:53:41Z from `/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/world_manifest.json`.

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
| Anchors audited | 21 |
| Blacklisted anchors | 6 |
| Blacklisted links | 57 |
| Successful traversals | 77 |
| Failed traversals | 179 |
| `invalid_start` | 70 |
| `invalid_goal` | 52 |
| `no_path` | 0 |
| `stuck` | 57 |
| `time_limit` | 0 |
| Average successful planned distance | 153.9 m |
| Average successful elapsed time | 24.1 s |

## Frequent Failures

| Path | Failures | Dominant Outcome |
| --- | ---: | --- |
| Belconnen Interchange Screen -> Black Mountain Saddle Start | 1 | invalid_start |
| Belconnen Interchange Screen -> Black Mountain Scope Test | 1 | invalid_start |
| Belconnen Interchange Screen -> Bruce Scope Saddle | 1 | invalid_start |
| Belconnen Interchange Screen -> Central Basin Screen | 1 | invalid_start |
| Belconnen Interchange Screen -> City Hill Median | 1 | invalid_start |
| Belconnen Interchange Screen -> City Hill Median Start | 1 | invalid_start |
| Belconnen Interchange Screen -> East Basin Scope Terrace | 1 | invalid_start |
| Belconnen Interchange Screen -> Parliament Axis Scope Test | 1 | invalid_start |
| Belconnen Interchange Screen -> Parliament Axis Start | 1 | invalid_start |
| Belconnen Interchange Screen -> Russell Causeway Review | 1 | invalid_start |
| Belconnen Interchange Screen -> Russell Causeway Start | 1 | invalid_start |
| Belconnen Interchange Screen -> Woden Interchange Wall | 1 | invalid_start |
| Belconnen Street Frame Start -> Belconnen Town Centre Review | 1 | invalid_start |
| Belconnen Street Frame Start -> Black Mountain Scope Test | 1 | invalid_start |
| Belconnen Street Frame Start -> Central Basin Screen | 1 | invalid_start |
| Belconnen Street Frame Start -> City Hill Arterial Review | 1 | invalid_start |
| Belconnen Street Frame Start -> East Basin Scope Perch | 1 | invalid_start |
| Belconnen Street Frame Start -> East Basin Scope Terrace | 1 | invalid_start |
| Belconnen Street Frame Start -> Russell Bridge Screen | 1 | invalid_start |
| Belconnen Street Frame Start -> Russell Causeway Start | 1 | invalid_start |

## Failure Table

| # | Start | Goal | Outcome | Planned m | Travelled m | Last Position | Note |
| ---: | --- | --- | --- | ---: | ---: | --- | --- |
| 1 | East Basin Scope Perch | Russell Causeway Review | stuck | 74.8 | 37.7 | (78.9, 0.5) | NPC stuck while approaching waypoint 3 / 11 |
| 2 | Russell Causeway Review | East Basin Scope Perch | stuck | 74.8 | 65.1 | (77.9, -3.7) | NPC stuck while approaching waypoint 9 / 11 |
| 7 | City Hill Arterial Review | Woden Town Centre Review | stuck | 297.9 | 203.1 | (18.0, 20.0) | NPC stuck while approaching waypoint 25 / 49 |
| 8 | Woden Town Centre Review | City Hill Arterial Review | stuck | 297.9 | 195.3 | (18.0, 23.1) | NPC stuck while approaching waypoint 25 / 49 |
| 9 | Woden Town Centre Review | Black Mountain Scope Test | stuck | 361.3 | 195.3 | (18.0, 23.1) | NPC stuck while approaching waypoint 25 / 54 |
| 10 | Black Mountain Scope Test | Woden Town Centre Review | stuck | 361.3 | 244.9 | (18.0, 20.0) | NPC stuck while approaching waypoint 30 / 54 |
| 13 | Belconnen Street Frame Start | Belconnen Town Centre Review | invalid_start | 0.0 | 0.0 | (-148.0, -186.0) | Anchor position overlaps collision or blocked occupancy |
| 14 | Belconnen Town Centre Review | Belconnen Street Frame Start | invalid_goal | 0.0 | 0.0 | (-141.4, -179.2) | Anchor position overlaps collision or blocked occupancy |
| 17 | City Hill Median Start | City Hill Arterial Review | invalid_start | 0.0 | 0.0 | (38.0, -110.0) | Anchor position overlaps collision or blocked occupancy |
| 18 | City Hill Arterial Review | City Hill Median Start | invalid_goal | 0.0 | 0.0 | (47.0, -118.0) | Anchor position overlaps collision or blocked occupancy |
| 25 | Woden Interchange Start | Woden Town Centre Review | invalid_start | 0.0 | 0.0 | (18.0, 168.0) | Anchor position overlaps collision or blocked occupancy |
| 26 | Woden Town Centre Review | Woden Interchange Start | invalid_goal | 0.0 | 0.0 | (21.0, 164.0) | Anchor position overlaps collision or blocked occupancy |
| 27 | East Basin Scope Perch | Russell Bridge Screen | stuck | 78.2 | 37.7 | (78.9, 0.5) | NPC stuck while approaching waypoint 3 / 12 |
| 29 | East Basin Scope Perch | Woden Interchange Wall | invalid_goal | 0.0 | 0.0 | (86.0, 8.0) | Anchor position overlaps collision or blocked occupancy |
| 31 | City Hill Median Start | Belconnen Town Centre Review | invalid_start | 0.0 | 0.0 | (38.0, -110.0) | Anchor position overlaps collision or blocked occupancy |
| 32 | Belconnen Street Frame Start | Central Basin Screen | invalid_start | 0.0 | 0.0 | (-148.0, -186.0) | Anchor position overlaps collision or blocked occupancy |
| 33 | Russell Causeway Review | Woden Town Centre Review | stuck | 261.5 | 115.0 | (72.0, -3.1) | NPC stuck while approaching waypoint 9 / 37 |
| 34 | Russell Causeway Review | City Hill Median Start | invalid_goal | 0.0 | 0.0 | (118.0, -46.0) | Anchor position overlaps collision or blocked occupancy |
| 35 | Russell Bridge Screen | Woden Interchange Start | invalid_goal | 0.0 | 0.0 | (112.0, -54.0) | Anchor position overlaps collision or blocked occupancy |
| 36 | Woden Interchange Wall | Belconnen Town Centre Review | invalid_start | 0.0 | 0.0 | (18.0, 168.0) | Anchor position overlaps collision or blocked occupancy |
| 37 | Russell Causeway Review | Scope Terrace Wall | stuck | 74.8 | 65.1 | (77.9, -3.7) | NPC stuck while approaching waypoint 9 / 11 |
| 38 | Woden Town Centre Review | Bruce Scope Saddle | stuck | 361.3 | 195.3 | (18.0, 23.1) | NPC stuck while approaching waypoint 25 / 54 |
| 41 | City Hill Median | Belconnen Town Centre Review | invalid_start | 0.0 | 0.0 | (38.0, -110.0) | Anchor position overlaps collision or blocked occupancy |
| 43 | East Basin Scope Terrace | Central Basin Screen | stuck | 99.8 | 76.9 | (77.8, 2.0) | NPC stuck while approaching waypoint 5 / 15 |
| 44 | Belconnen Town Centre Review | City Hill Median | invalid_goal | 0.0 | 0.0 | (-141.4, -179.2) | Anchor position overlaps collision or blocked occupancy |
| 45 | City Hill Arterial Review | City Hill Median | invalid_goal | 0.0 | 0.0 | (47.0, -118.0) | Anchor position overlaps collision or blocked occupancy |
| 46 | East Basin Scope Perch | Belconnen Interchange Screen | invalid_goal | 0.0 | 0.0 | (86.0, 8.0) | Anchor position overlaps collision or blocked occupancy |
| 47 | City Hill Median Start | City Hill Median | invalid_start | 0.0 | 0.0 | (38.0, -110.0) | Anchor position overlaps collision or blocked occupancy |
| 48 | East Basin Scope Terrace | Parliament Axis Scope Test | stuck | 114.4 | 76.9 | (77.8, 2.0) | NPC stuck while approaching waypoint 5 / 18 |
| 49 | Belconnen Interchange Screen | Woden Interchange Wall | invalid_start | 0.0 | 0.0 | (-150.0, -202.0) | Anchor position overlaps collision or blocked occupancy |
| 50 | Belconnen Town Centre Review | Woden Interchange Start | invalid_goal | 0.0 | 0.0 | (-141.4, -179.2) | Anchor position overlaps collision or blocked occupancy |
| 51 | Woden Interchange Wall | Belconnen Interchange Screen | invalid_start | 0.0 | 0.0 | (18.0, 168.0) | Anchor position overlaps collision or blocked occupancy |
| 53 | City Hill Arterial Review | Scope Terrace Wall | stuck | 147.8 | 179.9 | (78.0, -3.7) | NPC stuck while approaching waypoint 21 / 23 |
| 54 | Scope Terrace Wall | Russell Bridge Screen | stuck | 78.2 | 30.3 | (78.7, 0.6) | NPC stuck while approaching waypoint 3 / 12 |
| 55 | Belconnen Street Frame Start | City Hill Arterial Review | invalid_start | 0.0 | 0.0 | (-148.0, -186.0) | Anchor position overlaps collision or blocked occupancy |
| 58 | Central Basin Screen | City Hill Median Start | invalid_goal | 0.0 | 0.0 | (20.0, -12.0) | Anchor position overlaps collision or blocked occupancy |
| 59 | Central Basin Screen | East Basin Scope Perch | stuck | 85.4 | 113.5 | (73.2, 2.0) | NPC stuck while approaching waypoint 11 / 13 |
| 60 | City Hill Median Start | Russell Causeway Review | invalid_start | 0.0 | 0.0 | (38.0, -110.0) | Anchor position overlaps collision or blocked occupancy |
| 61 | Black Mountain Saddle Start | East Basin Scope Terrace | stuck | 248.9 | 212.9 | (79.8, -3.9) | NPC stuck while approaching waypoint 26 / 29 |
| 62 | Parliament Axis Start | Belconnen Interchange Screen | invalid_goal | 0.0 | 0.0 | (0.0, 9.0) | Anchor position overlaps collision or blocked occupancy |
| 63 | Woden Town Centre Review | Parliament Axis Scope Test | stuck | 172.1 | 137.4 | (12.0, 85.7) | NPC stuck while approaching waypoint 15 / 29 |
| 64 | Woden Interchange Start | Belconnen Town Centre Review | invalid_start | 0.0 | 0.0 | (18.0, 168.0) | Anchor position overlaps collision or blocked occupancy |
| 65 | Woden Interchange Start | Black Mountain Saddle Start | invalid_start | 0.0 | 0.0 | (18.0, 168.0) | Anchor position overlaps collision or blocked occupancy |
| 66 | City Hill Median Start | Belconnen Interchange Screen | invalid_start | 0.0 | 0.0 | (38.0, -110.0) | Anchor position overlaps collision or blocked occupancy |
| 67 | Russell Causeway Review | Belconnen Street Frame Start | invalid_goal | 0.0 | 0.0 | (118.0, -46.0) | Anchor position overlaps collision or blocked occupancy |
| 68 | Scope Terrace Wall | City Hill Median Start | invalid_goal | 0.0 | 0.0 | (84.0, 6.0) | Anchor position overlaps collision or blocked occupancy |
| 71 | Scope Terrace Wall | Parliament Axis Scope Test | stuck | 100.0 | 60.5 | (77.8, 2.0) | NPC stuck while approaching waypoint 3 / 16 |
| 72 | East Basin Scope Perch | City Hill Arterial Review | stuck | 147.8 | 37.7 | (78.9, 0.5) | NPC stuck while approaching waypoint 3 / 23 |
| 75 | Belconnen Interchange Screen | East Basin Scope Terrace | invalid_start | 0.0 | 0.0 | (-150.0, -202.0) | Anchor position overlaps collision or blocked occupancy |
| 76 | Woden Interchange Wall | City Hill Median Start | invalid_start | 0.0 | 0.0 | (18.0, 168.0) | Anchor position overlaps collision or blocked occupancy |
| 77 | City Hill Median | East Basin Scope Perch | invalid_start | 0.0 | 0.0 | (38.0, -110.0) | Anchor position overlaps collision or blocked occupancy |
| 80 | Bruce Scope Saddle | Scope Terrace Wall | stuck | 238.0 | 242.5 | (78.0, -3.7) | NPC stuck while approaching waypoint 26 / 28 |
| 81 | Woden Interchange Start | East Basin Scope Terrace | invalid_start | 0.0 | 0.0 | (18.0, 168.0) | Anchor position overlaps collision or blocked occupancy |
| 83 | East Basin Scope Terrace | Woden Interchange Start | invalid_goal | 0.0 | 0.0 | (96.0, 14.0) | Anchor position overlaps collision or blocked occupancy |
| 84 | City Hill Median | Russell Bridge Screen | invalid_start | 0.0 | 0.0 | (38.0, -110.0) | Anchor position overlaps collision or blocked occupancy |
| 85 | Scope Terrace Wall | City Hill Median | invalid_goal | 0.0 | 0.0 | (84.0, 6.0) | Anchor position overlaps collision or blocked occupancy |
| 86 | East Basin Scope Perch | Black Mountain Scope Test | stuck | 238.0 | 37.7 | (78.9, 0.5) | NPC stuck while approaching waypoint 3 / 28 |
| 88 | Woden Town Centre Review | City Hill Median | invalid_goal | 0.0 | 0.0 | (21.0, 164.0) | Anchor position overlaps collision or blocked occupancy |
| 91 | Central Basin Screen | Woden Interchange Wall | invalid_goal | 0.0 | 0.0 | (20.0, -12.0) | Anchor position overlaps collision or blocked occupancy |
| 93 | Black Mountain Saddle Start | Scope Terrace Wall | stuck | 238.0 | 242.5 | (78.0, -3.7) | NPC stuck while approaching waypoint 26 / 28 |
| 94 | Parliament Axis Start | City Hill Median Start | invalid_goal | 0.0 | 0.0 | (0.0, 9.0) | Anchor position overlaps collision or blocked occupancy |
| 95 | East Basin Scope Perch | Black Mountain Saddle Start | stuck | 238.0 | 37.7 | (78.9, 0.5) | NPC stuck while approaching waypoint 3 / 28 |
| 97 | Bruce Scope Saddle | Woden Interchange Start | invalid_goal | 0.0 | 0.0 | (-34.0, -148.0) | Anchor position overlaps collision or blocked occupancy |
| 99 | Belconnen Interchange Screen | Bruce Scope Saddle | invalid_start | 0.0 | 0.0 | (-150.0, -202.0) | Anchor position overlaps collision or blocked occupancy |
| 100 | Russell Causeway Start | Scope Terrace Wall | stuck | 83.3 | 74.7 | (77.9, -3.7) | NPC stuck while approaching waypoint 10 / 12 |
| 101 | Woden Interchange Start | Parliament Axis Start | invalid_start | 0.0 | 0.0 | (18.0, 168.0) | Anchor position overlaps collision or blocked occupancy |
| 103 | Russell Bridge Screen | Woden Interchange Wall | invalid_goal | 0.0 | 0.0 | (112.0, -54.0) | Anchor position overlaps collision or blocked occupancy |
| 104 | Woden Interchange Start | Russell Causeway Start | invalid_start | 0.0 | 0.0 | (18.0, 168.0) | Anchor position overlaps collision or blocked occupancy |
| 105 | Russell Causeway Start | Belconnen Street Frame Start | invalid_goal | 0.0 | 0.0 | (127.0, -50.0) | Anchor position overlaps collision or blocked occupancy |
| 107 | Belconnen Town Centre Review | Belconnen Interchange Screen | invalid_goal | 0.0 | 0.0 | (-141.4, -179.2) | Anchor position overlaps collision or blocked occupancy |
| 109 | Black Mountain Saddle Start | East Basin Scope Perch | stuck | 238.0 | 242.5 | (78.0, -3.7) | NPC stuck while approaching waypoint 26 / 28 |
| 110 | Scope Terrace Wall | Belconnen Interchange Screen | invalid_goal | 0.0 | 0.0 | (84.0, 6.0) | Anchor position overlaps collision or blocked occupancy |
| 111 | Belconnen Interchange Screen | Black Mountain Saddle Start | invalid_start | 0.0 | 0.0 | (-150.0, -202.0) | Anchor position overlaps collision or blocked occupancy |
| 115 | Parliament Axis Start | Woden Town Centre Review | stuck | 166.1 | 131.8 | (12.0, 83.3) | NPC stuck while approaching waypoint 14 / 28 |
| 117 | East Basin Scope Perch | Woden Town Centre Review | stuck | 194.9 | 22.0 | (81.5, 22.7) | NPC stuck while approaching waypoint 4 / 28 |
| 118 | Scope Terrace Wall | Russell Causeway Review | stuck | 74.8 | 30.3 | (78.7, 0.6) | NPC stuck while approaching waypoint 3 / 11 |
| 119 | East Basin Scope Perch | Parliament Axis Start | stuck | 100.9 | 16.6 | (77.8, 1.9) | NPC stuck while approaching waypoint 3 / 16 |
| 120 | City Hill Median Start | Russell Bridge Screen | invalid_start | 0.0 | 0.0 | (38.0, -110.0) | Anchor position overlaps collision or blocked occupancy |
| 121 | Scope Terrace Wall | City Hill Arterial Review | stuck | 147.8 | 30.3 | (78.7, 0.6) | NPC stuck while approaching waypoint 3 / 23 |
| 122 | Scope Terrace Wall | Russell Causeway Start | stuck | 83.3 | 30.3 | (78.7, 0.6) | NPC stuck while approaching waypoint 3 / 12 |
| 124 | City Hill Median | City Hill Median Start | invalid_start | 0.0 | 0.0 | (38.0, -110.0) | Anchor position overlaps collision or blocked occupancy |
| 126 | City Hill Median | Parliament Axis Start | invalid_start | 0.0 | 0.0 | (38.0, -110.0) | Anchor position overlaps collision or blocked occupancy |
| 130 | East Basin Scope Terrace | Belconnen Town Centre Review | stuck | 356.5 | 27.9 | (81.9, 0.2) | NPC stuck while approaching waypoint 4 / 42 |
| 131 | City Hill Median Start | Scope Terrace Wall | invalid_start | 0.0 | 0.0 | (38.0, -110.0) | Anchor position overlaps collision or blocked occupancy |
| 135 | Belconnen Town Centre Review | Scope Terrace Wall | stuck | 343.8 | 299.2 | (73.2, -3.2) | NPC stuck while approaching waypoint 38 / 40 |
| 136 | Woden Interchange Start | Belconnen Street Frame Start | invalid_start | 0.0 | 0.0 | (18.0, 168.0) | Anchor position overlaps collision or blocked occupancy |
| 137 | City Hill Arterial Review | East Basin Scope Perch | stuck | 147.8 | 179.9 | (78.0, -3.7) | NPC stuck while approaching waypoint 21 / 23 |
| 138 | Bruce Scope Saddle | Belconnen Interchange Screen | invalid_goal | 0.0 | 0.0 | (-34.0, -148.0) | Anchor position overlaps collision or blocked occupancy |
| 139 | Woden Interchange Start | Woden Interchange Wall | invalid_start | 0.0 | 0.0 | (18.0, 168.0) | Anchor position overlaps collision or blocked occupancy |
| 140 | City Hill Median Start | Parliament Axis Start | invalid_start | 0.0 | 0.0 | (38.0, -110.0) | Anchor position overlaps collision or blocked occupancy |
| 141 | Belconnen Street Frame Start | Russell Bridge Screen | invalid_start | 0.0 | 0.0 | (-148.0, -186.0) | Anchor position overlaps collision or blocked occupancy |
| 142 | Scope Terrace Wall | Parliament Axis Start | stuck | 100.9 | 60.5 | (77.8, 2.0) | NPC stuck while approaching waypoint 3 / 16 |
| 143 | East Basin Scope Perch | Russell Causeway Start | stuck | 83.3 | 37.7 | (78.9, 0.5) | NPC stuck while approaching waypoint 3 / 12 |
| 144 | Belconnen Street Frame Start | Woden Interchange Start | invalid_start | 0.0 | 0.0 | (-148.0, -186.0) | Anchor position overlaps collision or blocked occupancy |
| 145 | Central Basin Screen | Scope Terrace Wall | stuck | 85.4 | 113.5 | (73.2, 2.0) | NPC stuck while approaching waypoint 11 / 13 |
| 148 | Woden Interchange Start | Scope Terrace Wall | invalid_start | 0.0 | 0.0 | (18.0, 168.0) | Anchor position overlaps collision or blocked occupancy |
| 149 | Woden Interchange Wall | Russell Bridge Screen | invalid_start | 0.0 | 0.0 | (18.0, 168.0) | Anchor position overlaps collision or blocked occupancy |
| 151 | Woden Interchange Start | Russell Causeway Review | invalid_start | 0.0 | 0.0 | (18.0, 168.0) | Anchor position overlaps collision or blocked occupancy |
| 152 | Belconnen Interchange Screen | Black Mountain Scope Test | invalid_start | 0.0 | 0.0 | (-150.0, -202.0) | Anchor position overlaps collision or blocked occupancy |
| 153 | Belconnen Interchange Screen | Central Basin Screen | invalid_start | 0.0 | 0.0 | (-150.0, -202.0) | Anchor position overlaps collision or blocked occupancy |
| 155 | Russell Bridge Screen | Scope Terrace Wall | stuck | 78.2 | 116.0 | (78.0, -3.7) | NPC stuck while approaching waypoint 10 / 12 |
| 156 | Parliament Axis Start | Woden Interchange Wall | invalid_goal | 0.0 | 0.0 | (0.0, 9.0) | Anchor position overlaps collision or blocked occupancy |
| 159 | Russell Bridge Screen | Belconnen Interchange Screen | invalid_goal | 0.0 | 0.0 | (112.0, -54.0) | Anchor position overlaps collision or blocked occupancy |
| 161 | Black Mountain Scope Test | Belconnen Interchange Screen | invalid_goal | 0.0 | 0.0 | (-38.9, -145.5) | Anchor position overlaps collision or blocked occupancy |
| 162 | Belconnen Street Frame Start | Woden Interchange Wall | invalid_start | 0.0 | 0.0 | (-148.0, -186.0) | Anchor position overlaps collision or blocked occupancy |
| 163 | Belconnen Town Centre Review | Woden Town Centre Review | stuck | 441.4 | 376.7 | (12.0, 83.3) | NPC stuck while approaching waypoint 45 / 59 |
| 164 | Woden Town Centre Review | Parliament Axis Start | stuck | 166.1 | 137.4 | (12.0, 85.7) | NPC stuck while approaching waypoint 15 / 28 |
| 166 | Parliament Axis Scope Test | City Hill Median Start | invalid_goal | 0.0 | 0.0 | (0.0, 2.0) | Anchor position overlaps collision or blocked occupancy |
| 167 | Belconnen Interchange Screen | Russell Causeway Start | invalid_start | 0.0 | 0.0 | (-150.0, -202.0) | Anchor position overlaps collision or blocked occupancy |
| 169 | Woden Interchange Start | Bruce Scope Saddle | invalid_start | 0.0 | 0.0 | (18.0, 168.0) | Anchor position overlaps collision or blocked occupancy |
| 170 | Woden Interchange Wall | Russell Causeway Start | invalid_start | 0.0 | 0.0 | (18.0, 168.0) | Anchor position overlaps collision or blocked occupancy |
| 171 | Parliament Axis Scope Test | City Hill Median | invalid_goal | 0.0 | 0.0 | (0.0, 2.0) | Anchor position overlaps collision or blocked occupancy |
| 172 | Russell Bridge Screen | City Hill Median | invalid_goal | 0.0 | 0.0 | (112.0, -54.0) | Anchor position overlaps collision or blocked occupancy |
| 173 | Black Mountain Saddle Start | City Hill Median | invalid_goal | 0.0 | 0.0 | (-34.0, -148.0) | Anchor position overlaps collision or blocked occupancy |
| 174 | Parliament Axis Scope Test | Woden Interchange Start | invalid_goal | 0.0 | 0.0 | (0.0, 2.0) | Anchor position overlaps collision or blocked occupancy |
| 175 | City Hill Median | Woden Interchange Start | invalid_start | 0.0 | 0.0 | (38.0, -110.0) | Anchor position overlaps collision or blocked occupancy |
| 176 | City Hill Arterial Review | Belconnen Street Frame Start | invalid_goal | 0.0 | 0.0 | (47.0, -118.0) | Anchor position overlaps collision or blocked occupancy |
| 177 | Belconnen Street Frame Start | East Basin Scope Perch | invalid_start | 0.0 | 0.0 | (-148.0, -186.0) | Anchor position overlaps collision or blocked occupancy |
| 179 | Scope Terrace Wall | Black Mountain Scope Test | stuck | 238.0 | 30.3 | (78.7, 0.6) | NPC stuck while approaching waypoint 3 / 28 |
| 180 | Belconnen Interchange Screen | Parliament Axis Start | invalid_start | 0.0 | 0.0 | (-150.0, -202.0) | Anchor position overlaps collision or blocked occupancy |
| 181 | Parliament Axis Start | East Basin Scope Perch | stuck | 100.9 | 128.7 | (73.2, 2.0) | NPC stuck while approaching waypoint 14 / 16 |
| 182 | Woden Interchange Wall | Central Basin Screen | invalid_start | 0.0 | 0.0 | (18.0, 168.0) | Anchor position overlaps collision or blocked occupancy |
| 183 | Belconnen Interchange Screen | Parliament Axis Scope Test | invalid_start | 0.0 | 0.0 | (-150.0, -202.0) | Anchor position overlaps collision or blocked occupancy |
| 184 | Woden Town Centre Review | Central Basin Screen | stuck | 176.9 | 195.3 | (18.0, 23.1) | NPC stuck while approaching waypoint 25 / 31 |
| 185 | City Hill Median | Woden Interchange Wall | invalid_start | 0.0 | 0.0 | (38.0, -110.0) | Anchor position overlaps collision or blocked occupancy |
| 186 | Scope Terrace Wall | Central Basin Screen | stuck | 85.4 | 60.5 | (77.8, 2.0) | NPC stuck while approaching waypoint 3 / 13 |
| 187 | Parliament Axis Scope Test | Belconnen Interchange Screen | invalid_goal | 0.0 | 0.0 | (0.0, 2.0) | Anchor position overlaps collision or blocked occupancy |
| 188 | Black Mountain Scope Test | East Basin Scope Terrace | stuck | 248.9 | 214.3 | (79.7, -3.9) | NPC stuck while approaching waypoint 26 / 29 |
| 189 | Black Mountain Scope Test | Woden Interchange Start | invalid_goal | 0.0 | 0.0 | (-38.9, -145.5) | Anchor position overlaps collision or blocked occupancy |
| 190 | East Basin Scope Perch | Central Basin Screen | stuck | 85.4 | 16.6 | (77.8, 1.9) | NPC stuck while approaching waypoint 3 / 13 |
| 192 | Woden Interchange Start | Parliament Axis Scope Test | invalid_start | 0.0 | 0.0 | (18.0, 168.0) | Anchor position overlaps collision or blocked occupancy |
| 193 | Woden Interchange Wall | Russell Causeway Review | invalid_start | 0.0 | 0.0 | (18.0, 168.0) | Anchor position overlaps collision or blocked occupancy |
| 195 | Belconnen Street Frame Start | Russell Causeway Start | invalid_start | 0.0 | 0.0 | (-148.0, -186.0) | Anchor position overlaps collision or blocked occupancy |
| 196 | Belconnen Town Centre Review | City Hill Median Start | invalid_goal | 0.0 | 0.0 | (-141.4, -179.2) | Anchor position overlaps collision or blocked occupancy |
| 197 | City Hill Median Start | Central Basin Screen | invalid_start | 0.0 | 0.0 | (38.0, -110.0) | Anchor position overlaps collision or blocked occupancy |
| 198 | Parliament Axis Scope Test | Scope Terrace Wall | stuck | 100.0 | 127.0 | (73.2, 2.0) | NPC stuck while approaching waypoint 14 / 16 |
| 199 | Woden Interchange Wall | Parliament Axis Scope Test | invalid_start | 0.0 | 0.0 | (18.0, 168.0) | Anchor position overlaps collision or blocked occupancy |
| 200 | Russell Bridge Screen | City Hill Median Start | invalid_goal | 0.0 | 0.0 | (112.0, -54.0) | Anchor position overlaps collision or blocked occupancy |
| 201 | East Basin Scope Perch | Woden Interchange Start | invalid_goal | 0.0 | 0.0 | (86.0, 8.0) | Anchor position overlaps collision or blocked occupancy |
| 205 | Black Mountain Saddle Start | Woden Town Centre Review | stuck | 361.3 | 241.4 | (18.0, 20.0) | NPC stuck while approaching waypoint 30 / 54 |
| 206 | Black Mountain Saddle Start | Belconnen Street Frame Start | invalid_goal | 0.0 | 0.0 | (-34.0, -148.0) | Anchor position overlaps collision or blocked occupancy |
| 207 | Bruce Scope Saddle | Woden Interchange Wall | invalid_goal | 0.0 | 0.0 | (-34.0, -148.0) | Anchor position overlaps collision or blocked occupancy |
| 208 | Russell Causeway Review | Belconnen Interchange Screen | invalid_goal | 0.0 | 0.0 | (118.0, -46.0) | Anchor position overlaps collision or blocked occupancy |
| 209 | Central Basin Screen | East Basin Scope Terrace | stuck | 99.8 | 113.5 | (73.2, 2.0) | NPC stuck while approaching waypoint 11 / 15 |
| 210 | City Hill Median | Scope Terrace Wall | invalid_start | 0.0 | 0.0 | (38.0, -110.0) | Anchor position overlaps collision or blocked occupancy |
| 211 | Belconnen Interchange Screen | City Hill Median | invalid_start | 0.0 | 0.0 | (-150.0, -202.0) | Anchor position overlaps collision or blocked occupancy |
| 212 | Scope Terrace Wall | Woden Interchange Wall | invalid_goal | 0.0 | 0.0 | (84.0, 6.0) | Anchor position overlaps collision or blocked occupancy |
| 214 | Black Mountain Scope Test | City Hill Median Start | invalid_goal | 0.0 | 0.0 | (-38.9, -145.5) | Anchor position overlaps collision or blocked occupancy |
| 216 | City Hill Median Start | Russell Causeway Start | invalid_start | 0.0 | 0.0 | (38.0, -110.0) | Anchor position overlaps collision or blocked occupancy |
| 218 | Parliament Axis Start | Woden Interchange Start | invalid_goal | 0.0 | 0.0 | (0.0, 9.0) | Anchor position overlaps collision or blocked occupancy |
| 219 | Belconnen Interchange Screen | Russell Causeway Review | invalid_start | 0.0 | 0.0 | (-150.0, -202.0) | Anchor position overlaps collision or blocked occupancy |
| 222 | Parliament Axis Scope Test | East Basin Scope Terrace | stuck | 114.4 | 127.0 | (73.2, 2.0) | NPC stuck while approaching waypoint 14 / 18 |
| 223 | Bruce Scope Saddle | Woden Town Centre Review | stuck | 361.3 | 241.4 | (18.0, 20.0) | NPC stuck while approaching waypoint 30 / 54 |
| 224 | East Basin Scope Terrace | City Hill Median | invalid_goal | 0.0 | 0.0 | (96.0, 14.0) | Anchor position overlaps collision or blocked occupancy |
| 226 | Bruce Scope Saddle | Belconnen Street Frame Start | invalid_goal | 0.0 | 0.0 | (-34.0, -148.0) | Anchor position overlaps collision or blocked occupancy |
| 228 | Woden Interchange Wall | East Basin Scope Terrace | invalid_start | 0.0 | 0.0 | (18.0, 168.0) | Anchor position overlaps collision or blocked occupancy |
| 229 | Parliament Axis Start | City Hill Median | invalid_goal | 0.0 | 0.0 | (0.0, 9.0) | Anchor position overlaps collision or blocked occupancy |
| 230 | City Hill Median Start | East Basin Scope Terrace | invalid_start | 0.0 | 0.0 | (38.0, -110.0) | Anchor position overlaps collision or blocked occupancy |
| 231 | Belconnen Interchange Screen | City Hill Median Start | invalid_start | 0.0 | 0.0 | (-150.0, -202.0) | Anchor position overlaps collision or blocked occupancy |
| 232 | Woden Interchange Start | City Hill Arterial Review | invalid_start | 0.0 | 0.0 | (18.0, 168.0) | Anchor position overlaps collision or blocked occupancy |
| 233 | Russell Causeway Start | Woden Interchange Start | invalid_goal | 0.0 | 0.0 | (127.0, -50.0) | Anchor position overlaps collision or blocked occupancy |
| 234 | Bruce Scope Saddle | City Hill Median Start | invalid_goal | 0.0 | 0.0 | (-34.0, -148.0) | Anchor position overlaps collision or blocked occupancy |
| 235 | East Basin Scope Perch | Bruce Scope Saddle | stuck | 238.0 | 37.7 | (78.9, 0.5) | NPC stuck while approaching waypoint 3 / 28 |
| 236 | City Hill Median Start | Woden Interchange Start | invalid_start | 0.0 | 0.0 | (38.0, -110.0) | Anchor position overlaps collision or blocked occupancy |
| 237 | Belconnen Street Frame Start | East Basin Scope Terrace | invalid_start | 0.0 | 0.0 | (-148.0, -186.0) | Anchor position overlaps collision or blocked occupancy |
| 238 | Woden Interchange Start | Russell Bridge Screen | invalid_start | 0.0 | 0.0 | (18.0, 168.0) | Anchor position overlaps collision or blocked occupancy |
| 239 | East Basin Scope Terrace | Black Mountain Saddle Start | stuck | 248.9 | 27.9 | (81.9, 0.2) | NPC stuck while approaching waypoint 4 / 29 |
| 240 | Belconnen Town Centre Review | East Basin Scope Terrace | stuck | 356.5 | 303.1 | (78.7, -3.8) | NPC stuck while approaching waypoint 39 / 42 |
| 241 | City Hill Median Start | Bruce Scope Saddle | invalid_start | 0.0 | 0.0 | (38.0, -110.0) | Anchor position overlaps collision or blocked occupancy |
| 242 | Parliament Axis Start | Scope Terrace Wall | stuck | 100.9 | 128.7 | (73.2, 2.0) | NPC stuck while approaching waypoint 14 / 16 |
| 243 | Belconnen Town Centre Review | East Basin Scope Perch | stuck | 343.8 | 299.2 | (73.2, -3.2) | NPC stuck while approaching waypoint 38 / 40 |
| 245 | Belconnen Street Frame Start | Scope Terrace Wall | invalid_start | 0.0 | 0.0 | (-148.0, -186.0) | Anchor position overlaps collision or blocked occupancy |
| 246 | Woden Interchange Start | East Basin Scope Perch | invalid_start | 0.0 | 0.0 | (18.0, 168.0) | Anchor position overlaps collision or blocked occupancy |
| 249 | Belconnen Street Frame Start | Black Mountain Scope Test | invalid_start | 0.0 | 0.0 | (-148.0, -186.0) | Anchor position overlaps collision or blocked occupancy |
| 251 | Woden Interchange Wall | Scope Terrace Wall | invalid_start | 0.0 | 0.0 | (18.0, 168.0) | Anchor position overlaps collision or blocked occupancy |
| 253 | Parliament Axis Scope Test | Belconnen Street Frame Start | invalid_goal | 0.0 | 0.0 | (0.0, 2.0) | Anchor position overlaps collision or blocked occupancy |
| 254 | Woden Town Centre Review | Belconnen Street Frame Start | invalid_goal | 0.0 | 0.0 | (21.0, 164.0) | Anchor position overlaps collision or blocked occupancy |
| 255 | Woden Town Centre Review | Black Mountain Saddle Start | stuck | 361.3 | 195.3 | (18.0, 23.1) | NPC stuck while approaching waypoint 25 / 54 |
| 256 | City Hill Median Start | Woden Interchange Wall | invalid_start | 0.0 | 0.0 | (38.0, -110.0) | Anchor position overlaps collision or blocked occupancy |

## Notes

- The audit used a `6.0m` planning grid with the same ground and collision queries that the live `GameCore` world uses.
- Successful paths only confirm that an NPC can follow the planned route under the current collision and ground setup.
- Every blacklist entry is a real bug candidate to fix in world data, authored anchor placement, or NPC traversal logic. The audit no longer treats these failures as expected.
- The agent movement runs in `GameNPCState` so the audit exercises reusable NPC traversal logic instead of a test-only teleport script.
