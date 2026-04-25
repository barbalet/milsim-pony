# Input Focus Recovery Smoke Test

Purpose: verify the Metal game view keeps keyboard and mouse control after SwiftUI refreshes, window focus changes, and menu transitions.

1. Launch `MilsimPonyGame` and click inside the rendered scene.
2. Before pressing `Space`, move the mouse over the scene and confirm camera look updates immediately.
3. Before pressing `Space`, hold `W`, `A`, `S`, and `D` in turn and confirm movement responds without needing scope or deploy first.
4. Press `Space`, then confirm the scope/deploy path still works.
5. Confirm the first click captures the game view and the primary fire command is accepted while the route is live.
6. Open and close the Canberra map, then confirm mouse look and movement still work.
7. Open settings, close settings, click the scene once, then confirm mouse look and movement recover.
8. Switch focus to another app and back to the game window, then confirm one click restores primary fire and keyboard movement.
9. Click the mission overlay, control deck, menu shell, and map windows while the game is running, then confirm `W`, `A`, `S`, `D`, `M`, `Esc`, and mouse look recover without relaunching.

Expected result: keyboard and mouse input recover without restarting the app, reopening the scene, or clicking multiple times.
