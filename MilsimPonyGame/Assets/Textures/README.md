# Canberra Texture Sources

This directory stores both the sourced Canberra photographs in `Origin/` and the derived in-game material crops in `Final/`.

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
| `Final/canberra_dry_grass_texture.png` | `lake_burley_griffin_east_basin_source.jpg` | Terrain and mountain surface modulation. |
| `Final/canberra_concrete_texture.png` | `parliament_house_canberra_source.jpg` | Graybox building and retaining-wall surface modulation. |
| `Final/canberra_lake_water_texture.png` | `lake_burley_griffin_east_basin_source.jpg` | Lake basin surface modulation. |

## Processing Notes

- Final textures are photo-derived crops scaled to `1024x1024`.
- Road and concrete textures were desaturated and blurred to read as materials instead of literal scene fragments.
- The terrain and water textures were cropped from Lake Burley Griffin shoreline photography to keep the palette local to Canberra.
