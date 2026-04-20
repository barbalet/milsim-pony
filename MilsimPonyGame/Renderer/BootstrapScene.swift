import Foundation
import MetalKit
import simd

struct SceneDrawable {
    let name: String
    let vertexBuffer: MTLBuffer
    let vertexCount: Int
    let modelMatrix: simd_float4x4
    let worldCenter: SIMD3<Float>
    let boundingRadius: Float
    let maxDrawDistance: Float
    let minimumViewDot: Float
}

struct SceneEnvironment {
    let skyHorizonColor: SIMD4<Float>
    let skyZenithColor: SIMD4<Float>
    let sunDirection: SIMD3<Float>
    let sunColor: SIMD3<Float>
    let ambientIntensity: Float
    let diffuseIntensity: Float
}

struct SceneDebugInfo {
    let sceneName: String
    let summary: String
    let details: [String]
    let spawn: SpawnConfiguration
}

struct SceneStreamingState {
    let summary: String
    let details: [String]
    let activeDrawableCount: Int
}

struct SceneVisibilityState {
    let drawables: [SceneDrawable]
    let culledCount: Int
}

struct SceneRouteInfo {
    let name: String
    let summary: String
    let checkpoints: [RouteCheckpointConfiguration]
}

struct SceneRouteState {
    let summary: String
    let details: [String]
}

final class BootstrapScene {
    let drawables: [SceneDrawable]
    let debugInfo: SceneDebugInfo
    let environment: SceneEnvironment

    private let sectors: [SceneSectorRuntime]
    private let runtimeWorld: SceneRuntimeWorld
    private let alwaysLoadedIndices: [Int]
    private let routeInfo: SceneRouteInfo

    init(device: MTLDevice, assetRoot: String, worldDataRoot: String, worldManifestPath: String) {
        let manifestURL = URL(fileURLWithPath: worldManifestPath)

        do {
            let buildResult = try ScenePackageBuilder(
                device: device,
                assetRoot: assetRoot,
                worldDataRoot: worldDataRoot
            ).buildScene(from: manifestURL)

            drawables = buildResult.drawables
            debugInfo = buildResult.debugInfo
            environment = buildResult.environment
            sectors = buildResult.sectors
            runtimeWorld = buildResult.runtimeWorld
            alwaysLoadedIndices = buildResult.alwaysLoadedIndices
            routeInfo = buildResult.routeInfo
        } catch {
            let fallbackResult = FallbackSceneFactory.build(
                device: device,
                worldDataRoot: worldDataRoot,
                worldManifestPath: worldManifestPath,
                errorDescription: error.localizedDescription
            )

            drawables = fallbackResult.drawables
            debugInfo = fallbackResult.debugInfo
            environment = fallbackResult.environment
            sectors = fallbackResult.sectors
            runtimeWorld = fallbackResult.runtimeWorld
            alwaysLoadedIndices = fallbackResult.alwaysLoadedIndices
            routeInfo = fallbackResult.routeInfo
            print("[Scene] Falling back to procedural scene: \(error)")
        }
    }

    func configureGameCore() {
        runtimeWorld.sectorBounds.withUnsafeBufferPointer { sectorBounds in
            runtimeWorld.collisionVolumes.withUnsafeBufferPointer { collisionVolumes in
                runtimeWorld.groundSurfaces.withUnsafeBufferPointer { groundSurfaces in
                    GameCoreConfigureWorld(
                        sectorBounds.baseAddress,
                        Int32(sectorBounds.count),
                        collisionVolumes.baseAddress,
                        Int32(collisionVolumes.count),
                        groundSurfaces.baseAddress,
                        Int32(groundSurfaces.count)
                    )
                }
            }
        }

        runtimeWorld.routeCheckpoints.withUnsafeBufferPointer { routeCheckpoints in
            GameCoreConfigureRoute(routeCheckpoints.baseAddress, Int32(routeCheckpoints.count))
        }
    }

    func visibilityState(for cameraPosition: SIMD3<Float>, forwardVector: SIMD3<Float>) -> SceneVisibilityState {
        let drawIndices = alwaysLoadedIndices + streamedDrawIndices(for: cameraPosition)
        var visibleDrawables: [SceneDrawable] = []
        var culledCount = 0

        for drawIndex in drawIndices {
            let drawable = drawables[drawIndex]
            let offset = drawable.worldCenter - cameraPosition
            let distance = simd_length(offset)

            if distance - drawable.boundingRadius > drawable.maxDrawDistance {
                culledCount += 1
                continue
            }

            if distance > 18, drawable.minimumViewDot > -1, simd_length_squared(offset) > 0.001 {
                let viewDirection = simd_normalize(offset)
                if simd_dot(viewDirection, forwardVector) < drawable.minimumViewDot {
                    culledCount += 1
                    continue
                }
            }

            visibleDrawables.append(drawable)
        }

        return SceneVisibilityState(drawables: visibleDrawables, culledCount: culledCount)
    }

    func streamingState(
        for cameraPosition: SIMD3<Float>,
        visibleDrawableCount: Int,
        culledCount: Int
    ) -> SceneStreamingState {
        let activeIndices = activeSectorIndices(for: cameraPosition)
        let activeSectors = activeIndices.map { sectors[$0] }
        let activeNames = activeSectors.map(\.displayName)
        let currentSector = sectors.first(where: { $0.contains(cameraPosition) })?.displayName ?? "Outside district bounds"
        let streamedDrawableCount = activeSectors.reduce(0) { $0 + $1.drawableRange.count }

        return SceneStreamingState(
            summary: "Chunks: \(activeSectors.count) active / \(sectors.count) total",
            details: [
                "Active: \(activeNames.isEmpty ? "Fallback load" : activeNames.joined(separator: ", "))",
                "Current Sector: \(currentSector)",
                "Visibility: \(visibleDrawableCount) drawn / \(culledCount) culled",
            ],
            activeDrawableCount: alwaysLoadedIndices.count + streamedDrawableCount
        )
    }

