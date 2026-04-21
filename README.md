# milsim-pony

Military Simulation Experiment with ChatGPT

There are a bunch of helpful game assets in the MilsimPonyGame/Assets/PrimaryAssets/ directory.

Engine

The game engine is written in METAL, SwiftUI and C with most of the engine existing in a C core. The game is a Canberra-based first-person prototype, and the live demo must open from a recognisable basin survey position with readable sightlines from Lake Burley Griffin toward Woden and Belconnen.

Before the general game rendering starts it is important to have a relatively detailed view of Canberra, its streets and its general architecture. There are a number of resources online including Google Maps.

The immediate priority is no longer a narrow Parliament House corridor slice. The next development phase must show Canberra at a much larger scale, including Lake Burley Griffin and the broader landscape from Woden to Belconnen at a resolution high enough to support long-range observation and firing.

The first usable weapon in the game will be a sniper rifle with 4x magnification. That requirement drives the map plan: higher-resolution terrain, road, landmark, and collision data; longer sightlines; and stable distant rendering are now first-order priorities rather than polish tasks.

All active development cycles now count as Canberra-modeling cycles. Engine, rendering, and gameplay work are only justified when they unlock, improve, or validate the Woden-to-Belconnen world model.

Cycle timing is no longer assumed to be one week. Treat each cycle as a Canberra coverage gate, budget at least two weeks for basin reference gathering and world-data integration, and hold a third week open whenever new terrain, roads, or landmark imports need another pass before the cycle can be considered complete.

Please keep the cycle plan aligned to this broader Canberra goal until it is fully delivered as a playable and reviewable demo.

Please make sure a Mac Xcode project called:

MilsimPonyGame.xcodeproj

Is created in the main directory to make use of the existing directory structure.
