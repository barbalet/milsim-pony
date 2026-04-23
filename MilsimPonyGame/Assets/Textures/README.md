# Canberra Texture Sources

This directory stores both the sourced Canberra photographs in `Origin/` and the derived in-game material crops in `Final/`.

## Cycle 21 Audit Summary

- The shipped renderer material keys are `terrain`, `road`, `concrete`, and `water`.
- Each shipped material key now has both a Canberra source photograph under `Origin/` and a derived runtime texture under `Final/`.
- Remaining texture risk for cycle `21` is no longer missing material slots; it is the quality gap between shared materials and future district-specific facade sources while live contact lanes are active.
- The material-plumbing slice now adds authored `albedo + normal + roughness + AO` sets for Canberra civic facades and arterial asphalt, plus derived normal/roughness/AO companions for the shared Canberra concrete material.

## Source Photographs

| Local file | Upstream page | Author | License | Notes |
| --- | --- | --- | --- | --- |
| `Origin/canberra_bicycle_lane_source.jpg` | <https://commons.wikimedia.org/wiki/File:Canberra_bicycle_lane.jpg> | Tdmalone | CC BY-SA 2.5 | Hindmarsh Drive bicycle lane in Canberra. |
| `Origin/parliament_house_canberra_source.jpg` | <https://commons.wikimedia.org/wiki/File:Parliament_House,_Canberra.jpg> | Bidgee | CC BY-SA 3.0 | Parliament House forecourt panorama in Canberra. |
| `Origin/lake_burley_griffin_east_basin_source.jpg` | <https://commons.wikimedia.org/wiki/File:Lake_Burley_Griffin,_East_Basin_2.JPG> | Grahamec | CC BY-SA 3.0 | Lake Burley Griffin East Basin shoreline view. |

## Final Textures

| Final file | Derived from | Use |
| --- | --- | --- |
| `Final/canberra_asphalt_texture.png` | `canberra_bicycle_lane_source.jpg` | Road-strip albedo modulation. |
| `Final/canberra_arterial_asphalt_albedo.png` | Codex-authored local source | Upgraded Canberra arterial road albedo for road-strip materials. |
| `Final/canberra_arterial_asphalt_normal.png` | Derived from `canberra_arterial_asphalt_albedo.png` | Road normal response. |
| `Final/canberra_arterial_asphalt_roughness.png` | Derived from `canberra_arterial_asphalt_albedo.png` | Road roughness response. |
| `Final/canberra_arterial_asphalt_ao.png` | Derived from `canberra_arterial_asphalt_albedo.png` | Road ambient occlusion response. |
| `Final/canberra_dry_grass_texture.png` | `lake_burley_griffin_east_basin_source.jpg` | Terrain and mountain surface modulation. |
| `Final/canberra_concrete_texture.png` | `parliament_house_canberra_source.jpg` | Graybox building and retaining-wall surface modulation. |
| `Final/canberra_concrete_normal.png` | Derived from `canberra_concrete_texture.png` | Shared concrete normal response. |
| `Final/canberra_concrete_roughness.png` | Derived from `canberra_concrete_texture.png` | Shared concrete roughness response. |
| `Final/canberra_concrete_ao.png` | Derived from `canberra_concrete_texture.png` | Shared concrete ambient occlusion response. |
| `Final/canberra_civic_facade_albedo.png` | Codex-authored local source | Upgraded civic and office facade albedo for Canberra landmark masses. |
| `Final/canberra_civic_facade_normal.png` | Derived from `canberra_civic_facade_albedo.png` | Facade normal response. |
| `Final/canberra_civic_facade_roughness.png` | Derived from `canberra_civic_facade_albedo.png` | Facade roughness response. |
| `Final/canberra_civic_facade_ao.png` | Derived from `canberra_civic_facade_albedo.png` | Facade ambient occlusion response. |
| `Final/canberra_lake_water_texture.png` | `lake_burley_griffin_east_basin_source.jpg` | Lake basin surface modulation. |

## Processing Notes

- Final textures are photo-derived crops scaled to `1024x1024`.
- Road and concrete textures were desaturated and blurred to read as materials instead of literal scene fragments.
- The terrain and water textures were cropped from Lake Burley Griffin shoreline photography to keep the palette local to Canberra.
- The new facade and arterial asphalt albedos were authored locally with Codex image generation, then converted into normal/roughness/AO companions with the bundled runtime pipeline.
