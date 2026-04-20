# milsim-pony

Military Simulation Experiment with ChatGPT

There are a bunch of helpful game assets in the MilsimPonyGame/Assets/PrimaryAssets/ directory.

Engine

The game engine is written in METAL, SwiftUI and C with most of the engine existing in a C core. The game is a suburban evasion game based in Canberra, Australia. The game begins at the New Parliament House on top of the large hill with the flag above it.

Before the general game rendering starts it is important to have a relatively detailed view of Canberra, its streets and its general architecture. There are a number of resources online including Google Maps.

The immediate priority is no longer a narrow Parliament House corridor slice. The next development phase must show Canberra at a much larger scale, including Lake Burley Griffin and the broader landscape from Woden to Belconnen at a resolution high enough to support long-range observation and firing.

The first usable weapon in the game will be a sniper rifle with 4x magnification. That requirement drives the map plan: higher-resolution terrain, road, landmark, and collision data; longer sightlines; and stable distant rendering are now first-order priorities rather than polish tasks.

Please keep the cycle plan aligned to this broader Canberra goal until it is fully delivered as a playable and reviewable demo.

Please make sure a Mac Xcode project called:

MilsimPonyGame.xcodeproj

Is created in the main directory to make use of the existing directory structure.
