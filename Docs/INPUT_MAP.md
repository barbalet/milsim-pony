# Cycle 0 Input Map

The bootstrap build is not a full player controller yet. It wires the first responder path, key capture, and mouse delta capture so cycle `1` can move straight into camera and traversal work.

| Input | Action | Cycle 0 Behavior |
| --- | --- | --- |
| `W` | Forward | Updates forward intent in the C core |
| `S` | Backward | Updates backward intent in the C core |
| `A` | Strafe Left | Updates left strafe intent in the C core |
| `D` | Strafe Right | Updates right strafe intent in the C core |
| `Shift` | Sprint | Toggles sprint flag in the C core |
| `Mouse Move` | Look | Feeds yaw and pitch debug deltas into the C core |
| `Space` | Interact | Placeholder event with status feedback |
| `Escape` | Pause | Placeholder event with status feedback |

## Notes

- The `MTKView` becomes first responder when the window activates or the view is clicked.
- Mouse movement is tracked for debug look input, but cursor locking and sensitivity tuning are deferred to cycle `1`.
- Pause and interact are intentionally placeholders so the hooks exist before gameplay logic is added.