    func routeState(for snapshot: GameFrameSnapshot) -> SceneRouteState {
        guard !routeInfo.checkpoints.isEmpty else {
            return SceneRouteState(summary: "Route: unavailable", details: [])
        }

        if snapshot.routeComplete {
            return SceneRouteState(
                summary: "Route: \(routeInfo.name) complete",
                details: [
                    "Goal: \(routeInfo.checkpoints.last?.label ?? "Escape corridor exit")",
                    String(
                        format: "Run: %.1fs / %.0fm / %d restarts",
                        snapshot.elapsedSeconds,
                        snapshot.routeDistanceMeters,
                        snapshot.restartCount
                    ),
                ]
            )
        }

        let nextIndex = min(Int(snapshot.completedCheckpointCount), max(routeInfo.checkpoints.count - 1, 0))
        let nextCheckpoint = routeInfo.checkpoints[nextIndex]
        return SceneRouteState(
            summary: "Route: \(snapshot.completedCheckpointCount) / \(snapshot.totalCheckpointCount) checkpoints",
            details: [
                "Objective: \(routeInfo.summary)",
                String(
                    format: "Next: %@ (%.1fm)",
                    nextCheckpoint.label,
                    snapshot.distanceToNextCheckpointMeters
                ),
                String(
                    format: "Run: %.1fs / %.0fm / %d restarts",
                    snapshot.elapsedSeconds,
                    snapshot.routeDistanceMeters,
                    snapshot.restartCount
                ),
            ]
        )
    }

    private func activeSectorIndices(for cameraPosition: SIMD3<Float>) -> [Int] {
        let active = sectors.enumerated().compactMap { index, sector in
            sector.isActive(for: cameraPosition) ? index : nil
        }

        guard !active.isEmpty else {
            guard let nearest = sectors.enumerated().min(by: { $0.element.distanceSquared(to: cameraPosition) < $1.element.distanceSquared(to: cameraPosition) }) else {
                return []
            }
            return [nearest.offset]
        }

        return active
    }

    private func streamedDrawIndices(for cameraPosition: SIMD3<Float>) -> [Int] {
        let activeIndices = Set(activeSectorIndices(for: cameraPosition))
        return sectors.enumerated().flatMap { index, sector in
            activeIndices.contains(index) ? Array(sector.drawableRange) : []
        }
    }
}

private struct SceneBuildResult {
    let drawables: [SceneDrawable]
    let debugInfo: SceneDebugInfo
    let environment: SceneEnvironment
    let sectors: [SceneSectorRuntime]
    let runtimeWorld: SceneRuntimeWorld
    let alwaysLoadedIndices: [Int]
    let routeInfo: SceneRouteInfo
}

private struct SceneRuntimeWorld {
    let sectorBounds: [GameSectorBounds]
    let collisionVolumes: [GameCollisionVolume]
    let groundSurfaces: [GameGroundSurface]
    let routeCheckpoints: [GameRouteCheckpoint]
}

private struct SceneSectorRuntime {
    let id: String
    let displayName: String
    let minimum: SIMD3<Float>
    let maximum: SIMD3<Float>
    let activationPadding: Float
    let drawableRange: Range<Int>

    func contains(_ point: SIMD3<Float>) -> Bool {
        point.x >= minimum.x && point.x <= maximum.x && point.z >= minimum.z && point.z <= maximum.z
    }

    func isActive(for point: SIMD3<Float>) -> Bool {
        point.x >= (minimum.x - activationPadding) &&
            point.x <= (maximum.x + activationPadding) &&
            point.z >= (minimum.z - activationPadding) &&
            point.z <= (maximum.z + activationPadding)
    }

    func distanceSquared(to point: SIMD3<Float>) -> Float {
        let clampedX = min(max(point.x, minimum.x), maximum.x)
        let clampedZ = min(max(point.z, minimum.z), maximum.z)
        let dx = point.x - clampedX
        let dz = point.z - clampedZ
        return (dx * dx) + (dz * dz)
    }
}

private final class ScenePackageBuilder {
    private let device: MTLDevice
    private let assetRoot: String
    private let worldDataRoot: String
    private var assetCache: [String: LoadedAsset] = [:]

    init(device: MTLDevice, assetRoot: String, worldDataRoot: String) {
        self.device = device
        self.assetRoot = assetRoot
        self.worldDataRoot = worldDataRoot
    }

