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
    let fogColor: SIMD4<Float>
    let fogNear: Float
    let fogFar: Float
    let hazeStrength: Float
}

struct SceneDebugInfo {
    let cycleLabel: String
    let sceneName: String
    let summary: String
    let details: [String]
    let spawn: SpawnConfiguration
}

struct SceneMapPoint {
    let x: Float
    let z: Float
}

struct SceneMapCheckpoint: Identifiable {
    let id: String
    let label: String
    let point: SceneMapPoint
    let isGoal: Bool
}

struct SceneMapRoad: Identifiable {
    let id: String
    let displayName: String
    let centerPoint: SceneMapPoint
    let width: Float
    let length: Float
    let yawDegrees: Float

    var shortLabel: String {
        let trimmed = displayName
            .replacingOccurrences(of: "Avenue", with: "Ave")
            .replacingOccurrences(of: "Drive", with: "Dr")
            .replacingOccurrences(of: "Street", with: "St")
            .replacingOccurrences(of: "Road", with: "Rd")
            .replacingOccurrences(of: "Parade", with: "Pde")
            .replacingOccurrences(of: "Circuit", with: "Cct")
        return trimmed.count <= 18 ? trimmed : String(trimmed.prefix(18))
    }

    var startPoint: SceneMapPoint {
        let halfLength = length * 0.5
        let yawRadians = yawDegrees * (.pi / 180.0)
        let deltaX = sinf(yawRadians) * halfLength
        let deltaZ = cosf(yawRadians) * halfLength
        return SceneMapPoint(x: centerPoint.x - deltaX, z: centerPoint.z - deltaZ)
    }

    var endPoint: SceneMapPoint {
        let halfLength = length * 0.5
        let yawRadians = yawDegrees * (.pi / 180.0)
        let deltaX = sinf(yawRadians) * halfLength
        let deltaZ = cosf(yawRadians) * halfLength
        return SceneMapPoint(x: centerPoint.x + deltaX, z: centerPoint.z + deltaZ)
    }
}

struct SceneMapSector: Identifiable {
    let id: String
    let displayName: String
    let residency: SectorResidency
    let minX: Float
    let maxX: Float
    let minZ: Float
    let maxZ: Float

    var shortLabel: String {
        let trimmed = displayName
            .replacingOccurrences(of: " Sector", with: "")
            .replacingOccurrences(of: "Canberra ", with: "")
        if trimmed.count <= 18 {
            return trimmed
        }

        let words = trimmed.split(separator: " ")
        return words.prefix(2).map(String.init).joined(separator: " ")
    }

    func contains(x: Float, z: Float) -> Bool {
        x >= minX && x <= maxX && z >= minZ && z <= maxZ
    }
}

struct SceneMapConfiguration {
    let sceneName: String
    let minX: Float
    let maxX: Float
    let minZ: Float
    let maxZ: Float
    let spawnPoint: SceneMapPoint
    let spawnYawDegrees: Float
    let sectors: [SceneMapSector]
    let roads: [SceneMapRoad]
    let checkpoints: [SceneMapCheckpoint]

    var width: Float {
        max(maxX - minX, 1)
    }

    var depth: Float {
        max(maxZ - minZ, 1)
    }
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

struct SceneEvasionInfo {
    let failThreshold: Float
    let observers: [ThreatObserverConfiguration]
    let coverPoints: [GuidancePointConfiguration]
    let signposts: [GuidancePointConfiguration]
}

struct SceneEvasionState {
    let summary: String
    let details: [String]
}

struct SceneBriefingState {
    let summary: String
    let details: [String]
}

final class BootstrapScene {
    let drawables: [SceneDrawable]
    let debugInfo: SceneDebugInfo
    let environment: SceneEnvironment
    let scopeConfiguration: ScopeConfiguration
    let mapConfiguration: SceneMapConfiguration

    private let sectors: [SceneSectorRuntime]
    private let runtimeWorld: SceneRuntimeWorld
    private let alwaysLoadedIndices: [Int]
    private let routeInfo: SceneRouteInfo
    private let evasionInfo: SceneEvasionInfo
    private let traversalTuning: SceneTraversalTuning

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
            scopeConfiguration = buildResult.scopeConfiguration
            mapConfiguration = buildResult.mapConfiguration
            sectors = buildResult.sectors
            runtimeWorld = buildResult.runtimeWorld
            alwaysLoadedIndices = buildResult.alwaysLoadedIndices
            routeInfo = buildResult.routeInfo
            evasionInfo = buildResult.evasionInfo
            traversalTuning = buildResult.traversalTuning
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
            scopeConfiguration = fallbackResult.scopeConfiguration
            mapConfiguration = fallbackResult.mapConfiguration
            sectors = fallbackResult.sectors
            runtimeWorld = fallbackResult.runtimeWorld
            alwaysLoadedIndices = fallbackResult.alwaysLoadedIndices
            routeInfo = fallbackResult.routeInfo
            evasionInfo = fallbackResult.evasionInfo
            traversalTuning = fallbackResult.traversalTuning
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