    func buildScene(from manifestURL: URL) throws -> SceneBuildResult {
        let manifest = try loadJSON(WorldManifest.self, at: manifestURL)
        let packageRootURL = manifestURL.deletingLastPathComponent()
        let coordinateSystem = try loadJSON(
            CoordinateSystemConfiguration.self,
            at: packageRootURL.appendingPathComponent(manifest.coordinateSystemFile)
        )
        let sceneConfiguration = try loadJSON(
            SceneConfiguration.self,
            at: packageRootURL.appendingPathComponent(manifest.sceneFile)
        )

        let sectorLookup = try buildSectorLookup(
            relativePaths: manifest.sectorFiles,
            packageRootURL: packageRootURL
        )

        var sceneDrawables: [SceneDrawable] = []
        var alwaysLoadedIndices: [Int] = []
        var sceneSectors: [SceneSectorRuntime] = []
        var worldSectors: [GameSectorBounds] = []
        var worldCollisionVolumes: [GameCollisionVolume] = []
        var worldGroundSurfaces: [GameGroundSurface] = []
        var worldRouteCheckpoints: [GameRouteCheckpoint] = []
        var proceduralCount = 0
        var assetCount = 0
        var terrainCount = 0
        var roadCount = 0
        var grayboxCount = 0
        var collisionCount = 0
        var routeMarkerCount = 0

        for element in sceneConfiguration.proceduralElements {
            if let drawable = proceduralDrawable(from: element) {
                alwaysLoadedIndices.append(sceneDrawables.count)
                sceneDrawables.append(drawable)
                proceduralCount += 1
            }
        }

        for assetInstance in sceneConfiguration.assetInstances {
            if let drawable = assetDrawable(from: assetInstance) {
                alwaysLoadedIndices.append(sceneDrawables.count)
                sceneDrawables.append(drawable)
                assetCount += 1
            }
        }

        for checkpoint in sceneConfiguration.route.checkpoints {
            worldRouteCheckpoints.append(routeCheckpoint(from: checkpoint))
            for markerDrawable in routeMarkerDrawables(from: checkpoint) {
                alwaysLoadedIndices.append(sceneDrawables.count)
                sceneDrawables.append(markerDrawable)
                routeMarkerCount += 1
            }
        }

        let includedSectorIDs = sceneConfiguration.includedSectors.isEmpty
            ? Array(sectorLookup.keys).sorted()
            : sceneConfiguration.includedSectors

        let loadedSectors = includedSectorIDs.compactMap { sectorLookup[$0] }
        for sector in loadedSectors {
            let minimum = sector.bounds.minimum
            let maximum = sector.bounds.maximum
            let activationPadding = sector.streamingPadding ?? 10
            let drawStart = sceneDrawables.count

            worldSectors.append(
                GameSectorBounds(
                    minX: minimum.x,
                    minZ: minimum.z,
                    maxX: maximum.x,
                    maxZ: maximum.z,
                    activationPadding: activationPadding
                )
            )

            for terrainPatch in sector.terrainPatches {
                if let drawable = terrainDrawable(from: terrainPatch, sectorID: sector.id) {
                    sceneDrawables.append(drawable)
                    terrainCount += 1
                }
                worldGroundSurfaces.append(groundSurface(from: terrainPatch))
            }

            for roadStrip in sector.roadStrips {
                if let drawable = roadDrawable(from: roadStrip, sectorID: sector.id) {
                    sceneDrawables.append(drawable)
                    roadCount += 1
                }
                worldGroundSurfaces.append(groundSurface(from: roadStrip))
            }

            for block in sector.grayboxBlocks {
                if let drawable = grayboxDrawable(from: block, sectorID: sector.id) {
                    sceneDrawables.append(drawable)
                    grayboxCount += 1
                }
                if let shadowDrawable = grayboxShadowDrawable(from: block, sectorID: sector.id) {
                    sceneDrawables.append(shadowDrawable)
                }
                if block.collisionEnabled ?? true {
                    worldCollisionVolumes.append(collisionVolume(from: block))
                    collisionCount += 1
                }
            }

            for volume in sector.collisionVolumes {
                worldCollisionVolumes.append(collisionVolume(from: volume))
                collisionCount += 1
            }

            sceneSectors.append(
                SceneSectorRuntime(
                    id: sector.id,
                    displayName: sector.displayName,
                    minimum: minimum,
                    maximum: maximum,
                    activationPadding: activationPadding,
                    drawableRange: drawStart..<sceneDrawables.count
                )
            )
        }

        let detailLines = [
            "Grid: \(coordinateSystem.name)",
            "Axes: x \(coordinateSystem.axisX) / z \(coordinateSystem.axisZ)",
            "Spawn: \(sceneConfiguration.spawn.label ?? "District start")",
            "Sectors: \(loadedSectors.map(\.displayName).joined(separator: ", "))",
            "District: \(terrainCount) terrain / \(roadCount) roads / \(collisionCount) blockers",
            "Route: \(sceneConfiguration.route.name) / \(sceneConfiguration.route.checkpoints.count) checkpoints",
            "Data Root: \(URL(fileURLWithPath: worldDataRoot).lastPathComponent)",
        ]

        let summary = "\(assetCount) assets, \(terrainCount) terrain, \(roadCount) roads, \(grayboxCount) structures, \(routeMarkerCount) route markers"

        return SceneBuildResult(
            drawables: sceneDrawables,
            debugInfo: SceneDebugInfo(
                sceneName: sceneConfiguration.sceneName,
                summary: summary,
                details: detailLines,
                spawn: sceneConfiguration.spawn
            ),
            environment: SceneEnvironment(
                skyHorizonColor: sceneConfiguration.sky.horizonColorVector,
                skyZenithColor: sceneConfiguration.sky.zenithColorVector,
                sunDirection: sceneConfiguration.sun.directionVector,
                sunColor: sceneConfiguration.sun.colorVector,
                ambientIntensity: sceneConfiguration.sun.ambientIntensity,
                diffuseIntensity: sceneConfiguration.sun.diffuseIntensity
            ),
            sectors: sceneSectors,
            runtimeWorld: SceneRuntimeWorld(
                sectorBounds: worldSectors,
                collisionVolumes: worldCollisionVolumes,
                groundSurfaces: worldGroundSurfaces,
                routeCheckpoints: worldRouteCheckpoints
            ),
            alwaysLoadedIndices: alwaysLoadedIndices,
            routeInfo: SceneRouteInfo(
                name: sceneConfiguration.route.name,
                summary: sceneConfiguration.route.summary,
                checkpoints: sceneConfiguration.route.checkpoints
            )
        )
    }

    private func buildSectorLookup(
        relativePaths: [String],
        packageRootURL: URL
    ) throws -> [String: SectorConfiguration] {
        var sectors: [String: SectorConfiguration] = [:]

        for relativePath in relativePaths {
            let sector = try loadJSON(SectorConfiguration.self, at: packageRootURL.appendingPathComponent(relativePath))
            sectors[sector.id] = sector
        }

        return sectors
    }

    private func proceduralDrawable(from configuration: ProceduralElementConfiguration) -> SceneDrawable? {
        switch configuration.kind {
        case .checkerboard:
            let vertices = GeometryBuilder.makeCheckerboard(
                size: configuration.size ?? 16,
                tileSize: configuration.tileSize ?? 1.2,
                colorA: configuration.checkerColorA,
                colorB: configuration.checkerColorB
            )

            guard let buffer = makeBuffer(from: vertices) else {
                return nil
            }

            return SceneDrawable(
                name: configuration.name,
                vertexBuffer: buffer,
                vertexCount: vertices.count,
                modelMatrix: simd_float4x4.translation(configuration.positionVector),
                worldCenter: configuration.positionVector,
                boundingRadius: max(Float(configuration.size ?? 16) * (configuration.tileSize ?? 1.2) * 0.75, 8),
                maxDrawDistance: 140,
                minimumViewDot: -1
            )

        case .box:
            let vertices = GeometryBuilder.makeBox(
                halfExtents: configuration.halfExtentsVector,
                color: configuration.colorVector
            )

            guard let buffer = makeBuffer(from: vertices) else {
                return nil
            }

            let rotation = simd_float4x4.rotation(y: (configuration.yawDegrees ?? 0) * (.pi / 180.0))
            return SceneDrawable(
                name: configuration.name,
                vertexBuffer: buffer,
                vertexCount: vertices.count,
                modelMatrix: simd_float4x4.translation(configuration.positionVector) * rotation,
                worldCenter: configuration.positionVector,
                boundingRadius: simd_length(configuration.halfExtentsVector),
                maxDrawDistance: 120,
                minimumViewDot: -0.65
            )
        }
    }

    private func grayboxDrawable(from configuration: GrayboxBlockConfiguration, sectorID: String) -> SceneDrawable? {
        let vertices = GeometryBuilder.makeBox(
            halfExtents: configuration.halfExtentsVector,
            color: configuration.colorVector
        )

        guard let buffer = makeBuffer(from: vertices) else {
            return nil
        }

        let rotation = simd_float4x4.rotation(y: (configuration.yawDegrees ?? 0) * (.pi / 180.0))
        return SceneDrawable(
            name: "\(sectorID):\(configuration.name)",
            vertexBuffer: buffer,
            vertexCount: vertices.count,
            modelMatrix: simd_float4x4.translation(configuration.positionVector) * rotation,
            worldCenter: configuration.positionVector,
            boundingRadius: simd_length(configuration.halfExtentsVector),
            maxDrawDistance: 130,
            minimumViewDot: -0.55
        )
    }

    private func grayboxShadowDrawable(from configuration: GrayboxBlockConfiguration, sectorID: String) -> SceneDrawable? {
        let shadowVertices = GeometryBuilder.makeShadowQuad(
            halfExtents: SIMD2<Float>(
                max(configuration.halfExtentsVector.x * 1.08, 0.6),
                max(configuration.halfExtentsVector.z * 1.08, 0.6)
            ),
            color: SIMD4<Float>(0.03, 0.04, 0.05, 0.18)
        )

        guard let buffer = makeBuffer(from: shadowVertices) else {
            return nil
        }

        let baseY = configuration.positionVector.y - configuration.halfExtentsVector.y + 0.03
        let rotation = simd_float4x4.rotation(y: (configuration.yawDegrees ?? 0) * (.pi / 180.0))
        return SceneDrawable(
            name: "\(sectorID):\(configuration.name):Shadow",
            vertexBuffer: buffer,
            vertexCount: shadowVertices.count,
            modelMatrix: simd_float4x4.translation(SIMD3<Float>(configuration.positionVector.x, baseY, configuration.positionVector.z)) * rotation,
            worldCenter: SIMD3<Float>(configuration.positionVector.x, baseY, configuration.positionVector.z),
            boundingRadius: max(configuration.halfExtentsVector.x, configuration.halfExtentsVector.z) * 1.2,
            maxDrawDistance: 110,
            minimumViewDot: -0.7
        )
    }

    private func terrainDrawable(from configuration: TerrainPatchConfiguration, sectorID: String) -> SceneDrawable? {
        let vertices = GeometryBuilder.makeTerrainPatch(
            size: configuration.sizeVector,
            cornerHeights: configuration.cornerHeightVector,
            subdivisions: configuration.subdivisions ?? 10,
            color: configuration.colorVector
        )

        guard let buffer = makeBuffer(from: vertices) else {
            return nil
        }

        let rotation = simd_float4x4.rotation(y: (configuration.yawDegrees ?? 0) * (.pi / 180.0))
        return SceneDrawable(
            name: "\(sectorID):\(configuration.name)",
            vertexBuffer: buffer,
            vertexCount: vertices.count,
            modelMatrix: simd_float4x4.translation(configuration.positionVector) * rotation,
            worldCenter: configuration.positionVector,
            boundingRadius: simd_length(SIMD3<Float>(configuration.sizeVector.x * 0.5, 1.8, configuration.sizeVector.y * 0.5)),
            maxDrawDistance: 180,
            minimumViewDot: -1
        )
    }

    private func roadDrawable(from configuration: RoadStripConfiguration, sectorID: String) -> SceneDrawable? {
        let vertices = GeometryBuilder.makeRoadStrip(
            size: configuration.sizeVector,
            shoulderWidth: configuration.shoulderWidth ?? 1.2,
            centerLineWidth: configuration.centerLineWidth ?? 0.24,
            roadColor: configuration.roadColorVector,
            shoulderColor: configuration.shoulderColorVector,
            lineColor: configuration.lineColorVector,
            crownHeight: configuration.crownHeight ?? 0.04
        )

        guard let buffer = makeBuffer(from: vertices) else {
            return nil
        }

        let rotation = simd_float4x4.rotation(y: (configuration.yawDegrees ?? 0) * (.pi / 180.0))
        return SceneDrawable(
            name: "\(sectorID):\(configuration.name)",
            vertexBuffer: buffer,
            vertexCount: vertices.count,
            modelMatrix: simd_float4x4.translation(configuration.positionVector) * rotation,
            worldCenter: configuration.positionVector,
            boundingRadius: simd_length(SIMD3<Float>(configuration.sizeVector.x * 0.5, 0.5, configuration.sizeVector.y * 0.5)),
            maxDrawDistance: 175,
            minimumViewDot: -1
        )
    }

    private func assetDrawable(from configuration: AssetInstanceConfiguration) -> SceneDrawable? {
        let cacheKey = "\(configuration.category)/\(configuration.name)"
        let loadedAsset: LoadedAsset

        if let cachedAsset = assetCache[cacheKey] {
            loadedAsset = cachedAsset
        } else if let parsedAsset = OBJAssetLoader.loadAsset(
            named: configuration.name,
            category: configuration.category,
            assetRoot: assetRoot
        ) {
            assetCache[cacheKey] = parsedAsset
            loadedAsset = parsedAsset
        } else {
            return nil
        }

        guard let buffer = makeBuffer(from: loadedAsset.vertices) else {
            return nil
        }

        let maxExtent = max(loadedAsset.extent.x, max(loadedAsset.extent.y, loadedAsset.extent.z))
        let scale = max(configuration.targetExtent, 0.001) / max(maxExtent, 0.001)
        let normalization = simd_float4x4.scale(SIMD3<Float>(repeating: scale)) * simd_float4x4.translation(
            SIMD3<Float>(
                -loadedAsset.center.x,
                -loadedAsset.boundsMin.y,
                -loadedAsset.center.z
            )
        )
        let rotation = simd_float4x4.rotation(y: (configuration.yawDegrees ?? 0) * (.pi / 180.0))
        let worldExtent = loadedAsset.extent * scale
        let worldCenter = configuration.positionVector + SIMD3<Float>(0, worldExtent.y * 0.5, 0)

        return SceneDrawable(
            name: configuration.name,
            vertexBuffer: buffer,
            vertexCount: loadedAsset.vertices.count,
            modelMatrix: simd_float4x4.translation(configuration.positionVector) * rotation * normalization,
            worldCenter: worldCenter,
            boundingRadius: simd_length(worldExtent) * 0.5,
            maxDrawDistance: 90,
            minimumViewDot: -0.45
        )
    }