        runtimeWorld.threatObservers.withUnsafeBufferPointer { threatObservers in
            GameCoreConfigureDetection(
                threatObservers.baseAddress,
                Int32(threatObservers.count),
                runtimeWorld.suspicionDecayPerSecond,
                evasionInfo.failThreshold
            )
        }

        GameCoreConfigureTraversal(
            traversalTuning.walkSpeed,
            traversalTuning.sprintSpeed,
            traversalTuning.lookSensitivity
        )
    }

    func visibilityState(
        for cameraPosition: SIMD3<Float>,
        forwardVector: SIMD3<Float>,
        scopeActive: Bool
    ) -> SceneVisibilityState {
        let drawIndices = alwaysLoadedIndices + residentDrawIndices(for: cameraPosition)
        var visibleDrawables: [SceneDrawable] = []
        var culledCount = 0
        let scopeDrawDistanceMultiplier = scopeActive ? max(scopeConfiguration.drawDistanceMultiplier ?? 2.4, 1) : 1

        for drawIndex in drawIndices {
            let drawable = drawables[drawIndex]
            let offset = drawable.worldCenter - cameraPosition
            let distance = simd_length(offset)
            let maximumDrawDistance = drawable.maxDrawDistance * scopeDrawDistanceMultiplier
            let minimumViewDot = scopeActive ? -1 : drawable.minimumViewDot

            if distance - drawable.boundingRadius > maximumDrawDistance {
                culledCount += 1
                continue
            }

            if distance > 18, minimumViewDot > -1, simd_length_squared(offset) > 0.001 {
                let viewDirection = simd_normalize(offset)
                if simd_dot(viewDirection, forwardVector) < minimumViewDot {
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
        let residentIndices = residentSectorIndices(for: cameraPosition)
        let activeIndexSet = Set(activeIndices)
        let activeSectors = activeIndices.map { sectors[$0] }
        let residentOnlySectors = residentIndices
            .filter { !activeIndexSet.contains($0) }
            .map { sectors[$0] }
        let activeNames = activeSectors.map(\.displayName)
        let residentNames = residentOnlySectors.map(\.displayName)
        let currentSector = sectors.first(where: { $0.contains(cameraPosition) })?.displayName ?? "Outside basin bounds"
        let residentDrawableCount = residentIndices.reduce(0) { count, index in
            count + sectors[index].drawableRange.count
        }

        return SceneStreamingState(
            summary: "Chunks: \(activeSectors.count) near / \(residentIndices.count) resident / \(sectors.count) total",
            details: [
                "Active: \(activeNames.isEmpty ? "Fallback load" : activeNames.joined(separator: ", "))",
                "Far Field: \(residentNames.isEmpty ? "None" : residentNames.joined(separator: ", "))",
                "Current Sector: \(currentSector)",
                "Visibility: \(visibleDrawableCount) drawn / \(culledCount) culled",
            ],
            activeDrawableCount: alwaysLoadedIndices.count + residentDrawableCount
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
                    "Goal: \(routeInfo.checkpoints.last?.label ?? "Final review marker")",
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

    func evasionState(for snapshot: GameFrameSnapshot) -> SceneEvasionState {
        guard !evasionInfo.observers.isEmpty || !evasionInfo.coverPoints.isEmpty || !evasionInfo.signposts.isEmpty else {
            return SceneEvasionState(summary: "Evasion: unavailable", details: [])
        }

        if snapshot.routeFailed {
            return SceneEvasionState(
                summary: "Evasion: compromised",
                details: [
                    "Retry: press R to restart from the latest checkpoint",
                    "Threats: \(snapshot.failCount) failures logged",
                ]
            )
        }

        let cameraPosition = SIMD3<Float>(snapshot.cameraX, snapshot.cameraY, snapshot.cameraZ)
        var details: [String] = [
            String(format: "Watchers: %d seeing / %d in range", snapshot.seeingObserverCount, snapshot.activeObserverCount),
        ]

        if let nearestCover = nearestGuidancePoint(from: evasionInfo.coverPoints, to: cameraPosition) {
            details.append(String(format: "Cover: %@ (%.1fm)", nearestCover.point.label, nearestCover.distance))
        }

        if let nearestSignpost = nearestGuidancePoint(from: evasionInfo.signposts, to: cameraPosition) {
            details.append(String(format: "Guide: %@ (%.1fm)", nearestSignpost.point.label, nearestSignpost.distance))
        }

        return SceneEvasionState(
            summary: String(
                format: "Evasion: %.2f / %.2f suspicion",
                snapshot.suspicionLevel,
                max(evasionInfo.failThreshold, 0.01)
            ),
            details: details
        )
    }

    func briefingState(for snapshot: GameFrameSnapshot) -> SceneBriefingState {
        guard !routeInfo.checkpoints.isEmpty else {
            return SceneBriefingState(summary: "Briefing: unavailable", details: [])
        }

        if snapshot.routeComplete {
            return SceneBriefingState(
                summary: "Briefing: survey complete",
                details: [
                    "Outcome: the Woden-to-Belconnen basin line reads clearly without developer prompts",
                    "Reset: press R for a fresh run from the primary survey lookout",
                ]
            )
        }

        if snapshot.routeFailed {
            return SceneBriefingState(
                summary: "Briefing: recover the survey line",
                details: [
                    "Recovery: restart from the latest review marker and re-establish the basin read",
                    "Priority: return to the nearest signposted viewpoint instead of pushing into dead ground",
                ]
            )
        }

        let nextIndex = min(Int(snapshot.completedCheckpointCount), max(routeInfo.checkpoints.count - 1, 0))
        let nextCheckpoint = routeInfo.checkpoints[nextIndex]
        let originLabel = nextIndex == 0
            ? (debugInfo.spawn.label ?? "Primary survey lookout")
            : routeInfo.checkpoints[nextIndex - 1].label
        let cameraPosition = SIMD3<Float>(snapshot.cameraX, snapshot.cameraY, snapshot.cameraZ)
        let paceLine: String

        if snapshot.suspicionLevel >= max(evasionInfo.failThreshold * 0.55, 0.45) {
            paceLine = "Pace: break line of sight, then resume the Woden-to-Belconnen review pass"
        } else if snapshot.activeObserverCount > 0 {
            paceLine = "Pace: move between cover and keep the lake and district markers readable"
        } else if snapshot.distanceToNextCheckpointMeters > 18 {
            paceLine = "Pace: cross the open ground, then stop and confirm the next Canberra landmark"
        } else {
            paceLine = "Pace: steady approach into the next review marker"
        }

        var details = [
            "Leg: \(originLabel) -> \(nextCheckpoint.label)",
            String(
                format: "Heading: %@ for %.0fm",
                cardinalDirection(from: cameraPosition, to: nextCheckpoint.positionVector),
                max(snapshot.distanceToNextCheckpointMeters, 0)
            ),
            paceLine,
        ]

        if let nearestSignpost = nearestGuidancePoint(from: evasionInfo.signposts, to: cameraPosition) {
            details.append("Cue: follow \(nearestSignpost.point.label) to stay on the basin survey line")
        } else if let nearestCover = nearestGuidancePoint(from: evasionInfo.coverPoints, to: cameraPosition) {
            details.append("Cue: \(nearestCover.point.label) is the closest reset point for this survey pass")
        }

        return SceneBriefingState(
            summary: "Briefing: marker \(nextIndex + 1) / \(routeInfo.checkpoints.count) toward \(nextCheckpoint.label)",
            details: details
        )
    }

    private func activeSectorIndices(for cameraPosition: SIMD3<Float>) -> [Int] {
        let active = sectors.enumerated().compactMap { index, sector in
            sector.isNearFieldActive(for: cameraPosition) ? index : nil
        }

        guard !active.isEmpty else {
            guard let nearest = sectors.enumerated().min(by: { $0.element.distanceSquared(to: cameraPosition) < $1.element.distanceSquared(to: cameraPosition) }) else {
                return []
            }
            return [nearest.offset]
        }

        return active
    }

    private func residentSectorIndices(for cameraPosition: SIMD3<Float>) -> [Int] {
        let resident = sectors.enumerated().compactMap { index, sector in
            sector.isResident(for: cameraPosition) ? index : nil
        }

        guard !resident.isEmpty else {
            guard let nearest = sectors.enumerated().min(by: { $0.element.distanceSquared(to: cameraPosition) < $1.element.distanceSquared(to: cameraPosition) }) else {
                return []
            }
            return [nearest.offset]
        }

        return resident
    }

    private func residentDrawIndices(for cameraPosition: SIMD3<Float>) -> [Int] {
        let activeIndices = Set(residentSectorIndices(for: cameraPosition))
        return sectors.enumerated().flatMap { index, sector in
            activeIndices.contains(index) ? Array(sector.drawableRange) : []
        }
    }

    private func nearestGuidancePoint(
        from points: [GuidancePointConfiguration],
        to position: SIMD3<Float>
    ) -> (point: GuidancePointConfiguration, distance: Float)? {
        points
            .map { point in
                (point, simd_distance(point.positionVector, position))
            }
            .min { lhs, rhs in
                lhs.1 < rhs.1
            }
    }

    private func cardinalDirection(from origin: SIMD3<Float>, to destination: SIMD3<Float>) -> String {
        let delta = destination - origin
        let angle = atan2f(delta.x, -delta.z)
        let normalized = angle < 0 ? angle + (.pi * 2) : angle
        let sector = Int(round(normalized / (.pi / 4))) % 8
        let directions = ["north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west"]
        return directions[sector]
    }
}

private struct SceneBuildResult {
    let drawables: [SceneDrawable]
    let debugInfo: SceneDebugInfo
    let environment: SceneEnvironment
    let scopeConfiguration: ScopeConfiguration
    let mapConfiguration: SceneMapConfiguration
    let sectors: [SceneSectorRuntime]
    let runtimeWorld: SceneRuntimeWorld
    let alwaysLoadedIndices: [Int]
    let routeInfo: SceneRouteInfo
    let evasionInfo: SceneEvasionInfo
    let traversalTuning: SceneTraversalTuning
}

private struct SceneRuntimeWorld {
    let sectorBounds: [GameSectorBounds]
    let collisionVolumes: [GameCollisionVolume]
    let groundSurfaces: [GameGroundSurface]
    let routeCheckpoints: [GameRouteCheckpoint]
    let threatObservers: [GameThreatObserver]
    let suspicionDecayPerSecond: Float
}

private struct SceneTraversalTuning {
    let walkSpeed: Float
    let sprintSpeed: Float
    let lookSensitivity: Float
}

private struct SceneSectorRuntime {
    let id: String
    let displayName: String
    let residency: SectorResidency
    let minimum: SIMD3<Float>
    let maximum: SIMD3<Float>
    let activationPadding: Float
    let farFieldPadding: Float
    let drawableRange: Range<Int>

    func contains(_ point: SIMD3<Float>) -> Bool {
        point.x >= minimum.x && point.x <= maximum.x && point.z >= minimum.z && point.z <= maximum.z
    }

    func isNearFieldActive(for point: SIMD3<Float>) -> Bool {
        point.x >= (minimum.x - activationPadding) &&
            point.x <= (maximum.x + activationPadding) &&
            point.z >= (minimum.z - activationPadding) &&
            point.z <= (maximum.z + activationPadding)
    }

    func isResident(for point: SIMD3<Float>) -> Bool {
        switch residency {
        case .always:
            return true
        case .farField:
            return point.x >= (minimum.x - farFieldPadding) &&
                point.x <= (maximum.x + farFieldPadding) &&
                point.z >= (minimum.z - farFieldPadding) &&
                point.z <= (maximum.z + farFieldPadding)
        case .local:
            return isNearFieldActive(for: point)
        }
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
        let atmosphereConfiguration = sceneConfiguration.atmosphere ?? AtmosphereConfiguration()
        let detectionConfiguration = sceneConfiguration.detection ?? DetectionConfiguration()
        let guidanceConfiguration = sceneConfiguration.guidance ?? GuidanceConfiguration()
        let playerConfiguration = sceneConfiguration.player ?? PlayerConfiguration()
        let scopeConfiguration = sceneConfiguration.scope ?? ScopeConfiguration()
        let traversalTuning = SceneTraversalTuning(
            walkSpeed: max(playerConfiguration.walkSpeed ?? 4.2, 1.0),
            sprintSpeed: max(playerConfiguration.sprintSpeed ?? 6.8, max(playerConfiguration.walkSpeed ?? 4.2, 1.0) + 0.6),
            lookSensitivity: max(playerConfiguration.lookSensitivity ?? 0.08, 0.01)
        )

        var sceneDrawables: [SceneDrawable] = []
        var alwaysLoadedIndices: [Int] = []
        var sceneSectors: [SceneSectorRuntime] = []
        var worldSectors: [GameSectorBounds] = []
        var worldCollisionVolumes: [GameCollisionVolume] = []
        var worldGroundSurfaces: [GameGroundSurface] = []
        var worldRouteCheckpoints: [GameRouteCheckpoint] = []
        var worldThreatObservers: [GameThreatObserver] = []
        var proceduralCount = 0
        var assetCount = 0
        var terrainCount = 0
        var roadCount = 0
        var grayboxCount = 0
        var collisionCount = 0
        var routeMarkerCount = 0
        var guidanceMarkerCount = 0
        var observerMarkerCount = 0

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

        for observer in detectionConfiguration.observers {
            worldThreatObservers.append(threatObserver(from: observer))
            for markerDrawable in observerMarkerDrawables(from: observer) {
                alwaysLoadedIndices.append(sceneDrawables.count)
                sceneDrawables.append(markerDrawable)
                observerMarkerCount += 1
            }
        }

        let guidancePoints = guidanceConfiguration.coverPoints + guidanceConfiguration.signposts
        for guidancePoint in guidancePoints {
            for markerDrawable in guidanceDrawables(from: guidancePoint) {
                alwaysLoadedIndices.append(sceneDrawables.count)
                sceneDrawables.append(markerDrawable)
                guidanceMarkerCount += 1
            }
        }

        let includedSectorIDs = sceneConfiguration.includedSectors.isEmpty
            ? Array(sectorLookup.keys).sorted()
            : sceneConfiguration.includedSectors

        let loadedSectors = includedSectorIDs.compactMap { sectorLookup[$0] }
        let residencyCounts = loadedSectors.reduce(into: (local: 0, farField: 0, always: 0)) { counts, sector in
            switch sector.residency ?? .local {
            case .local:
                counts.local += 1
            case .farField:
                counts.farField += 1
            case .always:
                counts.always += 1
            }
        }
        for sector in loadedSectors {
            let minimum = sector.bounds.minimum
            let maximum = sector.bounds.maximum
            let activationPadding = sector.streamingPadding ?? 10
            let residency = sector.residency ?? .local
            let farFieldPadding = sector.farFieldPadding ?? max(activationPadding * 2.0, activationPadding + 140)
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
                if let drawable = terrainDrawable(
                    from: terrainPatch,
                    sectorID: sector.id,
                    residency: residency
                ) {
                    sceneDrawables.append(drawable)
                    terrainCount += 1
                }
                worldGroundSurfaces.append(groundSurface(from: terrainPatch))
            }

            for roadStrip in sector.roadStrips {
                if let drawable = roadDrawable(
                    from: roadStrip,
                    sectorID: sector.id,
                    residency: residency
                ) {
                    sceneDrawables.append(drawable)
                    roadCount += 1
                }
                worldGroundSurfaces.append(groundSurface(from: roadStrip))
            }

            for block in sector.grayboxBlocks {
                if let drawable = grayboxDrawable(
                    from: block,
                    sectorID: sector.id,
                    residency: residency
                ) {
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
                    residency: residency,
                    minimum: minimum,
                    maximum: maximum,
                    activationPadding: activationPadding,
                    farFieldPadding: farFieldPadding,
                    drawableRange: drawStart..<sceneDrawables.count
                )
            )
        }

        var detailLines = [
            "Grid: \(coordinateSystem.name)",
            "Axes: x \(coordinateSystem.axisX) / z \(coordinateSystem.axisZ)",
            "Spawn: \(sceneConfiguration.spawn.label ?? "District start")",
            "Sectors: \(loadedSectors.map(\.displayName).joined(separator: ", "))",
            "Residency: \(residencyCounts.always) always / \(residencyCounts.farField) far-field / \(residencyCounts.local) local",
            "World: \(terrainCount) terrain / \(roadCount) roads / \(collisionCount) blockers",
            String(
                format: "Scope: %.1fx / %.1f deg / x%.1f draw stabilization",
                scopeConfiguration.magnification,
                scopeConfiguration.fieldOfViewDegrees,
                scopeConfiguration.drawDistanceMultiplier ?? 2.4
            ),
            "Route: \(sceneConfiguration.route.name) / \(sceneConfiguration.route.checkpoints.count) checkpoints",
            "Threats: \(detectionConfiguration.observers.count) observers / \(guidanceConfiguration.coverPoints.count) cover / \(guidanceConfiguration.signposts.count) signs",
            String(
                format: "Traversal: %.1f walk / %.1f sprint / %.3f look",
                traversalTuning.walkSpeed,
                traversalTuning.sprintSpeed,
                traversalTuning.lookSensitivity
            ),
            "Data Root: \(URL(fileURLWithPath: worldDataRoot).lastPathComponent)",
        ]

        detailLines.append(contentsOf: sceneConfiguration.planningNotes ?? [])

        let summary = "\(assetCount) assets, \(terrainCount) terrain, \(roadCount) roads, \(grayboxCount) structures, \(routeMarkerCount) route markers, \(guidanceMarkerCount + observerMarkerCount) evasion markers"

        return SceneBuildResult(
            drawables: sceneDrawables,
            debugInfo: SceneDebugInfo(
                cycleLabel: sceneConfiguration.cycleLabel ?? "Canberra Basin Readability",
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
                diffuseIntensity: sceneConfiguration.sun.diffuseIntensity,
                fogColor: atmosphereConfiguration.fogColorVector,
                fogNear: max(atmosphereConfiguration.fogNear ?? 38, 8),
                fogFar: max(atmosphereConfiguration.fogFar ?? 118, max(atmosphereConfiguration.fogNear ?? 38, 8) + 1),
                hazeStrength: max(atmosphereConfiguration.hazeStrength ?? 0.16, 0)
            ),
            scopeConfiguration: scopeConfiguration,
            mapConfiguration: buildMapConfiguration(
                sceneName: sceneConfiguration.sceneName,
                loadedSectors: loadedSectors,
                spawn: sceneConfiguration.spawn,
                checkpoints: sceneConfiguration.route.checkpoints
            ),
            sectors: sceneSectors,
            runtimeWorld: SceneRuntimeWorld(
                sectorBounds: worldSectors,
                collisionVolumes: worldCollisionVolumes,
                groundSurfaces: worldGroundSurfaces,
                routeCheckpoints: worldRouteCheckpoints,
                threatObservers: worldThreatObservers,
                suspicionDecayPerSecond: detectionConfiguration.suspicionDecayPerSecond
            ),
            alwaysLoadedIndices: alwaysLoadedIndices,
            routeInfo: SceneRouteInfo(
                name: sceneConfiguration.route.name,
                summary: sceneConfiguration.route.summary,
                checkpoints: sceneConfiguration.route.checkpoints
            ),
            evasionInfo: SceneEvasionInfo(
                failThreshold: detectionConfiguration.failThreshold,
                observers: detectionConfiguration.observers,
                coverPoints: guidanceConfiguration.coverPoints,
                signposts: guidanceConfiguration.signposts
            ),
            traversalTuning: traversalTuning
        )
    }

    private func buildMapConfiguration(
        sceneName: String,
        loadedSectors: [SectorConfiguration],
        spawn: SpawnConfiguration,
        checkpoints: [RouteCheckpointConfiguration]
    ) -> SceneMapConfiguration {
        let mapSectors = loadedSectors.map { sector in
            SceneMapSector(
                id: sector.id,
                displayName: sector.displayName,
                residency: sector.residency ?? .local,
                minX: sector.bounds.minimum.x,
                maxX: sector.bounds.maximum.x,
                minZ: sector.bounds.minimum.z,
                maxZ: sector.bounds.maximum.z
            )
        }
        let mapRoads = loadedSectors.flatMap { sector in
            sector.roadStrips.map { road in
                SceneMapRoad(
                    id: "\(sector.id).\(road.name)",
                    displayName: road.name,
                    centerPoint: SceneMapPoint(
                        x: road.positionVector.x,
                        z: road.positionVector.z
                    ),
                    width: road.sizeVector.x,
                    length: road.sizeVector.y,
                    yawDegrees: road.yawDegrees ?? 0
                )
            }
        }
        let mapCheckpoints = checkpoints.map { checkpoint in
            SceneMapCheckpoint(
                id: checkpoint.id,
                label: checkpoint.label,
                point: SceneMapPoint(
                    x: checkpoint.positionVector.x,
                    z: checkpoint.positionVector.z
                ),
                isGoal: checkpoint.goal ?? false
            )
        }
        let spawnPoint = SceneMapPoint(
            x: spawn.positionVector.x,
            z: spawn.positionVector.z
        )

        var minX = mapSectors.map(\.minX).min() ?? (spawnPoint.x - 80)
        var maxX = mapSectors.map(\.maxX).max() ?? (spawnPoint.x + 80)
        var minZ = mapSectors.map(\.minZ).min() ?? (spawnPoint.z - 80)
        var maxZ = mapSectors.map(\.maxZ).max() ?? (spawnPoint.z + 80)

        minX = min(minX, spawnPoint.x)
        maxX = max(maxX, spawnPoint.x)
        minZ = min(minZ, spawnPoint.z)
        maxZ = max(maxZ, spawnPoint.z)

        for checkpoint in mapCheckpoints {
            minX = min(minX, checkpoint.point.x)
            maxX = max(maxX, checkpoint.point.x)
            minZ = min(minZ, checkpoint.point.z)
            maxZ = max(maxZ, checkpoint.point.z)
        }

        if (maxX - minX) < 1 {
            minX -= 40
            maxX += 40
        }
        if (maxZ - minZ) < 1 {
            minZ -= 40
            maxZ += 40
        }

        let padding = max(max(maxX - minX, maxZ - minZ) * 0.08, 18)

        return SceneMapConfiguration(
            sceneName: sceneName,
            minX: minX - padding,
            maxX: maxX + padding,
            minZ: minZ - padding,
            maxZ: maxZ + padding,
            spawnPoint: spawnPoint,
            spawnYawDegrees: spawn.yawDegrees,
            sectors: mapSectors,
            roads: mapRoads,
            checkpoints: mapCheckpoints
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
                maxDrawDistance: adaptiveDrawDistance(
                    defaultValue: 140,
                    boundingRadius: max(Float(configuration.size ?? 16) * (configuration.tileSize ?? 1.2) * 0.75, 8),
                    multiplier: 2.6
                ),
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
                maxDrawDistance: adaptiveDrawDistance(
                    defaultValue: 120,
                    boundingRadius: simd_length(configuration.halfExtentsVector),
                    multiplier: 3.2
                ),
                minimumViewDot: -0.65
            )
        }
    }

    private func grayboxDrawable(
        from configuration: GrayboxBlockConfiguration,
        sectorID: String,
        residency: SectorResidency
    ) -> SceneDrawable? {
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
            maxDrawDistance: adaptiveDrawDistance(
                defaultValue: visibilityDefault(130, for: residency),
                boundingRadius: simd_length(configuration.halfExtentsVector),
                multiplier: visibilityMultiplier(3.8, for: residency)
            ),
            minimumViewDot: visibilityMinimumViewDot(-0.55, for: residency)
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
            maxDrawDistance: adaptiveDrawDistance(
                defaultValue: 110,
                boundingRadius: max(configuration.halfExtentsVector.x, configuration.halfExtentsVector.z) * 1.2,
                multiplier: 3.0
            ),
            minimumViewDot: -0.7
        )
    }

    private func terrainDrawable(
        from configuration: TerrainPatchConfiguration,
        sectorID: String,
        residency: SectorResidency
    ) -> SceneDrawable? {
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
            maxDrawDistance: adaptiveDrawDistance(
                defaultValue: visibilityDefault(180, for: residency),
                boundingRadius: simd_length(SIMD3<Float>(configuration.sizeVector.x * 0.5, 1.8, configuration.sizeVector.y * 0.5)),
                multiplier: visibilityMultiplier(2.6, for: residency)
            ),
            minimumViewDot: -1
        )
    }

    private func roadDrawable(
        from configuration: RoadStripConfiguration,
        sectorID: String,
        residency: SectorResidency
    ) -> SceneDrawable? {
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
            maxDrawDistance: adaptiveDrawDistance(
                defaultValue: visibilityDefault(175, for: residency),
                boundingRadius: simd_length(SIMD3<Float>(configuration.sizeVector.x * 0.5, 0.5, configuration.sizeVector.y * 0.5)),
                multiplier: visibilityMultiplier(2.8, for: residency)
            ),
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
            maxDrawDistance: adaptiveDrawDistance(
                defaultValue: 90,
                boundingRadius: simd_length(worldExtent) * 0.5,
                multiplier: 3.2
            ),
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

    private func observerMarkerDrawables(from configuration: ThreatObserverConfiguration) -> [SceneDrawable] {
        let markerPosition = configuration.positionVector
        let markerColor = configuration.markerColorVector
        let heading = simd_float4x4.rotation(y: (configuration.yawDegrees * (.pi / 180.0)))
        var drawables: [SceneDrawable] = []

        let postVertices = GeometryBuilder.makeBox(
            halfExtents: SIMD3<Float>(0.18, 0.95, 0.18),
            color: markerColor
        )

        if let postBuffer = makeBuffer(from: postVertices) {
            drawables.append(
                SceneDrawable(
                    name: "ObserverPost:\(configuration.id)",
                    vertexBuffer: postBuffer,
                    vertexCount: postVertices.count,
                    modelMatrix: simd_float4x4.translation(markerPosition) * heading * simd_float4x4.translation(SIMD3<Float>(0, 0.95, 0)),
                    worldCenter: markerPosition + SIMD3<Float>(0, 0.95, 0),
                    boundingRadius: 1.4,
                    maxDrawDistance: 150,
                    minimumViewDot: -0.85
                )
            )
        }

        let facingVertices = GeometryBuilder.makeBox(
            halfExtents: SIMD3<Float>(0.70, 0.10, 0.10),
            color: SIMD4<Float>(markerColor.x, markerColor.y * 0.95, markerColor.z * 0.9, markerColor.w)
        )

        if let facingBuffer = makeBuffer(from: facingVertices) {
            drawables.append(
                SceneDrawable(
                    name: "ObserverFacing:\(configuration.id)",
                    vertexBuffer: facingBuffer,
                    vertexCount: facingVertices.count,
                    modelMatrix: simd_float4x4.translation(markerPosition) * heading * simd_float4x4.translation(SIMD3<Float>(0, 1.72, 0.56)),
                    worldCenter: markerPosition + SIMD3<Float>(0, 1.72, 0.56),
                    boundingRadius: 1.0,
                    maxDrawDistance: 150,
                    minimumViewDot: -0.88
                )
            )
        }

        let shadowVertices = GeometryBuilder.makeShadowQuad(
            halfExtents: SIMD2<Float>(0.75, 0.75),
            color: SIMD4<Float>(0.03, 0.04, 0.05, 0.18)
        )

        if let shadowBuffer = makeBuffer(from: shadowVertices) {
            drawables.append(
                SceneDrawable(
                    name: "ObserverShadow:\(configuration.id)",
                    vertexBuffer: shadowBuffer,
                    vertexCount: shadowVertices.count,
                    modelMatrix: simd_float4x4.translation(markerPosition + SIMD3<Float>(0, 0.03, 0)),
                    worldCenter: markerPosition,
                    boundingRadius: 0.9,
                    maxDrawDistance: 110,
                    minimumViewDot: -0.86
                )
            )
        }

        return drawables
    }

    private func guidanceDrawables(from configuration: GuidancePointConfiguration) -> [SceneDrawable] {
        let markerPosition = configuration.positionVector
        let markerColor = configuration.colorVector
        let yawRadians = (configuration.yawDegrees ?? 0) * (.pi / 180.0)
        let heading = simd_float4x4.rotation(y: yawRadians)
        var drawables: [SceneDrawable] = []

        switch configuration.kind {
        case .cover:
            let height = configuration.height ?? 1.25
            let coverVertices = GeometryBuilder.makeBox(
                halfExtents: SIMD3<Float>(0.90, height * 0.5, 0.24),
                color: markerColor
            )

            if let coverBuffer = makeBuffer(from: coverVertices) {
                drawables.append(
                    SceneDrawable(
                        name: "CoverMarker:\(configuration.id)",
                        vertexBuffer: coverBuffer,
                        vertexCount: coverVertices.count,
                        modelMatrix: simd_float4x4.translation(markerPosition + SIMD3<Float>(0, height * 0.5, 0)) * heading,
                        worldCenter: markerPosition + SIMD3<Float>(0, height * 0.5, 0),
                        boundingRadius: 1.2,
                        maxDrawDistance: 135,
                        minimumViewDot: -0.82
                    )
                )
            }

        case .signpost:
            let height = configuration.height ?? 2.4
            let postVertices = GeometryBuilder.makeBox(
                halfExtents: SIMD3<Float>(0.12, height * 0.5, 0.12),
                color: markerColor
            )

            if let postBuffer = makeBuffer(from: postVertices) {
                drawables.append(
                    SceneDrawable(
                        name: "SignpostMarker:\(configuration.id)",
                        vertexBuffer: postBuffer,
                        vertexCount: postVertices.count,
                        modelMatrix: simd_float4x4.translation(markerPosition) * heading * simd_float4x4.translation(SIMD3<Float>(0, height * 0.5, 0)),
                        worldCenter: markerPosition + SIMD3<Float>(0, height * 0.5, 0),
                        boundingRadius: 1.6,
                        maxDrawDistance: 165,
                        minimumViewDot: -0.9
                    )
                )
            }

            let armVertices = GeometryBuilder.makeBox(
                halfExtents: SIMD3<Float>(0.78, 0.12, 0.12),
                color: SIMD4<Float>(markerColor.x, markerColor.y, markerColor.z * 0.96, markerColor.w)
            )

            if let armBuffer = makeBuffer(from: armVertices) {
                drawables.append(
                    SceneDrawable(
                        name: "SignpostArm:\(configuration.id)",
                        vertexBuffer: armBuffer,
                        vertexCount: armVertices.count,
                        modelMatrix: simd_float4x4.translation(markerPosition) * heading * simd_float4x4.translation(SIMD3<Float>(0, height - 0.28, 0.48)),
                        worldCenter: markerPosition + SIMD3<Float>(0, height - 0.28, 0.48),
                        boundingRadius: 1.2,
                        maxDrawDistance: 165,
                        minimumViewDot: -0.9
                    )
                )
            }
        }

        let shadowVertices = GeometryBuilder.makeShadowQuad(
            halfExtents: SIMD2<Float>(0.8, 0.8),
            color: SIMD4<Float>(0.03, 0.04, 0.05, 0.14)
        )

        if let shadowBuffer = makeBuffer(from: shadowVertices) {
            drawables.append(
                SceneDrawable(
                    name: "GuidanceShadow:\(configuration.id)",
                    vertexBuffer: shadowBuffer,
                    vertexCount: shadowVertices.count,
                    modelMatrix: simd_float4x4.translation(markerPosition + SIMD3<Float>(0, 0.03, 0)),
                    worldCenter: markerPosition,
                    boundingRadius: 0.95,
                    maxDrawDistance: 110,
                    minimumViewDot: -0.82
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

    private func adaptiveDrawDistance(defaultValue: Float, boundingRadius: Float, multiplier: Float) -> Float {
        max(defaultValue, boundingRadius * multiplier)
    }

    private func visibilityDefault(_ baseValue: Float, for residency: SectorResidency) -> Float {
        switch residency {
        case .local:
            return baseValue
        case .farField:
            return baseValue * 1.9
        case .always:
            return baseValue * 2.4
        }
    }

    private func visibilityMultiplier(_ baseValue: Float, for residency: SectorResidency) -> Float {
        switch residency {
        case .local:
            return baseValue
        case .farField:
            return baseValue * 1.4
        case .always:
            return baseValue * 1.7
        }
    }

    private func visibilityMinimumViewDot(_ baseValue: Float, for residency: SectorResidency) -> Float {
        guard baseValue > -1 else {
            return baseValue
        }

        switch residency {
        case .local:
            return baseValue
        case .farField:
            return min(baseValue, -0.82)
        case .always:
            return -1
        }
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

    private func threatObserver(from configuration: ThreatObserverConfiguration) -> GameThreatObserver {
        GameThreatObserver(
            positionX: configuration.positionVector.x,
            positionY: configuration.positionVector.y,
            positionZ: configuration.positionVector.z,
            yawDegrees: configuration.yawDegrees,
            pitchDegrees: configuration.pitchDegrees ?? 0,
            range: configuration.range,
            fieldOfViewDegrees: configuration.fieldOfViewDegrees,
            suspicionPerSecond: configuration.suspicionPerSecond
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
                cycleLabel: "Fallback Data Slice",
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
                diffuseIntensity: 0.78,
                fogColor: SIMD4<Float>(0.58, 0.68, 0.78, 1),
                fogNear: 32,
                fogFar: 108,
                hazeStrength: 0.14
            ),
            scopeConfiguration: ScopeConfiguration(),
            mapConfiguration: SceneMapConfiguration(
                sceneName: "Fallback Bootstrap Scene",
                minX: -60,
                maxX: 60,
                minZ: -60,
                maxZ: 60,
                spawnPoint: SceneMapPoint(x: 0, z: 6),
                spawnYawDegrees: 0,
                sectors: [],
                roads: [],
                checkpoints: []
            ),
            sectors: [],
            runtimeWorld: SceneRuntimeWorld(
                sectorBounds: [],
                collisionVolumes: [],
                groundSurfaces: [],
                routeCheckpoints: [],
                threatObservers: [],
                suspicionDecayPerSecond: 0.28
            ),
            alwaysLoadedIndices: Array(drawables.indices),
            routeInfo: SceneRouteInfo(
                name: "Fallback Route",
                summary: "Route data unavailable",
                checkpoints: []
            ),
            evasionInfo: SceneEvasionInfo(
                failThreshold: 1.0,
                observers: [],
                coverPoints: [],
                signposts: []
            ),
            traversalTuning: SceneTraversalTuning(
                walkSpeed: 4.2,
                sprintSpeed: 6.8,
                lookSensitivity: 0.08
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