    private func routeMarkerDrawables(from configuration: RouteCheckpointConfiguration) -> [SceneDrawable] {
        let beaconHeight = configuration.beaconHeight ?? ((configuration.goal ?? false) ? 6.0 : 4.8)
        let beaconColor = configuration.beaconColorVector
        let markerPosition = configuration.positionVector
        var drawables: [SceneDrawable] = []

        let columnVertices = GeometryBuilder.makeBox(
            halfExtents: SIMD3<Float>(0.28, beaconHeight * 0.5, 0.28),
            color: beaconColor
        )

        if let columnBuffer = makeBuffer(from: columnVertices) {
            drawables.append(
                SceneDrawable(
                    name: "RouteBeacon:\(configuration.id)",
                    vertexBuffer: columnBuffer,
                    vertexCount: columnVertices.count,
                    modelMatrix: simd_float4x4.translation(markerPosition + SIMD3<Float>(0, beaconHeight * 0.5, 0)),
                    worldCenter: markerPosition + SIMD3<Float>(0, beaconHeight * 0.5, 0),
                    boundingRadius: beaconHeight * 0.6,
                    maxDrawDistance: configuration.goal ?? false ? 240 : 170,
                    minimumViewDot: -0.92
                )
            )
        }

        let capVertices = GeometryBuilder.makeBox(
            halfExtents: SIMD3<Float>((configuration.goal ?? false) ? 2.4 : 1.4, 0.08, 0.08),
            color: beaconColor
        )

        if let capBuffer = makeBuffer(from: capVertices) {
            drawables.append(
                SceneDrawable(
                    name: "RouteCap:\(configuration.id)",
                    vertexBuffer: capBuffer,
                    vertexCount: capVertices.count,
                    modelMatrix: simd_float4x4.translation(markerPosition + SIMD3<Float>(0, beaconHeight, 0)),
                    worldCenter: markerPosition + SIMD3<Float>(0, beaconHeight, 0),
                    boundingRadius: configuration.goal ?? false ? 2.8 : 1.8,
                    maxDrawDistance: configuration.goal ?? false ? 240 : 170,
                    minimumViewDot: -0.92
                )
            )
        }

        let shadowVertices = GeometryBuilder.makeShadowQuad(
            halfExtents: SIMD2<Float>((configuration.goal ?? false) ? 2.4 : 1.4, (configuration.goal ?? false) ? 2.4 : 1.4),
            color: SIMD4<Float>(0.03, 0.04, 0.05, configuration.goal ?? false ? 0.24 : 0.18)
        )

        if let shadowBuffer = makeBuffer(from: shadowVertices) {
            drawables.append(
                SceneDrawable(
                    name: "RouteShadow:\(configuration.id)",
                    vertexBuffer: shadowBuffer,
                    vertexCount: shadowVertices.count,
                    modelMatrix: simd_float4x4.translation(markerPosition + SIMD3<Float>(0, 0.03, 0)),
                    worldCenter: markerPosition,
                    boundingRadius: configuration.goal ?? false ? 2.6 : 1.6,
                    maxDrawDistance: configuration.goal ?? false ? 140 : 100,
                    minimumViewDot: -0.85
                )
            )
        }

        return drawables
    }

    private func makeBuffer(from vertices: [SceneVertex]) -> MTLBuffer? {
        device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<SceneVertex>.stride * vertices.count
        )
    }

    private func groundSurface(from configuration: TerrainPatchConfiguration) -> GameGroundSurface {
        let cornerHeights = configuration.cornerHeightVector
        return GameGroundSurface(
            centerX: configuration.positionVector.x,
            centerZ: configuration.positionVector.z,
            halfWidth: configuration.sizeVector.x * 0.5,
            halfDepth: configuration.sizeVector.y * 0.5,
            yawDegrees: configuration.yawDegrees ?? 0,
            northWestHeight: configuration.positionVector.y + cornerHeights.x,
            northEastHeight: configuration.positionVector.y + cornerHeights.y,
            southEastHeight: configuration.positionVector.y + cornerHeights.z,
            southWestHeight: configuration.positionVector.y + cornerHeights.w
        )
    }

    private func groundSurface(from configuration: RoadStripConfiguration) -> GameGroundSurface {
        let elevation = configuration.positionVector.y
        return GameGroundSurface(
            centerX: configuration.positionVector.x,
            centerZ: configuration.positionVector.z,
            halfWidth: configuration.sizeVector.x * 0.5,
            halfDepth: configuration.sizeVector.y * 0.5,
            yawDegrees: configuration.yawDegrees ?? 0,
            northWestHeight: elevation,
            northEastHeight: elevation,
            southEastHeight: elevation,
            southWestHeight: elevation
        )
    }

    private func collisionVolume(from configuration: GrayboxBlockConfiguration) -> GameCollisionVolume {
        GameCollisionVolume(
            centerX: configuration.positionVector.x,
            centerY: configuration.positionVector.y,
            centerZ: configuration.positionVector.z,
            halfWidth: configuration.halfExtentsVector.x,
            halfHeight: configuration.halfExtentsVector.y,
            halfDepth: configuration.halfExtentsVector.z,
            yawDegrees: configuration.yawDegrees ?? 0
        )
    }

    private func collisionVolume(from configuration: CollisionVolumeConfiguration) -> GameCollisionVolume {
        GameCollisionVolume(
            centerX: configuration.positionVector.x,
            centerY: configuration.positionVector.y,
            centerZ: configuration.positionVector.z,
            halfWidth: configuration.halfExtentsVector.x,
            halfHeight: configuration.halfExtentsVector.y,
            halfDepth: configuration.halfExtentsVector.z,
            yawDegrees: configuration.yawDegrees ?? 0
        )
    }

    private func routeCheckpoint(from configuration: RouteCheckpointConfiguration) -> GameRouteCheckpoint {
        GameRouteCheckpoint(
            positionX: configuration.positionVector.x,
            positionY: configuration.positionVector.y + 1.65,
            positionZ: configuration.positionVector.z,
            triggerRadius: configuration.triggerRadius,
            yawDegrees: configuration.yawDegrees ?? 0,
            pitchDegrees: configuration.pitchDegrees ?? -12,
            isGoal: configuration.goal ?? false
        )
    }

    private func loadJSON<T: Decodable>(_ type: T.Type, at url: URL) throws -> T {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

private enum FallbackSceneFactory {
    static func build(
        device: MTLDevice,
        worldDataRoot: String,
        worldManifestPath: String,
        errorDescription: String
    ) -> SceneBuildResult {
        let vertices = GeometryBuilder.makeCheckerboard(
            size: 18,
            tileSize: 1.4,
            colorA: SIMD4<Float>(0.18, 0.22, 0.26, 1),
            colorB: SIMD4<Float>(0.24, 0.29, 0.34, 1)
        )
        let groundBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<SceneVertex>.stride * vertices.count
        )

        let drawables = groundBuffer.map {
            [
                SceneDrawable(
                    name: "FallbackGround",
                    vertexBuffer: $0,
                    vertexCount: vertices.count,
                    modelMatrix: .identity(),
                    worldCenter: .zero,
                    boundingRadius: 20,
                    maxDrawDistance: 120,
                    minimumViewDot: -1
                )
            ]
        } ?? []

        return SceneBuildResult(
            drawables: drawables,
            debugInfo: SceneDebugInfo(
                sceneName: "Fallback Data Slice",
                summary: "Fallback procedural scene",
                details: [
                    "Grid: data unavailable",
                    "Manifest: \(URL(fileURLWithPath: worldManifestPath).lastPathComponent)",
                    "Data Root: \(URL(fileURLWithPath: worldDataRoot).lastPathComponent)",
                    "Error: \(errorDescription)",
                ],
                spawn: SpawnConfiguration(
                    label: "Fallback start",
                    position: [0, 1.65, 6],
                    yawDegrees: 0,
                    pitchDegrees: -10
                )
            ),
            environment: SceneEnvironment(
                skyHorizonColor: SIMD4<Float>(0.52, 0.66, 0.82, 1),
                skyZenithColor: SIMD4<Float>(0.18, 0.29, 0.46, 1),
                sunDirection: SIMD3<Float>(-0.45, -1.0, -0.25),
                sunColor: SIMD3<Float>(1.0, 0.93, 0.84),
                ambientIntensity: 0.34,
                diffuseIntensity: 0.78
            ),
            sectors: [],
            runtimeWorld: SceneRuntimeWorld(
                sectorBounds: [],
                collisionVolumes: [],
                groundSurfaces: [],
                routeCheckpoints: []
            ),
            alwaysLoadedIndices: Array(drawables.indices),
            routeInfo: SceneRouteInfo(
                name: "Fallback Route",
                summary: "Route data unavailable",
                checkpoints: []
            )
        )
    }
}

private struct LoadedAsset {
    let vertices: [SceneVertex]
    let boundsMin: SIMD3<Float>
    let boundsMax: SIMD3<Float>

    var center: SIMD3<Float> {
        (boundsMin + boundsMax) * 0.5
    }

    var extent: SIMD3<Float> {
        boundsMax - boundsMin
    }
}

private enum GeometryBuilder {
    static func makeCheckerboard(
        size: Int,
        tileSize: Float,
        colorA: SIMD4<Float>,
        colorB: SIMD4<Float>
    ) -> [SceneVertex] {
        var vertices: [SceneVertex] = []
        let half = Float(size) * tileSize * 0.5

        for row in 0..<size {
            for column in 0..<size {
                let x0 = -half + (Float(column) * tileSize)
                let z0 = -half + (Float(row) * tileSize)
                let x1 = x0 + tileSize
                let z1 = z0 + tileSize
                let isDark = (row + column).isMultiple(of: 2)
                let color = isDark ? colorA : colorB

                appendQuad(
                    to: &vertices,
                    p0: SIMD3<Float>(x0, 0, z0),
                    p1: SIMD3<Float>(x1, 0, z0),
                    p2: SIMD3<Float>(x1, 0, z1),
                    p3: SIMD3<Float>(x0, 0, z1),
                    color: color
                )
            }
        }

        return vertices
    }

    static func makeBox(halfExtents: SIMD3<Float>, color: SIMD4<Float>) -> [SceneVertex] {
        let minCorner = -halfExtents
        let maxCorner = halfExtents
        var vertices: [SceneVertex] = []

        let frontTopLeft = SIMD3<Float>(minCorner.x, maxCorner.y, maxCorner.z)
        let frontTopRight = SIMD3<Float>(maxCorner.x, maxCorner.y, maxCorner.z)
        let frontBottomLeft = SIMD3<Float>(minCorner.x, minCorner.y, maxCorner.z)
        let frontBottomRight = SIMD3<Float>(maxCorner.x, minCorner.y, maxCorner.z)
        let backTopLeft = SIMD3<Float>(minCorner.x, maxCorner.y, minCorner.z)
        let backTopRight = SIMD3<Float>(maxCorner.x, maxCorner.y, minCorner.z)
        let backBottomLeft = SIMD3<Float>(minCorner.x, minCorner.y, minCorner.z)
        let backBottomRight = SIMD3<Float>(maxCorner.x, minCorner.y, minCorner.z)

        appendQuad(to: &vertices, p0: frontBottomLeft, p1: frontBottomRight, p2: frontTopRight, p3: frontTopLeft, color: color)
        appendQuad(to: &vertices, p0: backBottomRight, p1: backBottomLeft, p2: backTopLeft, p3: backTopRight, color: color)
        appendQuad(to: &vertices, p0: backBottomLeft, p1: frontBottomLeft, p2: frontTopLeft, p3: backTopLeft, color: color)
        appendQuad(to: &vertices, p0: frontBottomRight, p1: backBottomRight, p2: backTopRight, p3: frontTopRight, color: color)
        appendQuad(to: &vertices, p0: frontTopLeft, p1: frontTopRight, p2: backTopRight, p3: backTopLeft, color: color)
        appendQuad(to: &vertices, p0: backBottomLeft, p1: backBottomRight, p2: frontBottomRight, p3: frontBottomLeft, color: color)

        return vertices
    }

    static func makeTerrainPatch(
        size: SIMD2<Float>,
        cornerHeights: SIMD4<Float>,
        subdivisions: Int,
        color: SIMD4<Float>
    ) -> [SceneVertex] {
        let width = max(size.x, 0.5)
        let depth = max(size.y, 0.5)
        let segmentCount = max(subdivisions, 1)
        var vertices: [SceneVertex] = []

        for row in 0..<segmentCount {
            let v0 = Float(row) / Float(segmentCount)
            let v1 = Float(row + 1) / Float(segmentCount)
            let z0 = (-depth * 0.5) + (depth * v0)
            let z1 = (-depth * 0.5) + (depth * v1)

            for column in 0..<segmentCount {
                let u0 = Float(column) / Float(segmentCount)
                let u1 = Float(column + 1) / Float(segmentCount)
                let x0 = (-width * 0.5) + (width * u0)
                let x1 = (-width * 0.5) + (width * u1)

                appendQuad(
                    to: &vertices,
                    p0: SIMD3<Float>(x0, bilinearHeight(u: u0, v: v0, cornerHeights: cornerHeights), z0),
                    p1: SIMD3<Float>(x1, bilinearHeight(u: u1, v: v0, cornerHeights: cornerHeights), z0),
                    p2: SIMD3<Float>(x1, bilinearHeight(u: u1, v: v1, cornerHeights: cornerHeights), z1),
                    p3: SIMD3<Float>(x0, bilinearHeight(u: u0, v: v1, cornerHeights: cornerHeights), z1),
                    color: color
                )
            }
        }

        return vertices
    }

    static func makeRoadStrip(
        size: SIMD2<Float>,
        shoulderWidth: Float,
        centerLineWidth: Float,
        roadColor: SIMD4<Float>,
        shoulderColor: SIMD4<Float>,
        lineColor: SIMD4<Float>,
        crownHeight: Float
    ) -> [SceneVertex] {
        let halfWidth = max(size.x * 0.5, 0.5)
        let halfDepth = max(size.y * 0.5, 0.5)
        let clampedShoulderWidth = min(max(shoulderWidth, 0.1), halfWidth * 0.45)
        let clampedCenterLine = min(max(centerLineWidth, 0.05), halfWidth * 0.2)
        var vertices: [SceneVertex] = []

        let strips: [(Float, Float, SIMD4<Float>)] = [
            (-halfWidth, -halfWidth + clampedShoulderWidth, shoulderColor),
            (-halfWidth + clampedShoulderWidth, -clampedCenterLine * 0.5, roadColor),
            (-clampedCenterLine * 0.5, clampedCenterLine * 0.5, lineColor),
            (clampedCenterLine * 0.5, halfWidth - clampedShoulderWidth, roadColor),
            (halfWidth - clampedShoulderWidth, halfWidth, shoulderColor),
        ]

        for (x0, x1, color) in strips where x1 > x0 {
            appendQuad(
                to: &vertices,
                p0: SIMD3<Float>(x0, roadCrownHeight(x: x0, halfWidth: halfWidth, crownHeight: crownHeight), -halfDepth),
                p1: SIMD3<Float>(x1, roadCrownHeight(x: x1, halfWidth: halfWidth, crownHeight: crownHeight), -halfDepth),
                p2: SIMD3<Float>(x1, roadCrownHeight(x: x1, halfWidth: halfWidth, crownHeight: crownHeight), halfDepth),
                p3: SIMD3<Float>(x0, roadCrownHeight(x: x0, halfWidth: halfWidth, crownHeight: crownHeight), halfDepth),
                color: color
            )
        }

        return vertices
    }

    static func makeShadowQuad(halfExtents: SIMD2<Float>, color: SIMD4<Float>) -> [SceneVertex] {
        var vertices: [SceneVertex] = []
        appendQuad(
            to: &vertices,
            p0: SIMD3<Float>(-halfExtents.x, 0, -halfExtents.y),
            p1: SIMD3<Float>(halfExtents.x, 0, -halfExtents.y),
            p2: SIMD3<Float>(halfExtents.x, 0, halfExtents.y),
            p3: SIMD3<Float>(-halfExtents.x, 0, halfExtents.y),
            color: color
        )
        return vertices
    }

    private static func bilinearHeight(u: Float, v: Float, cornerHeights: SIMD4<Float>) -> Float {
        let north = cornerHeights.x + ((cornerHeights.y - cornerHeights.x) * u)
        let south = cornerHeights.w + ((cornerHeights.z - cornerHeights.w) * u)
        return north + ((south - north) * v)
    }

    private static func roadCrownHeight(x: Float, halfWidth: Float, crownHeight: Float) -> Float {
        guard halfWidth > 0 else {
            return 0
        }
        let normalizedDistance = min(abs(x) / halfWidth, 1)
        return crownHeight * (1 - normalizedDistance)
    }

    private static func appendQuad(
        to vertices: inout [SceneVertex],
        p0: SIMD3<Float>,
        p1: SIMD3<Float>,
        p2: SIMD3<Float>,
        p3: SIMD3<Float>,
        color: SIMD4<Float>
    ) {
        let normal = simd_normalize(simd_cross(p1 - p0, p2 - p0))
        vertices.append(SceneVertex(position: p0, normal: normal, color: color))
        vertices.append(SceneVertex(position: p1, normal: normal, color: color))
        vertices.append(SceneVertex(position: p2, normal: normal, color: color))
        vertices.append(SceneVertex(position: p0, normal: normal, color: color))
        vertices.append(SceneVertex(position: p2, normal: normal, color: color))
        vertices.append(SceneVertex(position: p3, normal: normal, color: color))
    }
}

private enum OBJAssetLoader {
    static func loadAsset(named name: String, category: String, assetRoot: String) -> LoadedAsset? {
        let assetDirectory = URL(fileURLWithPath: assetRoot, isDirectory: true).appendingPathComponent(category, isDirectory: true)
        let objectURL = assetDirectory.appendingPathComponent("\(name).obj")

        guard let objectSource = try? String(contentsOf: objectURL) else {
            print("[Scene] Failed to read OBJ at \(objectURL.path)")
            return nil
        }

        var materials: [String: SIMD4<Float>] = [:]
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var vertices: [SceneVertex] = []
        var currentColor = SIMD4<Float>(0.72, 0.76, 0.82, 1)

        for rawLine in objectSource.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") {
                continue
            }

            let parts = line.split(whereSeparator: \.isWhitespace)
            guard let keyword = parts.first else {
                continue
            }

            switch keyword {
            case "mtllib":
                if parts.count > 1 {
                    let materialURL = assetDirectory.appendingPathComponent(String(parts[1]))
                    materials = parseMaterialLibrary(at: materialURL)
                }
            case "usemtl":
                if parts.count > 1 {
                    let materialName = String(parts[1])
                    currentColor = materials[materialName] ?? fallbackColor(for: materialName)
                }
            case "v":
                if let vertex = parseVertex(parts) {
                    positions.append(vertex)
                }
            case "vn":
                if let normal = parseNormal(parts) {
                    normals.append(normal)
                }
            case "f":
                appendFaceVertices(
                    parts.dropFirst(),
                    positions: positions,
                    normals: normals,
                    color: currentColor,
                    target: &vertices
                )
            default:
                continue
            }
        }

        guard var boundsMin = vertices.first?.position, var boundsMax = vertices.first?.position else {
            return nil
        }

        for vertex in vertices {
            boundsMin = simd_min(boundsMin, vertex.position)
            boundsMax = simd_max(boundsMax, vertex.position)
        }

        return LoadedAsset(vertices: vertices, boundsMin: boundsMin, boundsMax: boundsMax)
    }

    private static func parseVertex(_ parts: [Substring]) -> SIMD3<Float>? {
        guard parts.count >= 4 else {
            return nil
        }

        guard
            let x = Float(parts[1]),
            let y = Float(parts[2]),
            let z = Float(parts[3])
        else {
            return nil
        }

        return SIMD3<Float>(x, z, -y)
    }

    private static func parseNormal(_ parts: [Substring]) -> SIMD3<Float>? {
        guard parts.count >= 4 else {
            return nil
        }

        guard
            let x = Float(parts[1]),
            let y = Float(parts[2]),
            let z = Float(parts[3])
        else {
            return nil
        }

        return simd_normalize(SIMD3<Float>(x, z, -y))
    }

    private static func appendFaceVertices(
        _ entries: ArraySlice<Substring>,
        positions: [SIMD3<Float>],
        normals: [SIMD3<Float>],
        color: SIMD4<Float>,
        target: inout [SceneVertex]
    ) {
        let faceIndices = entries.compactMap { parseFaceIndex(String($0), positionCount: positions.count, normalCount: normals.count) }
        guard faceIndices.count >= 3 else {
            return
        }

        for triangleIndex in 1..<(faceIndices.count - 1) {
            let triangle = [faceIndices[0], faceIndices[triangleIndex], faceIndices[triangleIndex + 1]]
            let faceNormal = derivedFaceNormal(triangle: triangle, positions: positions)

            for corner in triangle {
                let normal = corner.normalIndex.flatMap { normals[safe: $0] } ?? faceNormal
                if let position = positions[safe: corner.positionIndex] {
                    target.append(SceneVertex(position: position, normal: normal, color: color))
                }
            }
        }
    }

    private static func parseFaceIndex(_ token: String, positionCount: Int, normalCount: Int) -> (positionIndex: Int, normalIndex: Int?)? {
        let components = token.split(separator: "/", omittingEmptySubsequences: false)
        guard let positionIndex = resolveIndex(from: components[safe: 0], count: positionCount) else {
            return nil
        }

        let normalIndex: Int?
        if components.count >= 3 {
            normalIndex = resolveIndex(from: components[safe: 2], count: normalCount)
        } else {
            normalIndex = nil
        }

        return (positionIndex, normalIndex)
    }

    private static func resolveIndex(from token: Substring?, count: Int) -> Int? {
        guard let token, !token.isEmpty, let value = Int(token) else {
            return nil
        }

        if value > 0 {
            return value - 1
        }

        let resolved = count + value
        return resolved >= 0 ? resolved : nil
    }

    private static func derivedFaceNormal(
        triangle: [(positionIndex: Int, normalIndex: Int?)],
        positions: [SIMD3<Float>]
    ) -> SIMD3<Float> {
        guard
            let p0 = positions[safe: triangle[0].positionIndex],
            let p1 = positions[safe: triangle[1].positionIndex],
            let p2 = positions[safe: triangle[2].positionIndex]
        else {
            return SIMD3<Float>(0, 1, 0)
        }

        let candidate = simd_cross(p1 - p0, p2 - p0)
        let length = simd_length(candidate)
        return length > 0.0001 ? candidate / length : SIMD3<Float>(0, 1, 0)
    }

    private static func parseMaterialLibrary(at url: URL) -> [String: SIMD4<Float>] {
        guard let source = try? String(contentsOf: url) else {
            return [:]
        }

        var colors: [String: SIMD4<Float>] = [:]
        var currentMaterial: String?

        for rawLine in source.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") {
                continue
            }

            let parts = line.split(whereSeparator: \.isWhitespace)
            guard let keyword = parts.first else {
                continue
            }

            switch keyword {
            case "newmtl":
                currentMaterial = parts.count > 1 ? String(parts[1]) : nil
            case "Kd":
                guard
                    let currentMaterial,
                    parts.count >= 4,
                    let red = Float(parts[1]),
                    let green = Float(parts[2]),
                    let blue = Float(parts[3])
                else {
                    continue
                }

                colors[currentMaterial] = SIMD4<Float>(red, green, blue, 1)
            default:
                continue
            }
        }

        return colors
    }

    private static func fallbackColor(for materialName: String) -> SIMD4<Float> {
        let scalar = Float(abs(materialName.hashValue % 1000)) / 1000
        return SIMD4<Float>(
            0.35 + (scalar * 0.25),
            0.45 + (scalar * 0.15),
            0.55 + (scalar * 0.10),
            1
        )
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
