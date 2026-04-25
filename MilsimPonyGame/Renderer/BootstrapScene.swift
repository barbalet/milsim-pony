import Foundation
import MetalKit
import simd

enum SceneTextureKey: String, CaseIterable {
    case terrain = "canberra_dry_grass_texture.png"
    case road = "canberra_asphalt_texture.png"
    case concrete = "canberra_concrete_texture.png"
    case water = "canberra_lake_water_texture.png"
}

enum SceneTextureReference: Hashable {
    case sceneKey(SceneTextureKey)
    case assetRelativePath(String)
}

struct SceneMaterial {
    let albedoTexture: SceneTextureReference?
    let normalTexture: SceneTextureReference?
    let roughnessTexture: SceneTextureReference?
    let ambientOcclusionTexture: SceneTextureReference?
    let baseColorFactor: SIMD4<Float>
    let roughnessFactor: Float
    let ambientOcclusionStrength: Float
    let normalScale: Float

    var hasAnyTexture: Bool {
        albedoTexture != nil || normalTexture != nil || roughnessTexture != nil || ambientOcclusionTexture != nil
    }

    static func legacy(
        textureKey: SceneTextureKey?,
        baseColorFactor: SIMD4<Float> = SIMD4<Float>(1, 1, 1, 1),
        roughnessFactor: Float = 0.88
    ) -> SceneMaterial {
        SceneMaterial(
            albedoTexture: textureKey.map { .sceneKey($0) },
            normalTexture: nil,
            roughnessTexture: nil,
            ambientOcclusionTexture: nil,
            baseColorFactor: baseColorFactor,
            roughnessFactor: roughnessFactor,
            ambientOcclusionStrength: 1.0,
            normalScale: 1.0
        )
    }

    func applying(configuration: MaterialConfiguration?) -> SceneMaterial {
        guard let configuration else {
            return self
        }

        return SceneMaterial(
            albedoTexture: configuration.albedoTexture.map(SceneTextureReference.assetRelativePath) ?? albedoTexture,
            normalTexture: configuration.normalTexture.map(SceneTextureReference.assetRelativePath) ?? normalTexture,
            roughnessTexture: configuration.roughnessTexture.map(SceneTextureReference.assetRelativePath) ?? roughnessTexture,
            ambientOcclusionTexture: configuration.ambientOcclusionTexture.map(SceneTextureReference.assetRelativePath) ?? ambientOcclusionTexture,
            baseColorFactor: configuration.baseColorVector ?? baseColorFactor,
            roughnessFactor: simd_clamp(configuration.roughness ?? roughnessFactor, 0.04, 1.0),
            ambientOcclusionStrength: simd_clamp(configuration.ambientOcclusionStrength ?? ambientOcclusionStrength, 0.0, 1.0),
            normalScale: max(configuration.normalScale ?? normalScale, 0.0)
        )
    }
}

struct SceneShadowSettings {
    let mapResolution: Int
    let coverage: Float
    let depthBias: Float
    let normalBias: Float
    let strength: Float
    let scopeCoverageMultiplier: Float
    let forwardOffsetMultiplier: Float
}

struct ScenePostProcessSettings {
    let exposureBias: Float
    let whitePoint: Float
    let contrast: Float
    let saturation: Float
    let shadowTint: SIMD4<Float>
    let highlightTint: SIMD4<Float>
    let shadowBalance: Float
    let vignetteStrength: Float
    let ssaoStrength: Float
    let ssaoRadius: Float
    let ssaoBias: Float
}

struct SceneBallisticsSettings {
    let muzzleVelocityMetersPerSecond: Float
    let gravityMetersPerSecondSquared: Float
    let maxSimulationTimeSeconds: Float
    let simulationStepSeconds: Float
    let launchHeightOffsetMeters: Float
    let scopedSpreadDegrees: Float
    let hipSpreadDegrees: Float
    let movementSpreadDegrees: Float
    let sprintSpreadDegrees: Float
    let settleDurationSeconds: Float
    let breathCycleSeconds: Float
    let breathAmplitudeDegrees: Float
    let holdBreathDurationSeconds: Float
    let holdBreathRecoverySeconds: Float
}

struct SceneDrawable {
    let name: String
    let vertexBuffer: MTLBuffer
    let vertexCount: Int
    let modelMatrix: simd_float4x4
    let worldCenter: SIMD3<Float>
    let boundingRadius: Float
    let maxDrawDistance: Float
    let minimumViewDot: Float
    let textureKey: SceneTextureKey?
    let material: SceneMaterial
    let retainedInJungleRenderer: Bool
    let castsShadow: Bool
    let receivesShadow: Bool

    init(
        name: String,
        vertexBuffer: MTLBuffer,
        vertexCount: Int,
        modelMatrix: simd_float4x4,
        worldCenter: SIMD3<Float>,
        boundingRadius: Float,
        maxDrawDistance: Float,
        minimumViewDot: Float,
        textureKey: SceneTextureKey?,
        material: SceneMaterial? = nil,
        retainedInJungleRenderer: Bool,
        castsShadow: Bool = false,
        receivesShadow: Bool = false
    ) {
        self.name = name
        self.vertexBuffer = vertexBuffer
        self.vertexCount = vertexCount
        self.modelMatrix = modelMatrix
        self.worldCenter = worldCenter
        self.boundingRadius = boundingRadius
        self.maxDrawDistance = maxDrawDistance
        self.minimumViewDot = minimumViewDot
        self.textureKey = textureKey
        self.material = material ?? SceneMaterial.legacy(textureKey: textureKey)
        self.retainedInJungleRenderer = retainedInJungleRenderer
        self.castsShadow = castsShadow
        self.receivesShadow = receivesShadow
    }
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
    let shadow: SceneShadowSettings
    let postProcess: ScenePostProcessSettings
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

struct SceneMapComparisonStop: Identifiable {
    let id: String
    let checkpointID: String
    let checkpointLabel: String
    let district: String
    let sourceFocus: String
    let combatLane: String
    let captureNote: String
}

struct SceneMapCombatStop: Identifiable {
    let id: String
    let checkpointID: String
    let checkpointLabel: String
    let district: String
    let lane: String
    let exposure: String
    let expectedObservers: Int
    let coverHint: String
    let recoveryNote: String
}

struct SceneMapMissionPhase: Identifiable {
    let id: String
    let checkpointID: String
    let checkpointLabel: String
    let phase: String
    let objective: String
    let trigger: String
    let successCue: String
    let failureCue: String
    let mapCode: String?
}

struct SceneMapAlternateRoute: Identifiable {
    let id: String
    let name: String
    let summary: String
    let startCheckpointLabel: String
    let goalCheckpointLabel: String
    let checkpointLabels: [String]
    let checkpointPoints: [SceneMapPoint]
    let plannedDistanceMeters: Float
    let sectorNames: [String]
    let routeType: String
    let authoringStatus: String
    let selectionMode: String
    let selectionStatus: String
    let activationRule: String
    let checkpointOwnershipStatus: String
    let sharedCheckpointLabels: [String]
    let exclusiveCheckpointLabels: [String]
}

struct SceneMapThreatObserver: Identifiable {
    let id: String
    let label: String
    let point: SceneMapPoint
    let yawDegrees: Float
    let range: Float
    let fieldOfViewDegrees: Float
    let groupID: String?
    let patrolRouteID: String?
    let patrolRole: String?
    let formationSpacingMeters: Float?
    let markerColor: SIMD4<Float>
}

struct SceneMapRoad: Identifiable {
    let id: String
    let displayName: String
    let centerPoint: SceneMapPoint
    let width: Float
    let length: Float
    let yawDegrees: Float

    private var readableLabel: String {
        Self.humanReadableLabel(from: displayName)
    }

    var shortLabel: String {
        let trimmed = readableLabel
            .replacingOccurrences(of: "Avenue", with: "Ave")
            .replacingOccurrences(of: "Drive", with: "Dr")
            .replacingOccurrences(of: "Street", with: "St")
            .replacingOccurrences(of: "Road", with: "Rd")
            .replacingOccurrences(of: "Parade", with: "Pde")
            .replacingOccurrences(of: "Circuit", with: "Cct")
            .replacingOccurrences(of: "Circle", with: "Cir")
            .replacingOccurrences(of: "Boulevard", with: "Blvd")
            .replacingOccurrences(of: "Northbound", with: "NB")
            .replacingOccurrences(of: "Southbound", with: "SB")
            .replacingOccurrences(of: "Eastbound", with: "EB")
            .replacingOccurrences(of: "Westbound", with: "WB")
            .replacingOccurrences(of: " North", with: " N")
            .replacingOccurrences(of: " South", with: " S")
            .replacingOccurrences(of: " East", with: " E")
            .replacingOccurrences(of: " West", with: " W")
            .replacingOccurrences(of: " Approach", with: "")
            .replacingOccurrences(of: " Link", with: "")
        guard trimmed.count > 18 else {
            return trimmed
        }

        let words = trimmed.split(separator: " ")
        guard let firstWord = words.first else {
            return String(trimmed.prefix(18))
        }

        if words.count >= 2 {
            let first = String(firstWord)
            let second = String(words[1])
            let condensed = "\(first) \(second)"
            if condensed.count <= 18 {
                return condensed
            }
        }

        return String(trimmed.prefix(18))
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

    private static func humanReadableLabel(from value: String) -> String {
        guard !value.isEmpty else {
            return value
        }

        var result = ""
        var previous: Character?

        for character in value {
            let shouldInsertSpace =
                previous != nil &&
                character.isUppercase &&
                (previous?.isLowercase == true || previous?.isNumber == true)

            if shouldInsertSpace {
                result.append(" ")
            }

            result.append(character)
            previous = character
        }

        return result
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
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

    var area: Float {
        max(maxX - minX, 1) * max(maxZ - minZ, 1)
    }

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
    let routeName: String
    let routeStartLabel: String
    let routeGoalLabel: String
    let routePlannedDistanceMeters: Float
    let routeSectorNames: [String]
    let activeRouteID: String
    let activeRouteLabel: String
    let selectedAlternateRouteID: String?
    let selectedAlternateRouteLabel: String?
    let routeBindingStatus: String
    let routeLoaderStatus: String
    let routeValidationStatus: String
    let routeValidationRule: String
    let routeSelectionStatus: String
    let routeSelectionRule: String
    let routeActivationStatus: String
    let routeActivationRule: String
    let routeRollbackStatus: String
    let routeRollbackRule: String
    let routeCommitStatus: String
    let routeCommitRule: String
    let routeDryRunStatus: String
    let routeDryRunRule: String
    let routePromotionStatus: String
    let routePromotionRule: String
    let routeAuditStatus: String
    let routeAuditRule: String
    let routeBoundaryStatus: String
    let routeBoundaryRule: String
    let routeArmingStatus: String
    let routeArmingRule: String
    let routeConfirmationStatus: String
    let routeConfirmationRule: String
    let routeReleaseStatus: String
    let routeReleaseRule: String
    let routePreflightStatus: String
    let routePreflightRule: String
    let routeHandoffStatus: String
    let routeHandoffRule: String
    let collisionAuthoringStatus: String
    let collisionAuthoringRule: String
    let collisionAuthoringAudit: String
    let collisionAuthoringBlockerScope: String
    let environmentalMotionStatus: String
    let environmentalMotionRule: String
    let environmentalMotionWindSummary: String
    let surfaceFidelityStatus: String
    let surfaceFidelityRule: String
    let surfaceFidelitySummary: String
    let sessionPersistenceStatus: String
    let sessionPersistenceRule: String
    let sessionPersistenceSummary: String
    let reviewPackTitle: String
    let reviewPackSummary: String
    let referenceGallery: String
    let textureLibrary: String
    let captureFormat: String
    let openRisks: [String]
    let comparisonStops: [SceneMapComparisonStop]
    let combatRehearsalTitle: String
    let combatRehearsalSummary: String
    let exposureGuide: String
    let recoveryRule: String
    let contactStops: [SceneMapCombatStop]
    let missionScriptTitle: String
    let missionScriptSummary: String
    let missionPhases: [SceneMapMissionPhase]
    let alternateRoutes: [SceneMapAlternateRoute]
    let threatObservers: [SceneMapThreatObserver]

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
    let startLabel: String
    let goalLabel: String
    let plannedDistanceMeters: Float
    let sectorNames: [String]
    let missionTitle: String
    let missionSummary: String
    let missionPhases: [MissionPhaseConfiguration]
    let routeSelection: RouteSelectionConfiguration
    let alternateRoutes: [AlternateRouteConfiguration]
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
    private static let terrainPatchSampleSide = 25
    private static let terrainPatchSpacing: Float = 2.0
    private static let terrainPatchUpdateStride: Float = terrainPatchSpacing * 0.5

    private struct TerrainPatchCacheKey: Equatable {
        let centerColumn: Int
        let centerRow: Int
        let profileToken: String
    }

    private struct CachedTerrainPatchState {
        let key: TerrainPatchCacheKey
        let patch: JungleTerrainPatch
    }

    let drawables: [SceneDrawable]
    private(set) var debugInfo: SceneDebugInfo
    let environment: SceneEnvironment
    let scopeConfiguration: ScopeConfiguration
    let ballisticsSettings: SceneBallisticsSettings
    let detectionFailThreshold: Float
    private(set) var mapConfiguration: SceneMapConfiguration

    private let sectors: [SceneSectorRuntime]
    private let runtimeWorld: SceneRuntimeWorld
    private let alwaysLoadedIndices: [Int]
    private let routeInfo: SceneRouteInfo
    private let evasionInfo: SceneEvasionInfo
    private let traversalTuning: SceneTraversalTuning
    private let environmentalMotion: EnvironmentalMotionConfiguration
    private let debugInfoTemplate: SceneDebugInfo
    private let mapConfigurationTemplate: SceneMapConfiguration
    private let groundSampler: WorldGroundSurfaceSampler
    private let spawnOptions: [SpawnConfiguration]
    private var activeRouteRuntimeCheckpoints: [GameRouteCheckpoint] = []
    private var activeRouteCheckpointConfigurations: [RouteCheckpointConfiguration] = []
    private var cachedTerrainPatchState: CachedTerrainPatchState?

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
            debugInfoTemplate = buildResult.debugInfo
            environment = buildResult.environment
            scopeConfiguration = buildResult.scopeConfiguration
            ballisticsSettings = buildResult.ballisticsSettings
            detectionFailThreshold = buildResult.evasionInfo.failThreshold
            mapConfiguration = buildResult.mapConfiguration
            mapConfigurationTemplate = buildResult.mapConfiguration
            sectors = buildResult.sectors
            runtimeWorld = buildResult.runtimeWorld
            alwaysLoadedIndices = buildResult.alwaysLoadedIndices
            routeInfo = buildResult.routeInfo
            evasionInfo = buildResult.evasionInfo
            traversalTuning = buildResult.traversalTuning
            environmentalMotion = buildResult.environmentalMotion
            groundSampler = buildResult.groundModel.sampler
            spawnOptions = buildResult.spawnOptions
        } catch {
            let fallbackResult = FallbackSceneFactory.build(
                device: device,
                worldDataRoot: worldDataRoot,
                worldManifestPath: worldManifestPath,
                errorDescription: error.localizedDescription
            )

            drawables = fallbackResult.drawables
            debugInfo = fallbackResult.debugInfo
            debugInfoTemplate = fallbackResult.debugInfo
            environment = fallbackResult.environment
            scopeConfiguration = fallbackResult.scopeConfiguration
            ballisticsSettings = fallbackResult.ballisticsSettings
            detectionFailThreshold = fallbackResult.evasionInfo.failThreshold
            mapConfiguration = fallbackResult.mapConfiguration
            mapConfigurationTemplate = fallbackResult.mapConfiguration
            sectors = fallbackResult.sectors
            runtimeWorld = fallbackResult.runtimeWorld
            alwaysLoadedIndices = fallbackResult.alwaysLoadedIndices
            routeInfo = fallbackResult.routeInfo
            evasionInfo = fallbackResult.evasionInfo
            traversalTuning = fallbackResult.traversalTuning
            environmentalMotion = fallbackResult.environmentalMotion
            groundSampler = fallbackResult.groundModel.sampler
            spawnOptions = fallbackResult.spawnOptions
            print("[Scene] Falling back to procedural scene: \(error)")
        }

        prepareFreshRun()
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

        let routeCheckpoints = activeRouteRuntimeCheckpoints.isEmpty
            ? runtimeWorld.routeCheckpoints
            : activeRouteRuntimeCheckpoints
        routeCheckpoints.withUnsafeBufferPointer { routeCheckpoints in
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

            GameCoreConfigureBallistics(
                GameBallisticsConfiguration(
                    muzzleVelocityMetersPerSecond: ballisticsSettings.muzzleVelocityMetersPerSecond,
                    gravityMetersPerSecondSquared: ballisticsSettings.gravityMetersPerSecondSquared,
                    maxSimulationTimeSeconds: ballisticsSettings.maxSimulationTimeSeconds,
                    simulationStepSeconds: ballisticsSettings.simulationStepSeconds,
                    launchHeightOffsetMeters: ballisticsSettings.launchHeightOffsetMeters,
                    scopedSpreadDegrees: ballisticsSettings.scopedSpreadDegrees,
                    hipSpreadDegrees: ballisticsSettings.hipSpreadDegrees,
                    movementSpreadDegrees: ballisticsSettings.movementSpreadDegrees,
                    sprintSpreadDegrees: ballisticsSettings.sprintSpreadDegrees,
                    settleDurationSeconds: ballisticsSettings.settleDurationSeconds,
                    breathCycleSeconds: ballisticsSettings.breathCycleSeconds,
                    breathAmplitudeDegrees: ballisticsSettings.breathAmplitudeDegrees,
                    holdBreathDurationSeconds: ballisticsSettings.holdBreathDurationSeconds,
                    holdBreathRecoverySeconds: ballisticsSettings.holdBreathRecoverySeconds
                )
            )
    }

    func prepareFreshRun(activateSelectedAlternate: Bool = false) {
        cachedTerrainPatchState = nil
        let spawn = spawnOptions.randomElement() ?? debugInfoTemplate.spawn
        debugInfo = sceneDebugInfo(applying: spawn)
        let alternateRoute = activateSelectedAlternate
            ? selectedLiveBindableAlternateRoute()
            : nil
        if let alternateRoute {
            let alternateCheckpoints = checkpoints(for: alternateRoute)
            activeRouteCheckpointConfigurations = alternateCheckpoints
            activeRouteRuntimeCheckpoints = WorldRuntimeConversions.routeCheckpoints(
                from: alternateCheckpoints,
                groundSampler: groundSampler
            )
            mapConfiguration = sceneMapConfiguration(applying: spawn, activeAlternateRoute: alternateRoute)
        } else {
            activeRouteCheckpointConfigurations = routeInfo.checkpoints
            activeRouteRuntimeCheckpoints = runtimeWorld.routeCheckpoints
            mapConfiguration = sceneMapConfiguration(applying: spawn)
        }
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
            guard drawable.retainedInJungleRenderer else {
                continue
            }
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

    func shadowCasterDrawables(
        for cameraPosition: SIMD3<Float>,
        scopeActive: Bool
    ) -> [SceneDrawable] {
        let drawIndices = Array(Set(alwaysLoadedIndices + residentDrawIndices(for: cameraPosition))).sorted()
        let scopeDrawDistanceMultiplier = scopeActive ? max(scopeConfiguration.drawDistanceMultiplier ?? 2.4, 1) : 1

        return drawIndices.compactMap { drawIndex in
            let drawable = drawables[drawIndex]
            guard drawable.retainedInJungleRenderer, drawable.castsShadow else {
                return nil
            }

            let offset = drawable.worldCenter - cameraPosition
            let distance = simd_length(offset)
            let maximumDrawDistance = drawable.maxDrawDistance * scopeDrawDistanceMultiplier
            guard distance - drawable.boundingRadius <= maximumDrawDistance else {
                return nil
            }

            return drawable
        }
    }

    func makeJungleTerrainFrame(
        snapshot: GameFrameSnapshot,
        cameraPosition: SIMD3<Float>,
        cameraForward: SIMD3<Float>,
        cameraRight: SIMD3<Float>,
        viewProjectionMatrix: simd_float4x4
    ) -> JungleTerrainFrame {
        let currentSector = currentMapSector(for: cameraPosition)
        let profile = terrainProfile(for: currentSector)
        let terrainPatch = terrainPatch(
            for: cameraPosition,
            currentSector: currentSector,
            profile: profile
        )

        return JungleTerrainFrame(
            cameraPosition: cameraPosition,
            cameraForward: cameraForward,
            cameraRight: cameraRight,
            cameraFloorHeight: snapshot.groundHeight,
            simulatedTimeSeconds: snapshot.elapsedSeconds,
            currentBiome: profile.biome,
            currentWeather: profile.weather,
            biomeBlend: profile.biomeBlend,
            groundCoverHeight: 0.35,
            waistHeight: 1.10,
            headHeight: 1.80,
            canopyHeight: 4.80,
            visibilityDistance: profile.visibilityDistance,
            ambientWetness: profile.ambientWetness,
            shorelineSpace: profile.shorelineSpace,
            windDirection: environmentalMotion.windDirectionVector,
            windStrength: clamp(environmentalMotion.windStrength ?? 0.55, min: 0.0, max: 2.0),
            gustStrength: clamp(environmentalMotion.gustStrength ?? 0.25, min: 0.0, max: 2.0),
            vegetationResponse: clamp(environmentalMotion.vegetationResponse ?? 1.0, min: 0.0, max: 2.0),
            shorelineRippleStrength: clamp(environmentalMotion.shorelineRippleStrength ?? 0.18, min: 0.0, max: 1.5),
            waterSurfaceResponse: clamp(environmentalMotion.waterSurfaceResponse ?? 0.72, min: 0.0, max: 2.0),
            terrainPatch: terrainPatch,
            groundMaterial: profile.groundMaterial,
            groundCoverMaterial: profile.groundCoverMaterial,
            waistMaterial: profile.waistMaterial,
            headMaterial: profile.headMaterial,
            canopyMaterial: profile.canopyMaterial,
            viewProjectionMatrix: viewProjectionMatrix
        )
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
        let activeCheckpoints = activeRouteCheckpointsForReadout
        let activePlannedDistance = activeRoutePlannedDistanceMeters
        let activeSectorNames = activeRouteSectorNames

        guard !activeCheckpoints.isEmpty else {
            return SceneRouteState(summary: "Route: unavailable", details: [])
        }

        if snapshot.routeComplete {
            return SceneRouteState(
                summary: "Route: \(mapConfiguration.activeRouteLabel) complete",
                details: [
                    "Goal: \(activeCheckpoints.last?.label ?? "Final review marker")",
                    String(
                        format: "Footprint: %@ -> %@ / %d sectors / %.0fm planned",
                        mapConfiguration.routeStartLabel,
                        mapConfiguration.routeGoalLabel,
                        activeSectorNames.count,
                        activePlannedDistance
                    ),
                    routeMapAccuracyLine(nextCheckpointLabel: nil, activeCheckpointCount: activeCheckpoints.count),
                    "Review Pack: \(mapConfiguration.reviewPackTitle) / \(mapConfiguration.comparisonStops.count) comparison stops / \(mapConfiguration.openRisks.count) open risks",
                    "Combat Rehearsal: \(mapConfiguration.combatRehearsalTitle) / \(mapConfiguration.contactStops.count) contact lanes / \(mapConfiguration.threatObservers.count) observers",
                    "Mission Script: \(mapConfiguration.missionScriptTitle) / \(mapConfiguration.missionPhases.count) checkpoint hooks",
                    activeRouteLine(),
                    routeValidationLine(),
                    routeSelectionLine(),
                    routeActivationLine(),
                    routeRollbackLine(),
                    routeCommitLine(),
                    routeDryRunLine(),
                    routePromotionLine(),
                    routeAuditLine(),
                    routeBoundaryLine(),
                    routeArmingLine(),
                    routeConfirmationLine(),
                    routeReleaseLine(),
                    routePreflightLine(),
                    routeHandoffLine(),
                    collisionAuthoringLine(),
                    environmentalMotionLine(),
                    surfaceFidelityLine(),
                    blackMountainMaterialCloseoutLine(),
                    westBasinWaterCloseoutLine(),
                    sessionPersistenceLine(),
                    alternateRouteCompletionLine(),
                    "Contacts: \(snapshot.neutralizedObserverCount) neutralized / \(max(snapshot.totalObserverCount - snapshot.neutralizedObserverCount, 0)) live",
                    String(
                        format: "Run: %.1fs / %.0fm / %d restarts",
                        snapshot.elapsedSeconds,
                        snapshot.routeDistanceMeters,
                        snapshot.restartCount
                    ),
                ]
            )
        }

        let nextIndex = min(Int(snapshot.completedCheckpointCount), max(activeCheckpoints.count - 1, 0))
        let nextCheckpoint = activeCheckpoints[nextIndex]
        let nextComparisonStop = comparisonStop(for: nextCheckpoint.id)
        let nextCombatStop = combatStop(for: nextCheckpoint.id)
        let nextMissionPhase = missionPhase(for: nextCheckpoint.id)
        var details = [
            "Objective: \(routeInfo.summary)",
            "Mission Script: \(routeInfo.missionTitle) / \(routeInfo.missionPhases.count) checkpoint hooks",
            activeRouteLine(),
            routeValidationLine(),
            routeSelectionLine(),
            routeActivationLine(),
            routeRollbackLine(),
            routeCommitLine(),
            routeDryRunLine(),
            routePromotionLine(),
            routeAuditLine(),
            routeBoundaryLine(),
            routeArmingLine(),
            routeConfirmationLine(),
            routeReleaseLine(),
            routePreflightLine(),
            routeHandoffLine(),
            collisionAuthoringLine(),
            environmentalMotionLine(),
            surfaceFidelityLine(),
            blackMountainMaterialCloseoutLine(),
            westBasinWaterCloseoutLine(),
            sessionPersistenceLine(),
            routeMapAccuracyLine(nextCheckpointLabel: nextCheckpoint.label, activeCheckpointCount: activeCheckpoints.count),
            "Alternate Routes: \(routeInfo.alternateRoutes.count) candidates / active route is \(mapConfiguration.activeRouteLabel)",
            String(
                format: "Footprint: %@ -> %@ / %d sectors / %.0fm planned",
                mapConfiguration.routeStartLabel,
                mapConfiguration.routeGoalLabel,
                activeSectorNames.count,
                activePlannedDistance
            ),
        ]

        if let nextCombatStop {
            details.append("Contact: \(nextCombatStop.lane) / \(nextCombatStop.exposure) / \(nextCombatStop.expectedObservers) watchers")
            details.append("Cover: \(nextCombatStop.coverHint)")
        }

        if let nextMissionPhase {
            details.append("Mission: \(nextMissionPhase.phase) / \(nextMissionPhase.objective)")
            details.append("Trigger: \(nextMissionPhase.trigger)")
        }

        for alternateRoute in routeInfo.alternateRoutes.prefix(3) {
            details.append("Alt Route: \(alternateRoute.name) / \(alternateRoute.authoringStatus)")
            details.append(alternateRouteSelectionLine(for: alternateRoute))
            details.append(alternateRouteOwnershipLine(for: alternateRoute))
            details.append(alternateRouteMetricsLine(for: alternateRoute))
            details.append(alternateRouteBindingGateLine(for: alternateRoute))
        }

        if let nextComparisonStop {
            details.append("Compare: \(nextComparisonStop.district) / \(nextComparisonStop.sourceFocus)")
            details.append("Combat: \(nextComparisonStop.combatLane)")
            details.append("Capture: \(nextComparisonStop.captureNote)")
        }

        details.append(
            String(
                format: "Next: %@ (%.1fm)",
                nextCheckpoint.label,
                snapshot.distanceToNextCheckpointMeters
            )
        )
        details.append(
            String(
                format: "Run: %.1fs / %.0fm / %d restarts",
                snapshot.elapsedSeconds,
                snapshot.routeDistanceMeters,
                snapshot.restartCount
            )
        )

        return SceneRouteState(
            summary: String(
                format: "Route: %d / %d checkpoints / %.0fm of %.0fm",
                snapshot.completedCheckpointCount,
                snapshot.totalCheckpointCount,
                snapshot.routeDistanceMeters,
                activePlannedDistance
            ),
            details: details
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
            "Contacts: \(snapshot.neutralizedObserverCount) neutralized / \(max(snapshot.totalObserverCount - snapshot.neutralizedObserverCount, 0)) live",
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
        let activeCheckpoints = activeRouteCheckpointsForReadout

        guard !activeCheckpoints.isEmpty else {
            return SceneBriefingState(summary: "Briefing: unavailable", details: [])
        }

        if snapshot.routeComplete {
            return SceneBriefingState(
                summary: "Briefing: rehearsal complete",
                details: [
                    "Outcome: the current Canberra contact rehearsal reads clearly without developer prompts",
                    "Reset: use Restart for a fresh run from a new rehearsal start",
                ]
            )
        }

        if snapshot.routeFailed {
            return SceneBriefingState(
                summary: "Briefing: recover the rehearsal line",
                details: [
                    "Recovery: restart from the latest checkpoint and re-establish the authored district read",
                    "Priority: return to the nearest signposted viewpoint instead of pushing into dead ground",
                ]
            )
        }

        let nextIndex = min(Int(snapshot.completedCheckpointCount), max(activeCheckpoints.count - 1, 0))
        let nextCheckpoint = activeCheckpoints[nextIndex]
        let nextMissionPhase = missionPhase(for: nextCheckpoint.id)
        let originLabel = nextIndex == 0
            ? (debugInfo.spawn.label ?? "Assigned survey start")
            : activeCheckpoints[nextIndex - 1].label
        let cameraPosition = SIMD3<Float>(snapshot.cameraX, snapshot.cameraY, snapshot.cameraZ)
        let paceLine: String

        if snapshot.suspicionLevel >= max(evasionInfo.failThreshold * 0.55, 0.45) {
            paceLine = "Pace: break line of sight, then resume the authored district review pass"
        } else if snapshot.activeObserverCount > 0 {
            paceLine = "Pace: move between cover and keep the district skyline markers readable"
        } else if snapshot.distanceToNextCheckpointMeters > 18 {
            paceLine = "Pace: cross the open ground, then stop and confirm the next authored landmark"
        } else {
            paceLine = "Pace: steady approach into the next rehearsal marker"
        }

        var details = [
            "Leg: \(originLabel) -> \(nextCheckpoint.label)",
            String(
                format: "Heading: %@ for %.0fm",
                cardinalDirection(from: cameraPosition, to: nextCheckpoint.positionVector),
                max(snapshot.distanceToNextCheckpointMeters, 0)
            ),
            paceLine,
            routeMapAccuracyLine(nextCheckpointLabel: nextCheckpoint.label, activeCheckpointCount: activeCheckpoints.count),
        ]

        if let nextCombatStop = combatStop(for: nextCheckpoint.id) {
            details.append("Contact: \(nextCombatStop.lane) / \(nextCombatStop.exposure)")
            details.append("Cover: \(nextCombatStop.coverHint)")
        }

        if let nextMissionPhase {
            details.append("Mission: \(nextMissionPhase.phase) / \(nextMissionPhase.objective)")
            details.append("Trigger: \(nextMissionPhase.trigger)")
            details.append("Success: \(nextMissionPhase.successCue)")
        }

        for alternateRoute in routeInfo.alternateRoutes.prefix(3) {
            details.append("Alt Route: \(alternateRoute.name) / \(alternateRoute.routeType) / \(alternateRoute.authoringStatus)")
            details.append(alternateRouteSelectionLine(for: alternateRoute))
            details.append(alternateRouteOwnershipLine(for: alternateRoute))
            details.append(alternateRouteMetricsLine(for: alternateRoute))
            details.append(alternateRouteBindingGateLine(for: alternateRoute))
        }

        if snapshot.neutralizedObserverCount > 0 {
            details.append("Threats: \(snapshot.neutralizedObserverCount) observers neutralized on the current rehearsal run")
        }

        if let nextComparisonStop = comparisonStop(for: nextCheckpoint.id) {
            details.append("Compare: \(nextComparisonStop.district) / \(nextComparisonStop.sourceFocus)")
            details.append("Capture: \(nextComparisonStop.captureNote)")
        }

        if let nearestSignpost = nearestGuidancePoint(from: evasionInfo.signposts, to: cameraPosition) {
            details.append("Cue: follow \(nearestSignpost.point.label) to stay on the authored atlas line")
        } else if let nearestCover = nearestGuidancePoint(from: evasionInfo.coverPoints, to: cameraPosition) {
            details.append("Cue: \(nearestCover.point.label) is the closest reset point for this survey pass")
        }

        return SceneBriefingState(
            summary: "Briefing: marker \(nextIndex + 1) / \(activeCheckpoints.count) toward \(nextCheckpoint.label)",
            details: details
        )
    }

    private func comparisonStop(for checkpointID: String) -> SceneMapComparisonStop? {
        mapConfiguration.comparisonStops.first { comparisonStop in
            comparisonStop.checkpointID == checkpointID
        }
    }

    private func combatStop(for checkpointID: String) -> SceneMapCombatStop? {
        mapConfiguration.contactStops.first { combatStop in
            combatStop.checkpointID == checkpointID
        }
    }

    private func missionPhase(for checkpointID: String) -> MissionPhaseConfiguration? {
        routeInfo.missionPhases.first { phase in
            phase.checkpointID == checkpointID
        }
    }

    private var activeRouteCheckpointsForReadout: [RouteCheckpointConfiguration] {
        activeRouteCheckpointConfigurations.isEmpty
            ? routeInfo.checkpoints
            : activeRouteCheckpointConfigurations
    }

    private var activeRoutePlannedDistanceMeters: Float {
        mapConfiguration.routePlannedDistanceMeters > 0
            ? mapConfiguration.routePlannedDistanceMeters
            : routeInfo.plannedDistanceMeters
    }

    private var activeRouteSectorNames: [String] {
        mapConfiguration.routeSectorNames.isEmpty
            ? routeInfo.sectorNames
            : mapConfiguration.routeSectorNames
    }

    private func routeMapAccuracyLine(nextCheckpointLabel: String?, activeCheckpointCount: Int) -> String {
        let nextLabel = nextCheckpointLabel ?? "route complete"
        return String(
            format: "Map Accuracy: active %@ / %d markers / %d threat rings / next %@ / %.0fm footer",
            mapConfiguration.activeRouteLabel,
            activeCheckpointCount,
            mapConfiguration.threatObservers.count,
            nextLabel,
            activeRoutePlannedDistanceMeters
        )
    }

    private func alternateRouteCompletionLine() -> String {
        guard let alternateRoute = mapConfiguration.alternateRoutes.first else {
            return "Alternate Routes: no additional rehearsal routes authored"
        }

        return "Alternate Routes: \(mapConfiguration.alternateRoutes.count) candidates / selected \(alternateRoute.name) / \(alternateRoute.selectionStatus) / \(alternateRoute.activationRule)"
    }

    private func activeRouteLine() -> String {
        let stagedLabel = routeInfo.routeSelection.selectedAlternateRouteLabel ?? "no alternate staged"
        return "Active Route: \(routeInfo.routeSelection.activeRouteLabel) / staged \(stagedLabel) / \(routeInfo.routeSelection.bindingStatus) / \(routeInfo.routeSelection.loaderStatus)"
    }

    private func routeValidationLine() -> String {
        "Route Validation: \(routeInfo.routeSelection.validationStatus) / \(routeInfo.routeSelection.validationRule)"
    }

    private func routeSelectionLine() -> String {
        let status = routeInfo.routeSelection.selectionStatus ?? "alternate route selection pending"
        let rule = routeInfo.routeSelection.selectionRule ?? "requires briefing-locked route choice before checkpoint binding"
        return "Route Selection: \(status) / \(rule)"
    }

    private func routeActivationLine() -> String {
        let status = routeInfo.routeSelection.activationStatus ?? "alternate route activation guarded"
        let rule = routeInfo.routeSelection.activationRule ?? "activation waits for a fresh run boundary"
        return "Route Activation: \(status) / \(rule)"
    }

    private func routeRollbackLine() -> String {
        let status = routeInfo.routeSelection.rollbackStatus ?? "alternate route rollback guarded"
        let rule = routeInfo.routeSelection.rollbackRule ?? "primary route remains the fallback if alternate binding fails"
        return "Route Rollback: \(status) / \(rule)"
    }

    private func routeCommitLine() -> String {
        let status = routeInfo.routeSelection.commitStatus ?? "alternate route commit pending"
        let rule = routeInfo.routeSelection.commitRule ?? "commit waits for staged route binding at a fresh run boundary"
        return "Route Commit: \(status) / \(rule)"
    }

    private func routeDryRunLine() -> String {
        let status = routeInfo.routeSelection.dryRunStatus ?? "alternate route dry run pending"
        let rule = routeInfo.routeSelection.dryRunRule ?? "dry run must compare checkpoint order without mutating the live route"
        return "Route Dry Run: \(status) / \(rule)"
    }

    private func routePromotionLine() -> String {
        let status = routeInfo.routeSelection.promotionStatus ?? "alternate route promotion pending"
        let rule = routeInfo.routeSelection.promotionRule ?? "promotion waits for a clean dry-run review before live binding"
        return "Route Promotion: \(status) / \(rule)"
    }

    private func routeAuditLine() -> String {
        let status = routeInfo.routeSelection.auditStatus ?? "alternate route audit pending"
        let rule = routeInfo.routeSelection.auditRule ?? "audit must prove active binding remains unchanged before promotion"
        return "Route Audit: \(status) / \(rule)"
    }

    private func routeBoundaryLine() -> String {
        let status = routeInfo.routeSelection.boundaryStatus ?? "alternate route boundary check pending"
        let rule = routeInfo.routeSelection.boundaryRule ?? "handoff remains locked to briefing or restart boundaries"
        return "Route Boundary: \(status) / \(rule)"
    }

    private func routeArmingLine() -> String {
        let status = routeInfo.routeSelection.armingStatus ?? "alternate route handoff arming pending"
        let rule = routeInfo.routeSelection.armingRule ?? "arming requires boundary approval while live binding stays unchanged"
        return "Route Arming: \(status) / \(rule)"
    }

    private func routeConfirmationLine() -> String {
        let status = routeInfo.routeSelection.confirmationStatus ?? "alternate route handoff confirmation pending"
        let rule = routeInfo.routeSelection.confirmationRule ?? "confirmation records readiness without replacing the active route"
        return "Route Confirmation: \(status) / \(rule)"
    }

    private func routeReleaseLine() -> String {
        let status = routeInfo.routeSelection.releaseStatus ?? "alternate route release gate pending"
        let rule = routeInfo.routeSelection.releaseRule ?? "release gate waits for explicit live-switch implementation"
        return "Route Release: \(status) / \(rule)"
    }

    private func routePreflightLine() -> String {
        let status = routeInfo.routeSelection.preflightStatus ?? "alternate route live-switch preflight pending"
        let rule = routeInfo.routeSelection.preflightRule ?? "preflight records switch readiness without changing the active binding"
        return "Route Preflight: \(status) / \(rule)"
    }

    private func routeHandoffLine() -> String {
        "Route Handoff: \(routeInfo.routeSelection.handoffStatus) / \(routeInfo.routeSelection.handoffRule)"
    }

    private func collisionAuthoringLine() -> String {
        "Collision Authoring: \(mapConfiguration.collisionAuthoringStatus) / \(mapConfiguration.collisionAuthoringRule)"
    }

    private func environmentalMotionLine() -> String {
        "Environmental Motion: \(mapConfiguration.environmentalMotionStatus) / \(mapConfiguration.environmentalMotionWindSummary)"
    }

    private func surfaceFidelityLine() -> String {
        "Surface Fidelity: \(mapConfiguration.surfaceFidelityStatus) / \(mapConfiguration.surfaceFidelitySummary)"
    }

    private func blackMountainMaterialCloseoutLine() -> String {
        let blackMountainStop = mapConfiguration.comparisonStops.first { stop in
            stop.district.localizedCaseInsensitiveContains("Black Mountain")
        }
        let captureNote = blackMountainStop?.captureNote ?? "Capture Telstra Tower, Black Mountain, and Bruce material reads from the active route."
        return "Black Mountain Materials: Telstra/Bruce source-backed assignments / \(mapConfiguration.textureLibrary) / \(captureNote)"
    }

    private func westBasinWaterCloseoutLine() -> String {
        let westBasinStop = mapConfiguration.comparisonStops.first { stop in
            stop.district.localizedCaseInsensitiveContains("West Basin")
        }
        let captureNote = westBasinStop?.captureNote ?? "Capture West Basin shoreline, promenade materials, water motion, and vegetation response from the active route."
        return "West Basin Materials: shoreline/water/vegetation closeout / \(mapConfiguration.environmentalMotionWindSummary) / \(captureNote)"
    }

    private func sessionPersistenceLine() -> String {
        "Session Persistence: \(mapConfiguration.sessionPersistenceStatus) / \(mapConfiguration.sessionPersistenceSummary)"
    }

    private func alternateRouteSelectionLine(for route: AlternateRouteConfiguration) -> String {
        let mode = route.selectionMode ?? "preview-only"
        let status = route.selectionStatus ?? route.authoringStatus
        let activation = route.activationRule ?? "activation waits for route selection"
        return "Selection: \(mode) / \(status) / \(activation)"
    }

    private func alternateRouteOwnershipLine(for route: AlternateRouteConfiguration) -> String {
        let status = route.checkpointOwnershipStatus ?? "checkpoint ownership pending"
        let sharedCount = route.sharedCheckpointIDs?.count ?? 0
        let exclusiveCount = route.exclusiveCheckpointIDs?.count ?? 0
        return "Ownership: \(status) / \(sharedCount) shared / \(exclusiveCount) alternate-owned"
    }

    private func alternateRouteMetricsLine(for route: AlternateRouteConfiguration) -> String {
        let stagedCheckpoints = route.checkpointIDs.compactMap { checkpointID in
            routeInfo.checkpoints.first { $0.id == checkpointID }
        }
        let plannedDistance = plannedDistance(for: stagedCheckpoints)
        let sectorCount = routeSectorNames(for: stagedCheckpoints).count
        return String(
            format: "Staged Route: %d markers / %.0fm planned / %d sectors",
            stagedCheckpoints.count,
            plannedDistance,
            sectorCount
        )
    }

    private func alternateRouteBindingGateLine(for route: AlternateRouteConfiguration) -> String {
        let stagedCheckpoints = checkpoints(for: route)
        let plannedDistance = plannedDistance(for: stagedCheckpoints)
        let sectorCount = routeSectorNames(for: stagedCheckpoints).count
        let status = stagedCheckpoints.count >= 3 && plannedDistance >= 100 && sectorCount >= 2
            ? "loader gate eligible"
            : "loader gate blocked"

        return String(
            format: "Binding Gate: %@ / %d markers / %.0fm planned / %d sectors",
            status,
            stagedCheckpoints.count,
            plannedDistance,
            sectorCount
        )
    }

    private func checkpoints(for route: AlternateRouteConfiguration) -> [RouteCheckpointConfiguration] {
        route.checkpointIDs.compactMap { checkpointID in
            routeInfo.checkpoints.first { $0.id == checkpointID }
        }
    }

    private func selectedLiveBindableAlternateRoute() -> AlternateRouteConfiguration? {
        guard let selectedID = routeInfo.routeSelection.selectedAlternateRouteID else {
            return nil
        }

        guard let route = routeInfo.alternateRoutes.first(where: { $0.id == selectedID }) else {
            return nil
        }

        let stagedCheckpoints = checkpoints(for: route)
        guard stagedCheckpoints.count >= 3 else {
            return nil
        }

        let plannedDistance = plannedDistance(for: stagedCheckpoints)
        let sectorCount = routeSectorNames(for: stagedCheckpoints).count
        guard plannedDistance >= 100, sectorCount >= 2 else {
            return nil
        }

        return route
    }

    private func plannedDistance(for checkpoints: [RouteCheckpointConfiguration]) -> Float {
        zip(checkpoints, checkpoints.dropFirst()).reduce(0) { partialResult, segment in
            partialResult + simd_distance(segment.0.positionVector, segment.1.positionVector)
        }
    }

    private func routeSectorNames(for checkpoints: [RouteCheckpointConfiguration]) -> [String] {
        var names: [String] = []

        for checkpoint in checkpoints {
            guard let sector = mapConfiguration.sectors
                .filter({ $0.contains(x: checkpoint.positionVector.x, z: checkpoint.positionVector.z) })
                .min(by: { lhs, rhs in
                    ((lhs.maxX - lhs.minX) * (lhs.maxZ - lhs.minZ)) < ((rhs.maxX - rhs.minX) * (rhs.maxZ - rhs.minZ))
                })
            else {
                continue
            }

            if !names.contains(sector.displayName) {
                names.append(sector.displayName)
            }
        }

        return names
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

    private func sceneDebugInfo(applying spawn: SpawnConfiguration) -> SceneDebugInfo {
        let groundedSpawn = WorldRuntimeConversions.groundedSpawn(
            from: spawn,
            groundSampler: groundSampler
        )
        let updatedDetails = debugInfoTemplate.details.map { detail in
            detail.hasPrefix("Spawn:") ? "Spawn: \(groundedSpawn.label ?? "Survey start")" : detail
        }

        return SceneDebugInfo(
            cycleLabel: debugInfoTemplate.cycleLabel,
            sceneName: debugInfoTemplate.sceneName,
            summary: debugInfoTemplate.summary,
            details: updatedDetails,
            spawn: groundedSpawn
        )
    }

    private func sceneMapConfiguration(
        applying spawn: SpawnConfiguration,
        activeAlternateRoute: AlternateRouteConfiguration? = nil
    ) -> SceneMapConfiguration {
        let activeAlternateCheckpoints = activeAlternateRoute.map(checkpoints(for:)) ?? []
        let activeCheckpointConfigurations = activeAlternateRoute == nil
            ? routeInfo.checkpoints
            : activeAlternateCheckpoints
        let activeMapCheckpoints = activeCheckpointConfigurations.map { checkpoint in
            SceneMapCheckpoint(
                id: checkpoint.id,
                label: checkpoint.label,
                point: SceneMapPoint(
                    x: checkpoint.positionVector.x,
                    z: checkpoint.positionVector.z
                ),
                isGoal: checkpoint.id == activeCheckpointConfigurations.last?.id
            )
        }
        let activeRouteName = activeAlternateRoute?.name ?? mapConfigurationTemplate.routeName
        let activeRouteID = activeAlternateRoute?.id ?? mapConfigurationTemplate.activeRouteID
        let activeStartLabel = activeCheckpointConfigurations.first?.label ?? mapConfigurationTemplate.routeStartLabel
        let activeGoalLabel = activeCheckpointConfigurations.last?.label ?? mapConfigurationTemplate.routeGoalLabel
        let activePlannedDistance = plannedDistance(for: activeCheckpointConfigurations)
        let activeSectorNames = routeSectorNames(for: activeCheckpointConfigurations)
        let liveBindingActive = activeAlternateRoute != nil

        return SceneMapConfiguration(
            sceneName: mapConfigurationTemplate.sceneName,
            minX: mapConfigurationTemplate.minX,
            maxX: mapConfigurationTemplate.maxX,
            minZ: mapConfigurationTemplate.minZ,
            maxZ: mapConfigurationTemplate.maxZ,
            spawnPoint: SceneMapPoint(x: spawn.positionVector.x, z: spawn.positionVector.z),
            spawnYawDegrees: spawn.yawDegrees,
            sectors: mapConfigurationTemplate.sectors,
            roads: mapConfigurationTemplate.roads,
            checkpoints: activeMapCheckpoints,
            routeName: activeRouteName,
            routeStartLabel: activeStartLabel,
            routeGoalLabel: activeGoalLabel,
            routePlannedDistanceMeters: activePlannedDistance,
            routeSectorNames: activeSectorNames,
            activeRouteID: activeRouteID,
            activeRouteLabel: activeRouteName,
            selectedAlternateRouteID: mapConfigurationTemplate.selectedAlternateRouteID,
            selectedAlternateRouteLabel: mapConfigurationTemplate.selectedAlternateRouteLabel,
            routeBindingStatus: liveBindingActive
                ? "alternate route live-bound at fresh boundary"
                : mapConfigurationTemplate.routeBindingStatus,
            routeLoaderStatus: liveBindingActive
                ? "alternate route loader committed"
                : mapConfigurationTemplate.routeLoaderStatus,
            routeValidationStatus: mapConfigurationTemplate.routeValidationStatus,
            routeValidationRule: mapConfigurationTemplate.routeValidationRule,
            routeSelectionStatus: mapConfigurationTemplate.routeSelectionStatus,
            routeSelectionRule: mapConfigurationTemplate.routeSelectionRule,
            routeActivationStatus: liveBindingActive
                ? "selected alternate active"
                : mapConfigurationTemplate.routeActivationStatus,
            routeActivationRule: liveBindingActive
                ? "activated only through briefing or restart fresh-run boundary"
                : mapConfigurationTemplate.routeActivationRule,
            routeRollbackStatus: liveBindingActive
                ? "primary route retained as fallback metadata"
                : mapConfigurationTemplate.routeRollbackStatus,
            routeRollbackRule: mapConfigurationTemplate.routeRollbackRule,
            routeCommitStatus: liveBindingActive
                ? "staged route committed to active checkpoints"
                : mapConfigurationTemplate.routeCommitStatus,
            routeCommitRule: liveBindingActive
                ? "commit happened before live movement input"
                : mapConfigurationTemplate.routeCommitRule,
            routeDryRunStatus: mapConfigurationTemplate.routeDryRunStatus,
            routeDryRunRule: mapConfigurationTemplate.routeDryRunRule,
            routePromotionStatus: mapConfigurationTemplate.routePromotionStatus,
            routePromotionRule: mapConfigurationTemplate.routePromotionRule,
            routeAuditStatus: mapConfigurationTemplate.routeAuditStatus,
            routeAuditRule: mapConfigurationTemplate.routeAuditRule,
            routeBoundaryStatus: mapConfigurationTemplate.routeBoundaryStatus,
            routeBoundaryRule: mapConfigurationTemplate.routeBoundaryRule,
            routeArmingStatus: mapConfigurationTemplate.routeArmingStatus,
            routeArmingRule: mapConfigurationTemplate.routeArmingRule,
            routeConfirmationStatus: mapConfigurationTemplate.routeConfirmationStatus,
            routeConfirmationRule: mapConfigurationTemplate.routeConfirmationRule,
            routeReleaseStatus: mapConfigurationTemplate.routeReleaseStatus,
            routeReleaseRule: mapConfigurationTemplate.routeReleaseRule,
            routePreflightStatus: mapConfigurationTemplate.routePreflightStatus,
            routePreflightRule: mapConfigurationTemplate.routePreflightRule,
            routeHandoffStatus: mapConfigurationTemplate.routeHandoffStatus,
            routeHandoffRule: mapConfigurationTemplate.routeHandoffRule,
            collisionAuthoringStatus: mapConfigurationTemplate.collisionAuthoringStatus,
            collisionAuthoringRule: mapConfigurationTemplate.collisionAuthoringRule,
            collisionAuthoringAudit: mapConfigurationTemplate.collisionAuthoringAudit,
            collisionAuthoringBlockerScope: mapConfigurationTemplate.collisionAuthoringBlockerScope,
            environmentalMotionStatus: mapConfigurationTemplate.environmentalMotionStatus,
            environmentalMotionRule: mapConfigurationTemplate.environmentalMotionRule,
            environmentalMotionWindSummary: mapConfigurationTemplate.environmentalMotionWindSummary,
            surfaceFidelityStatus: mapConfigurationTemplate.surfaceFidelityStatus,
            surfaceFidelityRule: mapConfigurationTemplate.surfaceFidelityRule,
            surfaceFidelitySummary: mapConfigurationTemplate.surfaceFidelitySummary,
            sessionPersistenceStatus: mapConfigurationTemplate.sessionPersistenceStatus,
            sessionPersistenceRule: mapConfigurationTemplate.sessionPersistenceRule,
            sessionPersistenceSummary: mapConfigurationTemplate.sessionPersistenceSummary,
            reviewPackTitle: mapConfigurationTemplate.reviewPackTitle,
            reviewPackSummary: mapConfigurationTemplate.reviewPackSummary,
            referenceGallery: mapConfigurationTemplate.referenceGallery,
            textureLibrary: mapConfigurationTemplate.textureLibrary,
            captureFormat: mapConfigurationTemplate.captureFormat,
            openRisks: mapConfigurationTemplate.openRisks,
            comparisonStops: mapConfigurationTemplate.comparisonStops,
            combatRehearsalTitle: mapConfigurationTemplate.combatRehearsalTitle,
            combatRehearsalSummary: mapConfigurationTemplate.combatRehearsalSummary,
            exposureGuide: mapConfigurationTemplate.exposureGuide,
            recoveryRule: mapConfigurationTemplate.recoveryRule,
            contactStops: mapConfigurationTemplate.contactStops,
            missionScriptTitle: mapConfigurationTemplate.missionScriptTitle,
            missionScriptSummary: mapConfigurationTemplate.missionScriptSummary,
            missionPhases: mapConfigurationTemplate.missionPhases,
            alternateRoutes: mapConfigurationTemplate.alternateRoutes,
            threatObservers: mapConfigurationTemplate.threatObservers
        )
    }

    private func currentMapSector(for position: SIMD3<Float>) -> SceneMapSector? {
        mapConfiguration.sectors.first { sector in
            sector.contains(x: position.x, z: position.z)
        }
    }

    private func terrainPatch(
        for cameraPosition: SIMD3<Float>,
        currentSector: SceneMapSector?,
        profile: JungleTerrainProfile
    ) -> JungleTerrainPatch {
        let patchCenter = snappedTerrainPatchCenter(for: cameraPosition)
        let cacheKey = TerrainPatchCacheKey(
            centerColumn: snappedTerrainPatchCoordinate(for: patchCenter.x),
            centerRow: snappedTerrainPatchCoordinate(for: patchCenter.z),
            profileToken: currentSector?.id ?? "__default__"
        )

        if let cachedTerrainPatchState, cachedTerrainPatchState.key == cacheKey {
            return cachedTerrainPatchState.patch
        }

        let patch = buildTerrainPatch(center: patchCenter, profile: profile)
        cachedTerrainPatchState = CachedTerrainPatchState(key: cacheKey, patch: patch)
        return patch
    }

    private func buildTerrainPatch(
        center patchCenter: SIMD3<Float>,
        profile: JungleTerrainProfile
    ) -> JungleTerrainPatch {
        let sampleSide = Self.terrainPatchSampleSide
        let spacing = Self.terrainPatchSpacing
        let halfExtent = (Float(sampleSide - 1) * spacing) * 0.5
        let wetnessLift = max(0, (profile.ambientWetness - 0.18) * 0.28)
        var samples: [JungleTerrainSample] = []
        samples.reserveCapacity(sampleSide * sampleSide)

        for row in 0..<sampleSide {
            let worldZ = patchCenter.z - halfExtent + (Float(row) * spacing)

            for column in 0..<sampleSide {
                let worldX = patchCenter.x - halfExtent + (Float(column) * spacing)
                let roadFactor = roadInfluence(at: SIMD2<Float>(worldX, worldZ))
                let foliageNoise = terrainNoise(x: worldX, z: worldZ, frequency: 0.034, phase: 0.9)
                let canopyNoise = terrainNoise(x: worldX, z: worldZ, frequency: 0.017, phase: 2.1)
                let microNoise = terrainNoise(x: worldX, z: worldZ, frequency: 0.081, phase: 1.7)
                let height = resolvedTerrainHeight(x: worldX, z: worldZ)
                let groundCover = clamp(
                    profile.groundCoverDensity * (0.68 + foliageNoise * 0.32) * (1.0 - roadFactor * 0.88),
                    min: 0,
                    max: 1
                )
                let waist = clamp(
                    profile.waistDensity * (0.48 + foliageNoise * 0.52) * (1.0 - roadFactor * 0.92),
                    min: 0,
                    max: 1
                )
                let head = clamp(
                    profile.headDensity * (0.44 + canopyNoise * 0.56) * (1.0 - roadFactor * 0.95),
                    min: 0,
                    max: 1
                )
                let canopy = clamp(
                    profile.canopyDensity * (0.42 + canopyNoise * 0.58) * (1.0 - roadFactor * 0.97),
                    min: 0,
                    max: 1
                )
                let wetness = clamp(
                    profile.ambientWetness * (0.72 + microNoise * 0.16) +
                        wetnessLift +
                        (profile.shorelineSpace * 0.18) -
                        (roadFactor * 0.10),
                    min: 0,
                    max: 1
                )

                samples.append(
                    JungleTerrainSample(
                        position: SIMD3<Float>(worldX, height, worldZ),
                        groundCover: groundCover,
                        waist: waist,
                        head: head,
                        canopy: canopy,
                        wetness: wetness
                    )
                )
            }
        }

        return JungleTerrainPatch(
            sampleSide: sampleSide,
            spacing: spacing,
            center: patchCenter,
            samples: samples
        )
    }

    private func snappedTerrainPatchCenter(for cameraPosition: SIMD3<Float>) -> SIMD3<Float> {
        SIMD3<Float>(
            Self.terrainPatchUpdateStride > 0
                ? round(cameraPosition.x / Self.terrainPatchUpdateStride) * Self.terrainPatchUpdateStride
                : cameraPosition.x,
            cameraPosition.y,
            Self.terrainPatchUpdateStride > 0
                ? round(cameraPosition.z / Self.terrainPatchUpdateStride) * Self.terrainPatchUpdateStride
                : cameraPosition.z
        )
    }

    private func snappedTerrainPatchCoordinate(for value: Float) -> Int {
        guard Self.terrainPatchUpdateStride > 0 else {
            return 0
        }

        return Int(round(value / Self.terrainPatchUpdateStride))
    }

    private func terrainProfile(for sector: SceneMapSector?) -> JungleTerrainProfile {
        let label = sector?.displayName.lowercased() ?? ""

        if label.contains("basin") || label.contains("lake") || label.contains("yarralumla") {
            return JungleTerrainProfile(
                biome: .beach,
                weather: .coastalHaze,
                biomeBlend: 0.86,
                visibilityDistance: 132,
                ambientWetness: 0.54,
                shorelineSpace: 0.82,
                groundMaterial: JungleMaterialChannel(
                    red: 0.64,
                    green: 0.58,
                    blue: 0.43,
                    alpha: 1.0,
                    motion: 0.04,
                    wetnessResponse: 0.34
                ),
                groundCoverMaterial: JungleMaterialChannel(
                    red: 0.60,
                    green: 0.67,
                    blue: 0.45,
                    alpha: 0.26,
                    motion: 0.30,
                    wetnessResponse: 0.24
                ),
                waistMaterial: JungleMaterialChannel(
                    red: 0.53,
                    green: 0.61,
                    blue: 0.42,
                    alpha: 0.14,
                    motion: 0.28,
                    wetnessResponse: 0.18
                ),
                headMaterial: JungleMaterialChannel(
                    red: 0.43,
                    green: 0.53,
                    blue: 0.35,
                    alpha: 0.08,
                    motion: 0.24,
                    wetnessResponse: 0.16
                ),
                canopyMaterial: JungleMaterialChannel(
                    red: 0.34,
                    green: 0.44,
                    blue: 0.30,
                    alpha: 0.05,
                    motion: 0.20,
                    wetnessResponse: 0.14
                ),
                groundCoverDensity: 0.28,
                waistDensity: 0.12,
                headDensity: 0.06,
                canopyDensity: 0.03
            )
        }

        if label.contains("mountain")
            || label.contains("ainslie")
            || label.contains("campbell")
            || label.contains("deakin")
            || label.contains("escape")
        {
            return JungleTerrainProfile(
                biome: .jungle,
                weather: .humidCanopy,
                biomeBlend: 0.78,
                visibilityDistance: 88,
                ambientWetness: 0.42,
                shorelineSpace: 0.10,
                groundMaterial: JungleMaterialChannel(
                    red: 0.33,
                    green: 0.37,
                    blue: 0.27,
                    alpha: 1.0,
                    motion: 0.05,
                    wetnessResponse: 0.32
                ),
                groundCoverMaterial: JungleMaterialChannel(
                    red: 0.40,
                    green: 0.51,
                    blue: 0.31,
                    alpha: 0.62,
                    motion: 0.70,
                    wetnessResponse: 0.30
                ),
                waistMaterial: JungleMaterialChannel(
                    red: 0.29,
                    green: 0.43,
                    blue: 0.24,
                    alpha: 0.42,
                    motion: 0.62,
                    wetnessResponse: 0.28
                ),
                headMaterial: JungleMaterialChannel(
                    red: 0.23,
                    green: 0.34,
                    blue: 0.20,
                    alpha: 0.28,
                    motion: 0.56,
                    wetnessResponse: 0.24
                ),
                canopyMaterial: JungleMaterialChannel(
                    red: 0.18,
                    green: 0.28,
                    blue: 0.17,
                    alpha: 0.24,
                    motion: 0.66,
                    wetnessResponse: 0.20
                ),
                groundCoverDensity: 0.56,
                waistDensity: 0.42,
                headDensity: 0.24,
                canopyDensity: 0.18
            )
        }

        return JungleTerrainProfile(
            biome: .grassland,
            weather: .clearBreeze,
            biomeBlend: 0.34,
            visibilityDistance: 112,
            ambientWetness: 0.22,
            shorelineSpace: 0.06,
            groundMaterial: JungleMaterialChannel(
                red: 0.48,
                green: 0.47,
                blue: 0.41,
                alpha: 1.0,
                motion: 0.03,
                wetnessResponse: 0.20
            ),
            groundCoverMaterial: JungleMaterialChannel(
                red: 0.49,
                green: 0.58,
                blue: 0.35,
                alpha: 0.32,
                motion: 0.38,
                wetnessResponse: 0.18
            ),
            waistMaterial: JungleMaterialChannel(
                red: 0.38,
                green: 0.48,
                blue: 0.30,
                alpha: 0.12,
                motion: 0.32,
                wetnessResponse: 0.16
            ),
            headMaterial: JungleMaterialChannel(
                red: 0.30,
                green: 0.39,
                blue: 0.26,
                alpha: 0.06,
                motion: 0.24,
                wetnessResponse: 0.15
            ),
            canopyMaterial: JungleMaterialChannel(
                red: 0.25,
                green: 0.34,
                blue: 0.24,
                alpha: 0.04,
                motion: 0.22,
                wetnessResponse: 0.14
            ),
            groundCoverDensity: 0.24,
            waistDensity: 0.10,
            headDensity: 0.04,
            canopyDensity: 0.02
        )
    }

    private func resolvedTerrainHeight(x: Float, z: Float) -> Float {
        if let height = groundSampler.sampleHeight(x: x, z: z) {
            return height
        }

        let nearestSamples = groundSampler.surfaces
            .map { groundSampler.projectedSample(x: x, z: z, surface: $0) }
            .sorted { lhs, rhs in
                lhs.distanceSquared < rhs.distanceSquared
            }
            .prefix(4)

        guard !nearestSamples.isEmpty else {
            return 0
        }

        var weightedHeight: Float = 0
        var totalWeight: Float = 0

        for sample in nearestSamples {
            let weight = 1 / max(sample.distanceSquared, 1)
            weightedHeight += sample.height * weight
            totalWeight += weight
        }

        return totalWeight > 0 ? (weightedHeight / totalWeight) : nearestSamples.first?.height ?? 0
    }

    private func roadInfluence(at position: SIMD2<Float>) -> Float {
        mapConfiguration.roads.reduce(0) { maximumInfluence, road in
            max(maximumInfluence, roadInfluence(for: road, at: position))
        }
    }

    private func roadInfluence(for road: SceneMapRoad, at position: SIMD2<Float>) -> Float {
        let yawRadians = (-road.yawDegrees) * (.pi / 180.0)
        let cosine = cosf(yawRadians)
        let sine = sinf(yawRadians)
        let offsetX = position.x - road.centerPoint.x
        let offsetZ = position.y - road.centerPoint.z
        let localX = (offsetX * cosine) - (offsetZ * sine)
        let localZ = (offsetX * sine) + (offsetZ * cosine)
        let halfWidth = max(road.width * 0.5, 0.8)
        let halfLength = max(road.length * 0.5, 1.2)
        let edgeDistance = max(abs(localX) - halfWidth, abs(localZ) - halfLength)

        if edgeDistance <= 0 {
            return 1
        }

        let falloff = max(road.width * 0.65, 4.0)
        return clamp(1.0 - (edgeDistance / falloff), min: 0, max: 1)
    }

    private func terrainNoise(x: Float, z: Float, frequency: Float, phase: Float) -> Float {
        let value =
            sinf((x * frequency) + phase) +
            sinf((z * frequency * 1.27) + (phase * 0.7)) +
            sinf(((x + z) * frequency * 0.61) + (phase * 1.3))
        return clamp((value * 0.1667) + 0.5, min: 0, max: 1)
    }

    private func clamp(_ value: Float, min minimum: Float, max maximum: Float) -> Float {
        Swift.min(Swift.max(value, minimum), maximum)
    }
}

private struct SceneBuildResult {
    let drawables: [SceneDrawable]
    let debugInfo: SceneDebugInfo
    let environment: SceneEnvironment
    let scopeConfiguration: ScopeConfiguration
    let ballisticsSettings: SceneBallisticsSettings
    let mapConfiguration: SceneMapConfiguration
    let sectors: [SceneSectorRuntime]
    let groundModel: WorldGroundModel
    let runtimeWorld: SceneRuntimeWorld
    let alwaysLoadedIndices: [Int]
    let routeInfo: SceneRouteInfo
    let evasionInfo: SceneEvasionInfo
    let traversalTuning: SceneTraversalTuning
    let environmentalMotion: EnvironmentalMotionConfiguration
    let spawnOptions: [SpawnConfiguration]
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

private struct JungleTerrainProfile {
    let biome: JungleBiomeKind
    let weather: JungleWeatherKind
    let biomeBlend: Float
    let visibilityDistance: Float
    let ambientWetness: Float
    let shorelineSpace: Float
    let groundMaterial: JungleMaterialChannel
    let groundCoverMaterial: JungleMaterialChannel
    let waistMaterial: JungleMaterialChannel
    let headMaterial: JungleMaterialChannel
    let canopyMaterial: JungleMaterialChannel
    let groundCoverDensity: Float
    let waistDensity: Float
    let headDensity: Float
    let canopyDensity: Float
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
            let residentPadding = max(activationPadding * 1.35, min(farFieldPadding * 0.45, activationPadding + 48))
            return point.x >= (minimum.x - residentPadding) &&
                point.x <= (maximum.x + residentPadding) &&
                point.z >= (minimum.z - residentPadding) &&
                point.z <= (maximum.z + residentPadding)
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
        let shadowConfiguration = sceneConfiguration.shadow ?? ShadowConfiguration()
        let postProcessConfiguration = sceneConfiguration.postProcess ?? PostProcessConfiguration()
        let ballisticsConfiguration = sceneConfiguration.ballistics ?? BallisticsConfiguration()
        let environmentalMotion = sceneConfiguration.environmentalMotion ?? EnvironmentalMotionConfiguration()
        let materialBreakup = sceneConfiguration.materialBreakup ?? MaterialBreakupConfiguration()
        let surfaceFidelity = sceneConfiguration.surfaceFidelity ?? SurfaceFidelityConfiguration()
        let sessionPersistence = sceneConfiguration.sessionPersistence ?? SessionPersistenceConfiguration()
        let materialBreakupRoadDecalDensity = simd_clamp(materialBreakup.roadDecalDensity ?? 0.55, 0.0, 2.0)
        let materialBreakupRoadScuffStrength = simd_clamp(materialBreakup.roadScuffStrength ?? 0.42, 0.0, 1.0)
        let materialBreakupLandmarkStrength = simd_clamp(materialBreakup.landmarkBreakupStrength ?? 0.20, 0.0, 1.0)
        let traversalTuning = SceneTraversalTuning(
            walkSpeed: max(playerConfiguration.walkSpeed ?? 4.2, 1.0),
            sprintSpeed: max(playerConfiguration.sprintSpeed ?? 6.8, max(playerConfiguration.walkSpeed ?? 4.2, 1.0) + 0.6),
            lookSensitivity: max(playerConfiguration.lookSensitivity ?? 0.08, 0.01)
        )
        let shadowSettings = SceneShadowSettings(
            mapResolution: max(shadowConfiguration.mapResolution ?? 2048, 512),
            coverage: max(shadowConfiguration.coverage ?? 120.0, 24.0),
            depthBias: max(shadowConfiguration.depthBias ?? 0.015, 0.0),
            normalBias: max(shadowConfiguration.normalBias ?? 0.010, 0.0),
            strength: min(max(shadowConfiguration.strength ?? 0.72, 0.0), 1.0),
            scopeCoverageMultiplier: max(shadowConfiguration.scopeCoverageMultiplier ?? 1.25, 1.0),
            forwardOffsetMultiplier: min(max(shadowConfiguration.forwardOffsetMultiplier ?? 0.35, 0.0), 1.0)
        )
        let postProcessSettings = ScenePostProcessSettings(
            exposureBias: postProcessConfiguration.exposureBias ?? 0.18,
            whitePoint: max(postProcessConfiguration.whitePoint ?? 1.25, 0.25),
            contrast: max(postProcessConfiguration.contrast ?? 1.04, 0.0),
            saturation: max(postProcessConfiguration.saturation ?? 1.02, 0.0),
            shadowTint: postProcessConfiguration.shadowTintVector,
            highlightTint: postProcessConfiguration.highlightTintVector,
            shadowBalance: simd_clamp(postProcessConfiguration.shadowBalance ?? 0.44, 0.05, 0.95),
            vignetteStrength: simd_clamp(postProcessConfiguration.vignetteStrength ?? 0.08, 0.0, 1.0),
            ssaoStrength: simd_clamp(postProcessConfiguration.ssaoStrength ?? 0.18, 0.0, 1.0),
            ssaoRadius: simd_clamp(postProcessConfiguration.ssaoRadius ?? 1.6, 0.5, 6.0),
            ssaoBias: simd_clamp(postProcessConfiguration.ssaoBias ?? 0.0008, 0.0, 0.02)
        )
        let ballisticsSettings = SceneBallisticsSettings(
            muzzleVelocityMetersPerSecond: max(ballisticsConfiguration.muzzleVelocityMetersPerSecond ?? 820.0, 40.0),
            gravityMetersPerSecondSquared: max(ballisticsConfiguration.gravityMetersPerSecondSquared ?? 9.81, 0.1),
            maxSimulationTimeSeconds: simd_clamp(ballisticsConfiguration.maxSimulationTimeSeconds ?? 2.4, 0.25, 8.0),
            simulationStepSeconds: simd_clamp(ballisticsConfiguration.simulationStepSeconds ?? (1.0 / 120.0), 1.0 / 480.0, 0.05),
            launchHeightOffsetMeters: ballisticsConfiguration.launchHeightOffsetMeters ?? 0.0,
            scopedSpreadDegrees: simd_clamp(ballisticsConfiguration.scopedSpreadDegrees ?? 0.10, 0.01, 4.0),
            hipSpreadDegrees: simd_clamp(ballisticsConfiguration.hipSpreadDegrees ?? 0.65, 0.05, 8.0),
            movementSpreadDegrees: simd_clamp(ballisticsConfiguration.movementSpreadDegrees ?? 1.10, 0.0, 8.0),
            sprintSpreadDegrees: simd_clamp(ballisticsConfiguration.sprintSpreadDegrees ?? 1.80, 0.0, 12.0),
            settleDurationSeconds: simd_clamp(ballisticsConfiguration.settleDurationSeconds ?? 0.60, 0.0, 4.0),
            breathCycleSeconds: simd_clamp(ballisticsConfiguration.breathCycleSeconds ?? 3.40, 0.5, 12.0),
            breathAmplitudeDegrees: simd_clamp(ballisticsConfiguration.breathAmplitudeDegrees ?? 0.16, 0.01, 2.0),
            holdBreathDurationSeconds: simd_clamp(ballisticsConfiguration.holdBreathDurationSeconds ?? 2.60, 0.25, 10.0),
            holdBreathRecoverySeconds: simd_clamp(ballisticsConfiguration.holdBreathRecoverySeconds ?? 3.60, 0.25, 12.0)
        )

        var sceneDrawables: [SceneDrawable] = []
        var alwaysLoadedIndices: [Int] = []
        var sceneSectors: [SceneSectorRuntime] = []
        var proceduralCount = 0
        var assetCount = 0
        var terrainCount = 0
        var roadCount = 0
        var grayboxCount = 0
        var decalCount = 0
        var landmarkBreakupCount = 0
        var routeMarkerCount = 0
        var guidanceMarkerCount = 0
        var observerMarkerCount = 0
        var texturedWorldDrawableCount = 0
        var flatColorWorldDrawableCount = 0
        var continuityGroundDrawableCount = 0

        let includedSectorIDs = sceneConfiguration.includedSectors.isEmpty
            ? Array(sectorLookup.keys).sorted()
            : sceneConfiguration.includedSectors
        let loadedSectors = includedSectorIDs.compactMap { sectorLookup[$0] }
        let groundModel = WorldRuntimeConversions.groundModel(from: loadedSectors)
        let worldSectors = WorldRuntimeConversions.sectorBounds(from: loadedSectors)
        let worldGroundSurfaces = groundModel.allSurfaces
        let groundSampler = groundModel.sampler
        let worldCollisionVolumes = WorldRuntimeConversions.collisionVolumes(from: loadedSectors)
        let worldRouteCheckpoints = WorldRuntimeConversions.routeCheckpoints(
            from: sceneConfiguration.route.checkpoints,
            groundSampler: groundSampler
        )
        let worldThreatObservers = WorldRuntimeConversions.threatObservers(from: detectionConfiguration.observers)
        let collisionCount = worldCollisionVolumes.count
        let worldBounds = combinedBounds(
            for: loadedSectors,
            fallback: sceneConfiguration.spawn.positionVector
        )
        let furthestCheckpointDistance = sceneConfiguration.route.checkpoints.map { checkpoint in
            simd_distance(checkpoint.positionVector, sceneConfiguration.spawn.positionVector)
        }.max() ?? 0
        let longRangeCheckpointCount = sceneConfiguration.route.checkpoints.filter { checkpoint in
            simd_distance(checkpoint.positionVector, sceneConfiguration.spawn.positionVector) >= 70
        }.count
        let farFieldCheckpointCount = sceneConfiguration.route.checkpoints.filter { checkpoint in
            sector(containing: checkpoint.positionVector, in: loadedSectors).map { sector in
                (sector.residency ?? .local) == .farField
            } ?? false
        }.count

        for element in sceneConfiguration.proceduralElements {
            if let drawable = proceduralDrawable(from: element) {
                alwaysLoadedIndices.append(sceneDrawables.count)
                sceneDrawables.append(drawable)
                proceduralCount += 1
            }
        }

        if let drawable = continuityGroundDrawable(
            from: groundModel.continuitySurfaces,
            bounds: worldBounds
        ) {
            alwaysLoadedIndices.append(sceneDrawables.count)
            sceneDrawables.append(drawable)
            continuityGroundDrawableCount += 1
            texturedWorldDrawableCount += 1
        }

        for assetInstance in sceneConfiguration.assetInstances {
            let assetDrawables = assetDrawables(from: assetInstance, groundSampler: groundSampler)
            if !assetDrawables.isEmpty {
                assetCount += 1
            }
            for drawable in assetDrawables {
                alwaysLoadedIndices.append(sceneDrawables.count)
                sceneDrawables.append(drawable)
            }
        }

        for checkpoint in sceneConfiguration.route.checkpoints {
            for markerDrawable in routeMarkerDrawables(from: checkpoint, groundSampler: groundSampler) {
                alwaysLoadedIndices.append(sceneDrawables.count)
                sceneDrawables.append(markerDrawable)
                routeMarkerCount += 1
            }
        }

        for observer in detectionConfiguration.observers {
            for markerDrawable in observerMarkerDrawables(from: observer) {
                alwaysLoadedIndices.append(sceneDrawables.count)
                sceneDrawables.append(markerDrawable)
                observerMarkerCount += 1
            }
        }

        let guidancePoints = guidanceConfiguration.coverPoints + guidanceConfiguration.signposts
        for guidancePoint in guidancePoints {
            for markerDrawable in guidanceDrawables(from: guidancePoint, groundSampler: groundSampler) {
                alwaysLoadedIndices.append(sceneDrawables.count)
                sceneDrawables.append(markerDrawable)
                guidanceMarkerCount += 1
            }
        }
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

            for terrainPatch in sector.terrainPatches {
                if let drawable = terrainDrawable(
                    from: terrainPatch,
                    sectorID: sector.id,
                    residency: residency
                ) {
                    sceneDrawables.append(drawable)
                    terrainCount += 1
                    if drawable.material.hasAnyTexture {
                        texturedWorldDrawableCount += 1
                    } else {
                        flatColorWorldDrawableCount += 1
                    }
                }
            }

            for roadStrip in sector.roadStrips {
                if let drawable = roadDrawable(
                    from: roadStrip,
                    sectorID: sector.id,
                    residency: residency
                ) {
                    sceneDrawables.append(drawable)
                    roadCount += 1
                    if drawable.material.hasAnyTexture {
                        texturedWorldDrawableCount += 1
                    } else {
                        flatColorWorldDrawableCount += 1
                    }
                }

                if materialBreakupRoadDecalDensity > 0 {
                    for decalDrawable in roadDecalDrawables(
                        from: roadStrip,
                        sectorID: sector.id,
                        residency: residency,
                        density: materialBreakupRoadDecalDensity,
                        strength: materialBreakupRoadScuffStrength
                    ) {
                        sceneDrawables.append(decalDrawable)
                        decalCount += 1
                        flatColorWorldDrawableCount += 1
                    }
                }
            }

            for block in sector.grayboxBlocks {
                let normalizedBlockName = "\(sector.id) \(block.name)".lowercased()
                if materialBreakupLandmarkStrength > 0 && usesLandmarkBreakupMaterial(for: normalizedBlockName) {
                    landmarkBreakupCount += 1
                }

                if let drawable = grayboxDrawable(
                    from: block,
                    sectorID: sector.id,
                    residency: residency,
                    landmarkBreakupStrength: materialBreakupLandmarkStrength
                ) {
                    sceneDrawables.append(drawable)
                    grayboxCount += 1
                    if drawable.material.hasAnyTexture {
                        texturedWorldDrawableCount += 1
                    } else {
                        flatColorWorldDrawableCount += 1
                    }
                }
                if let shadowDrawable = grayboxShadowDrawable(from: block, sectorID: sector.id) {
                    sceneDrawables.append(shadowDrawable)
                }
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

        let reviewPack = sceneConfiguration.reviewPack ?? ReviewPackConfiguration()
        let combatRehearsal = sceneConfiguration.combatRehearsal ?? CombatRehearsalConfiguration()
        let missionScript = sceneConfiguration.missionScript ?? MissionScriptConfiguration()
        let alternateRoutes = sceneConfiguration.alternateRoutes ?? []
        let routeSelection = sceneConfiguration.routeSelection ?? RouteSelectionConfiguration(
            activeRouteID: "primary",
            activeRouteLabel: sceneConfiguration.route.name,
            selectedAlternateRouteID: alternateRoutes.first?.id,
            selectedAlternateRouteLabel: alternateRoutes.first?.name,
            bindingStatus: "primary route bound",
            loaderStatus: "alternate route loader pending",
            validationStatus: "alternate route validation pending",
            validationRule: "requires staged route metrics",
            selectionStatus: "alternate route selection pending",
            selectionRule: "requires briefing-locked route choice before checkpoint binding",
            activationStatus: "alternate route activation guarded",
            activationRule: "activation waits for a fresh run boundary",
            rollbackStatus: "alternate route rollback guarded",
            rollbackRule: "primary route remains the fallback if alternate binding fails",
            commitStatus: "alternate route commit pending",
            commitRule: "commit waits for staged route binding at a fresh run boundary",
            dryRunStatus: "alternate route dry run pending",
            dryRunRule: "dry run must compare checkpoint order without mutating the live route",
            promotionStatus: "alternate route promotion pending",
            promotionRule: "promotion waits for a clean dry-run review before live binding",
            auditStatus: "alternate route audit pending",
            auditRule: "audit must prove active binding remains unchanged before promotion",
            boundaryStatus: "alternate route boundary check pending",
            boundaryRule: "handoff remains locked to briefing or restart boundaries",
            armingStatus: "alternate route handoff arming pending",
            armingRule: "arming requires boundary approval while live binding stays unchanged",
            confirmationStatus: "alternate route handoff confirmation pending",
            confirmationRule: "confirmation records readiness without replacing the active route",
            releaseStatus: "alternate route release gate pending",
            releaseRule: "release gate waits for explicit live-switch implementation",
            preflightStatus: "alternate route live-switch preflight pending",
            preflightRule: "preflight records switch readiness without changing the active binding",
            handoffStatus: "route handoff pending",
            handoffRule: "requires eligible staged route and restart-safe checkpoint ownership"
        )
        let collisionAuthoring = sceneConfiguration.collisionAuthoring ?? CollisionAuthoringConfiguration(
            status: "collision authoring review pending",
            rule: "requires sector blocker inventory before route handoff editing",
            audit: "no collision authoring audit loaded",
            blockerScope: "sector blockers only"
        )
        let routePlannedDistanceMeters = plannedRouteDistance(for: sceneConfiguration.route.checkpoints)
        let surfaceFidelitySummary = surfaceFidelitySummary(
            environmentalMotion: environmentalMotion,
            postProcessSettings: postProcessSettings,
            materialBreakup: materialBreakup,
            roadDecalCount: decalCount,
            landmarkBreakupCount: landmarkBreakupCount
        )
        let sessionPersistenceSummary = sessionPersistenceSummary(
            spawnCount: sceneConfiguration.randomSpawns?.count ?? 1,
            checkpointCount: sceneConfiguration.route.checkpoints.count,
            alternateRouteCount: alternateRoutes.count,
            reviewStopCount: reviewPack.comparisonStops.count,
            missionPhaseCount: missionScript.phases.count
        )
        let routeSectorNames = routeSectorNames(
            for: sceneConfiguration.route.checkpoints,
            loadedSectors: loadedSectors
        )

        var detailLines = [
            "Grid: \(coordinateSystem.name)",
            "Axes: x \(coordinateSystem.axisX) / z \(coordinateSystem.axisZ)",
            "Spawn: \(sceneConfiguration.spawn.label ?? "Survey start")",
            "Sectors: \(loadedSectors.map(\.displayName).joined(separator: ", "))",
            "Residency: \(residencyCounts.always) always / \(residencyCounts.farField) far-field / \(residencyCounts.local) local",
            "World: \(terrainCount) terrain / \(roadCount) roads / \(collisionCount) blockers",
            String(
                format: "Material Breakup: %@ / %.2f road density / %.2f scuff / %.2f landmark / %d decals / %d landmark materials",
                materialBreakup.status ?? "material breakup pending",
                materialBreakupRoadDecalDensity,
                materialBreakupRoadScuffStrength,
                materialBreakupLandmarkStrength,
                decalCount,
                landmarkBreakupCount
            ),
            "Ground: \(groundModel.localSurfaces.count) local / \(groundModel.continuitySurfaces.count) continuity surfaces / \(continuityGroundDrawableCount) global drawable",
            "Texture Coverage: \(texturedWorldDrawableCount) textured world drawables / \(flatColorWorldDrawableCount) flat-color world drawables",
            String(
                format: "Scope: %.1fx / %.1f deg / x%.1f draw stabilization",
                scopeConfiguration.magnification,
                scopeConfiguration.fieldOfViewDegrees,
                scopeConfiguration.drawDistanceMultiplier ?? 2.4
            ),
            String(
                format: "Shadows: 1 map / %d px / %.0fm coverage",
                shadowSettings.mapResolution,
                shadowSettings.coverage
            ),
            String(
                format: "Long Range: %d distant checks / %d far-field markers / %.0fm furthest authored sightline",
                longRangeCheckpointCount,
                farFieldCheckpointCount,
                furthestCheckpointDistance
            ),
            String(
                format: "Route: %@ / %d checkpoints / %.0fm planned / %d sectors",
                sceneConfiguration.route.name,
                sceneConfiguration.route.checkpoints.count,
                routePlannedDistanceMeters,
                routeSectorNames.count
            ),
            "Review Pack: \(reviewPack.title) / \(reviewPack.comparisonStops.count) comparison stops / \(reviewPack.openRisks.count) open risks",
            "Reference Pack: \(reviewPack.referenceGallery) / \(reviewPack.textureLibrary)",
            "Capture Framing: \(reviewPack.captureFormat)",
            "Texture Audit: \(SceneTextureKey.allCases.count) material slots / \(texturedWorldDrawableCount) textured drawables / \(flatColorWorldDrawableCount) flat-color review items",
            "Combat Lanes: \(Set(reviewPack.comparisonStops.map(\.combatLane)).count) linked follow-on lanes",
            "Combat Rehearsal: \(combatRehearsal.title) / \(combatRehearsal.contactStops.count) contact lanes / \(detectionConfiguration.observers.count) observers",
            "Exposure Guide: \(combatRehearsal.exposureGuide)",
            "Recovery Rule: \(combatRehearsal.recoveryRule)",
            String(
                format: "Post: %+0.2f exp / %.2f white / %.2f contrast / %.2f saturation / SSAO %.2f r%.1f",
                postProcessSettings.exposureBias,
                postProcessSettings.whitePoint,
                postProcessSettings.contrast,
                postProcessSettings.saturation,
                postProcessSettings.ssaoStrength,
                postProcessSettings.ssaoRadius
            ),
            String(
                format: "Ballistics: %.0f m/s / %.2f m/s2 / %.2fs window / %.0f Hz",
                ballisticsSettings.muzzleVelocityMetersPerSecond,
                ballisticsSettings.gravityMetersPerSecondSquared,
                ballisticsSettings.maxSimulationTimeSeconds,
                1.0 / ballisticsSettings.simulationStepSeconds
            ),
            "Telemetry: \((sceneConfiguration.randomSpawns?.count ?? 1)) starts / \(sceneConfiguration.route.checkpoints.count) route markers / \(guidanceConfiguration.signposts.count) signposts",
            "Route Loader: active \(routeSelection.activeRouteLabel) / staged \(routeSelection.selectedAlternateRouteLabel ?? "no alternate staged") / \(routeSelection.bindingStatus) / \(routeSelection.loaderStatus)",
            "Route Selection: \(routeSelection.selectionStatus ?? "alternate route selection pending") / \(routeSelection.selectionRule ?? "requires briefing-locked route choice before checkpoint binding")",
            "Route Activation: \(routeSelection.activationStatus ?? "alternate route activation guarded") / \(routeSelection.activationRule ?? "activation waits for a fresh run boundary")",
            "Route Rollback: \(routeSelection.rollbackStatus ?? "alternate route rollback guarded") / \(routeSelection.rollbackRule ?? "primary route remains the fallback if alternate binding fails")",
            "Route Commit: \(routeSelection.commitStatus ?? "alternate route commit pending") / \(routeSelection.commitRule ?? "commit waits for staged route binding at a fresh run boundary")",
            "Route Dry Run: \(routeSelection.dryRunStatus ?? "alternate route dry run pending") / \(routeSelection.dryRunRule ?? "dry run must compare checkpoint order without mutating the live route")",
            "Route Promotion: \(routeSelection.promotionStatus ?? "alternate route promotion pending") / \(routeSelection.promotionRule ?? "promotion waits for a clean dry-run review before live binding")",
            "Route Audit: \(routeSelection.auditStatus ?? "alternate route audit pending") / \(routeSelection.auditRule ?? "audit must prove active binding remains unchanged before promotion")",
            "Route Boundary: \(routeSelection.boundaryStatus ?? "alternate route boundary check pending") / \(routeSelection.boundaryRule ?? "handoff remains locked to briefing or restart boundaries")",
            "Route Arming: \(routeSelection.armingStatus ?? "alternate route handoff arming pending") / \(routeSelection.armingRule ?? "arming requires boundary approval while live binding stays unchanged")",
            "Route Confirmation: \(routeSelection.confirmationStatus ?? "alternate route handoff confirmation pending") / \(routeSelection.confirmationRule ?? "confirmation records readiness without replacing the active route")",
            "Route Release: \(routeSelection.releaseStatus ?? "alternate route release gate pending") / \(routeSelection.releaseRule ?? "release gate waits for explicit live-switch implementation")",
            "Route Preflight: \(routeSelection.preflightStatus ?? "alternate route live-switch preflight pending") / \(routeSelection.preflightRule ?? "preflight records switch readiness without changing the active binding")",
            "Collision Authoring: \(collisionAuthoring.status) / \(collisionAuthoring.rule) / \(collisionAuthoring.audit)",
            "Environmental Motion: \(environmentalMotion.status ?? "environmental motion pending") / \(environmentalMotionWindSummary(environmentalMotion))",
            "Surface Fidelity: \(surfaceFidelity.status ?? "surface fidelity review pending") / \(surfaceFidelitySummary)",
            "Session Persistence: \(sessionPersistence.status ?? "session persistence planning pending") / \(sessionPersistenceSummary)",
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

        let summary = "\(assetCount) assets, \(terrainCount) terrain, \(roadCount) roads, \(grayboxCount) structures, \(decalCount) decals, \(routeMarkerCount) route markers, \(guidanceMarkerCount + observerMarkerCount) evasion markers"

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
                hazeStrength: max(atmosphereConfiguration.hazeStrength ?? 0.16, 0),
                shadow: shadowSettings,
                postProcess: postProcessSettings
            ),
            scopeConfiguration: scopeConfiguration,
            ballisticsSettings: ballisticsSettings,
            mapConfiguration: buildMapConfiguration(
                sceneName: sceneConfiguration.sceneName,
                loadedSectors: loadedSectors,
                spawn: sceneConfiguration.spawn,
                checkpoints: sceneConfiguration.route.checkpoints,
                routeName: sceneConfiguration.route.name,
                routeStartLabel: sceneConfiguration.route.checkpoints.first?.label ?? (sceneConfiguration.spawn.label ?? "Survey start"),
                routeGoalLabel: sceneConfiguration.route.checkpoints.last?.label ?? "Final review marker",
                routePlannedDistanceMeters: routePlannedDistanceMeters,
                routeSectorNames: routeSectorNames,
                routeSelection: routeSelection,
                collisionAuthoring: collisionAuthoring,
                collisionCount: collisionCount,
                environmentalMotion: environmentalMotion,
                surfaceFidelity: surfaceFidelity,
                surfaceFidelitySummary: surfaceFidelitySummary,
                sessionPersistence: sessionPersistence,
                sessionPersistenceSummary: sessionPersistenceSummary,
                reviewPack: reviewPack,
                combatRehearsal: combatRehearsal,
                missionScript: missionScript,
                alternateRoutes: alternateRoutes,
                threatObservers: detectionConfiguration.observers
            ),
            sectors: sceneSectors,
            groundModel: groundModel,
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
                checkpoints: sceneConfiguration.route.checkpoints,
                startLabel: sceneConfiguration.route.checkpoints.first?.label ?? (sceneConfiguration.spawn.label ?? "Survey start"),
                goalLabel: sceneConfiguration.route.checkpoints.last?.label ?? "Final review marker",
                plannedDistanceMeters: routePlannedDistanceMeters,
                sectorNames: routeSectorNames,
                missionTitle: missionScript.title,
                missionSummary: missionScript.summary,
                missionPhases: missionScript.phases,
                routeSelection: routeSelection,
                alternateRoutes: alternateRoutes
            ),
            evasionInfo: SceneEvasionInfo(
                failThreshold: detectionConfiguration.failThreshold,
                observers: detectionConfiguration.observers,
                coverPoints: guidanceConfiguration.coverPoints,
                signposts: guidanceConfiguration.signposts
            ),
            traversalTuning: traversalTuning,
            environmentalMotion: environmentalMotion,
            spawnOptions: sceneConfiguration.randomSpawns?.isEmpty == false
                ? (sceneConfiguration.randomSpawns ?? [sceneConfiguration.spawn])
                : [sceneConfiguration.spawn]
        )
    }

    private func buildMapConfiguration(
        sceneName: String,
        loadedSectors: [SectorConfiguration],
        spawn: SpawnConfiguration,
        checkpoints: [RouteCheckpointConfiguration],
        routeName: String,
        routeStartLabel: String,
        routeGoalLabel: String,
        routePlannedDistanceMeters: Float,
        routeSectorNames: [String],
        routeSelection: RouteSelectionConfiguration,
        collisionAuthoring: CollisionAuthoringConfiguration,
        collisionCount: Int,
        environmentalMotion: EnvironmentalMotionConfiguration,
        surfaceFidelity: SurfaceFidelityConfiguration,
        surfaceFidelitySummary: String,
        sessionPersistence: SessionPersistenceConfiguration,
        sessionPersistenceSummary: String,
        reviewPack: ReviewPackConfiguration,
        combatRehearsal: CombatRehearsalConfiguration,
        missionScript: MissionScriptConfiguration,
        alternateRoutes: [AlternateRouteConfiguration],
        threatObservers: [ThreatObserverConfiguration]
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
        let checkpointLabelsByID: [String: String] = Dictionary(uniqueKeysWithValues: checkpoints.map { checkpoint in
            (checkpoint.id, checkpoint.label)
        })
        func checkpointLabels(for checkpointIDs: [String]?) -> [String] {
            (checkpointIDs ?? []).map { checkpointID in
                checkpointLabelsByID[checkpointID] ?? checkpointID
            }
        }
        let mapComparisonStops: [SceneMapComparisonStop] = reviewPack.comparisonStops.compactMap { comparisonStop -> SceneMapComparisonStop? in
            guard let checkpointLabel = checkpointLabelsByID[comparisonStop.checkpointID] else {
                return nil
            }

            return SceneMapComparisonStop(
                id: comparisonStop.checkpointID,
                checkpointID: comparisonStop.checkpointID,
                checkpointLabel: checkpointLabel,
                district: comparisonStop.district,
                sourceFocus: comparisonStop.sourceFocus,
                combatLane: comparisonStop.combatLane,
                captureNote: comparisonStop.captureNote
            )
        }
        let mapCombatStops: [SceneMapCombatStop] = combatRehearsal.contactStops.compactMap { contactStop -> SceneMapCombatStop? in
            guard let checkpointLabel = checkpointLabelsByID[contactStop.checkpointID] else {
                return nil
            }

            return SceneMapCombatStop(
                id: contactStop.checkpointID,
                checkpointID: contactStop.checkpointID,
                checkpointLabel: checkpointLabel,
                district: contactStop.district,
                lane: contactStop.lane,
                exposure: contactStop.exposure,
                expectedObservers: contactStop.expectedObservers,
                coverHint: contactStop.coverHint,
                recoveryNote: contactStop.recoveryNote
            )
        }
        let mapMissionPhases: [SceneMapMissionPhase] = missionScript.phases.compactMap { phase -> SceneMapMissionPhase? in
            guard let checkpointLabel = checkpointLabelsByID[phase.checkpointID] else {
                return nil
            }

            return SceneMapMissionPhase(
                id: phase.checkpointID,
                checkpointID: phase.checkpointID,
                checkpointLabel: checkpointLabel,
                phase: phase.phase,
                objective: phase.objective,
                trigger: phase.trigger,
                successCue: phase.successCue,
                failureCue: phase.failureCue,
                mapCode: phase.mapCode
            )
        }
        let mapAlternateRoutes: [SceneMapAlternateRoute] = alternateRoutes.map { route in
            let alternateCheckpoints = route.checkpointIDs.compactMap { checkpointID in
                checkpoints.first { $0.id == checkpointID }
            }

            return SceneMapAlternateRoute(
                id: route.id,
                name: route.name,
                summary: route.summary,
                startCheckpointLabel: checkpointLabelsByID[route.startCheckpointID] ?? route.startCheckpointID,
                goalCheckpointLabel: checkpointLabelsByID[route.goalCheckpointID] ?? route.goalCheckpointID,
                checkpointLabels: route.checkpointIDs.map { checkpointID in
                    checkpointLabelsByID[checkpointID] ?? checkpointID
                },
                checkpointPoints: route.checkpointIDs.compactMap { checkpointID in
                    guard let checkpoint = checkpoints.first(where: { $0.id == checkpointID }) else {
                        return nil
                    }

                    return SceneMapPoint(
                        x: checkpoint.positionVector.x,
                        z: checkpoint.positionVector.z
                    )
                },
                plannedDistanceMeters: plannedRouteDistance(for: alternateCheckpoints),
                sectorNames: self.routeSectorNames(
                    for: alternateCheckpoints,
                    loadedSectors: loadedSectors
                ),
                routeType: route.routeType,
                authoringStatus: route.authoringStatus,
                selectionMode: route.selectionMode ?? "preview-only",
                selectionStatus: route.selectionStatus ?? route.authoringStatus,
                activationRule: route.activationRule ?? "activation waits for route selection",
                checkpointOwnershipStatus: route.checkpointOwnershipStatus ?? "checkpoint ownership pending",
                sharedCheckpointLabels: checkpointLabels(for: route.sharedCheckpointIDs),
                exclusiveCheckpointLabels: checkpointLabels(for: route.exclusiveCheckpointIDs)
            )
        }
        let mapThreatObservers = threatObservers.map { observer in
            SceneMapThreatObserver(
                id: observer.id,
                label: observer.label,
                point: SceneMapPoint(
                    x: observer.positionVector.x,
                    z: observer.positionVector.z
                ),
                yawDegrees: observer.yawDegrees,
                range: observer.range,
                fieldOfViewDegrees: observer.fieldOfViewDegrees,
                groupID: observer.groupID,
                patrolRouteID: observer.patrolRouteID,
                patrolRole: observer.patrolRole,
                formationSpacingMeters: observer.formationSpacingMeters,
                markerColor: observer.markerColorVector
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
            checkpoints: mapCheckpoints,
            routeName: routeName,
            routeStartLabel: routeStartLabel,
            routeGoalLabel: routeGoalLabel,
            routePlannedDistanceMeters: routePlannedDistanceMeters,
            routeSectorNames: routeSectorNames,
            activeRouteID: routeSelection.activeRouteID,
            activeRouteLabel: routeSelection.activeRouteLabel,
            selectedAlternateRouteID: routeSelection.selectedAlternateRouteID,
            selectedAlternateRouteLabel: routeSelection.selectedAlternateRouteLabel,
            routeBindingStatus: routeSelection.bindingStatus,
            routeLoaderStatus: routeSelection.loaderStatus,
            routeValidationStatus: routeSelection.validationStatus,
            routeValidationRule: routeSelection.validationRule,
            routeSelectionStatus: routeSelection.selectionStatus ?? "alternate route selection pending",
            routeSelectionRule: routeSelection.selectionRule ?? "requires briefing-locked route choice before checkpoint binding",
            routeActivationStatus: routeSelection.activationStatus ?? "alternate route activation guarded",
            routeActivationRule: routeSelection.activationRule ?? "activation waits for a fresh run boundary",
            routeRollbackStatus: routeSelection.rollbackStatus ?? "alternate route rollback guarded",
            routeRollbackRule: routeSelection.rollbackRule ?? "primary route remains the fallback if alternate binding fails",
            routeCommitStatus: routeSelection.commitStatus ?? "alternate route commit pending",
            routeCommitRule: routeSelection.commitRule ?? "commit waits for staged route binding at a fresh run boundary",
            routeDryRunStatus: routeSelection.dryRunStatus ?? "alternate route dry run pending",
            routeDryRunRule: routeSelection.dryRunRule ?? "dry run must compare checkpoint order without mutating the live route",
            routePromotionStatus: routeSelection.promotionStatus ?? "alternate route promotion pending",
            routePromotionRule: routeSelection.promotionRule ?? "promotion waits for a clean dry-run review before live binding",
            routeAuditStatus: routeSelection.auditStatus ?? "alternate route audit pending",
            routeAuditRule: routeSelection.auditRule ?? "audit must prove active binding remains unchanged before promotion",
            routeBoundaryStatus: routeSelection.boundaryStatus ?? "alternate route boundary check pending",
            routeBoundaryRule: routeSelection.boundaryRule ?? "handoff remains locked to briefing or restart boundaries",
            routeArmingStatus: routeSelection.armingStatus ?? "alternate route handoff arming pending",
            routeArmingRule: routeSelection.armingRule ?? "arming requires boundary approval while live binding stays unchanged",
            routeConfirmationStatus: routeSelection.confirmationStatus ?? "alternate route handoff confirmation pending",
            routeConfirmationRule: routeSelection.confirmationRule ?? "confirmation records readiness without replacing the active route",
            routeReleaseStatus: routeSelection.releaseStatus ?? "alternate route release gate pending",
            routeReleaseRule: routeSelection.releaseRule ?? "release gate waits for explicit live-switch implementation",
            routePreflightStatus: routeSelection.preflightStatus ?? "alternate route live-switch preflight pending",
            routePreflightRule: routeSelection.preflightRule ?? "preflight records switch readiness without changing the active binding",
            routeHandoffStatus: routeSelection.handoffStatus,
            routeHandoffRule: routeSelection.handoffRule,
            collisionAuthoringStatus: collisionAuthoring.status,
            collisionAuthoringRule: routeCollisionAuthoringRule(
                collisionAuthoring,
                collisionCount: collisionCount,
                sectorCount: loadedSectors.count
            ),
            collisionAuthoringAudit: collisionAuthoring.audit,
            collisionAuthoringBlockerScope: collisionAuthoring.blockerScope,
            environmentalMotionStatus: environmentalMotion.status ?? "environmental motion pending",
            environmentalMotionRule: environmentalMotion.rule ?? "scene uses default terrain breeze",
            environmentalMotionWindSummary: environmentalMotionWindSummary(environmentalMotion),
            surfaceFidelityStatus: surfaceFidelity.status ?? "surface fidelity review pending",
            surfaceFidelityRule: surfaceFidelity.rule ?? "review environmental motion, water, SSAO, decals, and material breakup together",
            surfaceFidelitySummary: surfaceFidelitySummary,
            sessionPersistenceStatus: sessionPersistence.status ?? "session persistence planning pending",
            sessionPersistenceRule: sessionPersistence.rule ?? "capture route, checkpoint, difficulty, map, and review state before save/resume activation",
            sessionPersistenceSummary: sessionPersistenceSummary,
            reviewPackTitle: reviewPack.title,
            reviewPackSummary: reviewPack.summary,
            referenceGallery: reviewPack.referenceGallery,
            textureLibrary: reviewPack.textureLibrary,
            captureFormat: reviewPack.captureFormat,
            openRisks: reviewPack.openRisks,
            comparisonStops: mapComparisonStops,
            combatRehearsalTitle: combatRehearsal.title,
            combatRehearsalSummary: combatRehearsal.summary,
            exposureGuide: combatRehearsal.exposureGuide,
            recoveryRule: combatRehearsal.recoveryRule,
            contactStops: mapCombatStops,
            missionScriptTitle: missionScript.title,
            missionScriptSummary: missionScript.summary,
            missionPhases: mapMissionPhases,
            alternateRoutes: mapAlternateRoutes,
            threatObservers: mapThreatObservers
        )
    }

    private func plannedRouteDistance(for checkpoints: [RouteCheckpointConfiguration]) -> Float {
        zip(checkpoints, checkpoints.dropFirst()).reduce(0) { partialResult, segment in
            partialResult + simd_distance(segment.0.positionVector, segment.1.positionVector)
        }
    }

    private func routeCollisionAuthoringRule(
        _ configuration: CollisionAuthoringConfiguration,
        collisionCount: Int,
        sectorCount: Int
    ) -> String {
        "\(configuration.rule) / \(collisionCount) blockers across \(sectorCount) sectors / \(configuration.blockerScope)"
    }

    private func environmentalMotionWindSummary(_ configuration: EnvironmentalMotionConfiguration) -> String {
        let direction = configuration.windDirectionVector
        return String(
            format: "%@ / wind %.2f gust %.2f / dir %.2f %.2f / vegetation %.2f / shoreline ripple %.2f / water %.2f",
            configuration.rule ?? "scene uses default terrain breeze",
            simd_clamp(configuration.windStrength ?? 0.55, 0.0, 2.0),
            simd_clamp(configuration.gustStrength ?? 0.25, 0.0, 2.0),
            direction.x,
            direction.y,
            simd_clamp(configuration.vegetationResponse ?? 1.0, 0.0, 2.0),
            simd_clamp(configuration.shorelineRippleStrength ?? 0.18, 0.0, 1.5),
            simd_clamp(configuration.waterSurfaceResponse ?? 0.72, 0.0, 2.0)
        )
    }

    private func surfaceFidelitySummary(
        environmentalMotion: EnvironmentalMotionConfiguration,
        postProcessSettings: ScenePostProcessSettings,
        materialBreakup: MaterialBreakupConfiguration,
        roadDecalCount: Int,
        landmarkBreakupCount: Int
    ) -> String {
        String(
            format: "wind %.2f / water %.2f / SSAO %.2f r%.1f / decals %d / landmarks %d / road %.2f landmark %.2f",
            simd_clamp(environmentalMotion.windStrength ?? 0.55, 0.0, 2.0),
            simd_clamp(environmentalMotion.waterSurfaceResponse ?? 0.72, 0.0, 2.0),
            postProcessSettings.ssaoStrength,
            postProcessSettings.ssaoRadius,
            roadDecalCount,
            landmarkBreakupCount,
            simd_clamp(materialBreakup.roadScuffStrength ?? 0.42, 0.0, 1.0),
            simd_clamp(materialBreakup.landmarkBreakupStrength ?? 0.20, 0.0, 1.0)
        )
    }

    private func sessionPersistenceSummary(
        spawnCount: Int,
        checkpointCount: Int,
        alternateRouteCount: Int,
        reviewStopCount: Int,
        missionPhaseCount: Int
    ) -> String {
        String(
            format: "%d starts / %d checkpoints / %d alternate / %d review stops / %d hooks",
            spawnCount,
            checkpointCount,
            alternateRouteCount,
            reviewStopCount,
            missionPhaseCount
        )
    }

    private func routeSectorNames(
        for checkpoints: [RouteCheckpointConfiguration],
        loadedSectors: [SectorConfiguration]
    ) -> [String] {
        var names: [String] = []

        for checkpoint in checkpoints {
            let position = checkpoint.positionVector
            let containingSector = loadedSectors
                .filter { sector in
                    let minimum = sector.bounds.minimum
                    let maximum = sector.bounds.maximum
                    return position.x >= minimum.x
                        && position.x <= maximum.x
                        && position.z >= minimum.z
                        && position.z <= maximum.z
                }
                .min { lhs, rhs in
                    sectorArea(lhs) < sectorArea(rhs)
                }

            guard let displayName = containingSector?.displayName, !names.contains(displayName) else {
                continue
            }
            names.append(displayName)
        }

        return names
    }

    private func sectorArea(_ sector: SectorConfiguration) -> Float {
        let minimum = sector.bounds.minimum
        let maximum = sector.bounds.maximum
        return max(maximum.x - minimum.x, 1) * max(maximum.z - minimum.z, 1)
    }

    private func combinedBounds(
        for loadedSectors: [SectorConfiguration],
        fallback: SIMD3<Float>
    ) -> (minX: Float, maxX: Float, minZ: Float, maxZ: Float) {
        let minX = loadedSectors.map { $0.bounds.minimum.x }.min() ?? (fallback.x - 80)
        let maxX = loadedSectors.map { $0.bounds.maximum.x }.max() ?? (fallback.x + 80)
        let minZ = loadedSectors.map { $0.bounds.minimum.z }.min() ?? (fallback.z - 80)
        let maxZ = loadedSectors.map { $0.bounds.maximum.z }.max() ?? (fallback.z + 80)
        return (minX, maxX, minZ, maxZ)
    }

    private func sector(
        containing position: SIMD3<Float>,
        in loadedSectors: [SectorConfiguration]
    ) -> SectorConfiguration? {
        loadedSectors.first { sector in
            let minimum = sector.bounds.minimum
            let maximum = sector.bounds.maximum
            return position.x >= minimum.x &&
                position.x <= maximum.x &&
                position.z >= minimum.z &&
                position.z <= maximum.z
        }
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
                minimumViewDot: -1,
                textureKey: nil,
                material: legacyMaterial(
                    textureKey: nil,
                    overrides: configuration.material,
                    roughnessFactor: 0.96
                ),
                retainedInJungleRenderer: false
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
                minimumViewDot: -0.65,
                textureKey: .terrain,
                material: legacyMaterial(
                    textureKey: .terrain,
                    overrides: configuration.material
                ),
                retainedInJungleRenderer: true,
                castsShadow: configuration.castsShadow ?? true,
                receivesShadow: configuration.receivesShadow ?? true
            )
        }
    }

    private func grayboxDrawable(
        from configuration: GrayboxBlockConfiguration,
        sectorID: String,
        residency: SectorResidency,
        landmarkBreakupStrength: Float
    ) -> SceneDrawable? {
        let vertices = GeometryBuilder.makeBox(
            halfExtents: configuration.halfExtentsVector,
            color: configuration.colorVector
        )

        guard let buffer = makeBuffer(from: vertices) else {
            return nil
        }

        let normalizedName = configuration.name.lowercased()
        let isWaterSurface = usesWaterMaterial(for: normalizedName)
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
            minimumViewDot: visibilityMinimumViewDot(-0.55, for: residency),
            textureKey: isWaterSurface ? .water : .concrete,
            material: grayboxMaterial(
                for: configuration,
                sectorID: sectorID,
                landmarkBreakupStrength: landmarkBreakupStrength
            ),
            retainedInJungleRenderer: true,
            castsShadow: isWaterSurface ? false : (configuration.castsShadow ?? true),
            receivesShadow: configuration.receivesShadow ?? true
        )
    }

    private func grayboxShadowDrawable(from configuration: GrayboxBlockConfiguration, sectorID: String) -> SceneDrawable? {
        let normalizedName = configuration.name.lowercased()
        guard !usesWaterMaterial(for: normalizedName) else {
            return nil
        }

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
            minimumViewDot: -0.7,
            textureKey: nil,
            retainedInJungleRenderer: false
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
            minimumViewDot: -1,
            textureKey: .terrain,
            material: legacyMaterial(
                textureKey: .terrain,
                overrides: configuration.material
            ),
            retainedInJungleRenderer: false
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
            minimumViewDot: -1,
            textureKey: .road,
            material: roadMaterial(
                for: configuration,
                sectorID: sectorID
            ),
            retainedInJungleRenderer: false
        )
    }

    private func roadDecalDrawables(
        from configuration: RoadStripConfiguration,
        sectorID: String,
        residency: SectorResidency,
        density: Float,
        strength: Float
    ) -> [SceneDrawable] {
        let count = max(
            1,
            min(
                Int(ceil((configuration.sizeVector.y / 46.0) * density)),
                8
            )
        )
        let baseColor = configuration.roadColorVector
        let decalColor = SIMD4<Float>(
            max(baseColor.x * (0.50 + strength * 0.16), 0.015),
            max(baseColor.y * (0.50 + strength * 0.16), 0.015),
            max(baseColor.z * (0.50 + strength * 0.16), 0.015),
            1.0
        )
        let vertices = GeometryBuilder.makeRoadSurfaceDecals(
            size: configuration.sizeVector,
            shoulderWidth: configuration.shoulderWidth ?? 1.2,
            crownHeight: configuration.crownHeight ?? 0.04,
            count: count,
            strength: strength,
            color: decalColor
        )

        guard !vertices.isEmpty, let buffer = makeBuffer(from: vertices) else {
            return []
        }

        let rotation = simd_float4x4.rotation(y: (configuration.yawDegrees ?? 0) * (.pi / 180.0))
        let radius = simd_length(SIMD3<Float>(configuration.sizeVector.x * 0.5, 0.5, configuration.sizeVector.y * 0.5))
        return [
            SceneDrawable(
                name: "\(sectorID):\(configuration.name):RoadBreakup",
                vertexBuffer: buffer,
                vertexCount: vertices.count,
                modelMatrix: simd_float4x4.translation(configuration.positionVector + SIMD3<Float>(0, 0.018, 0)) * rotation,
                worldCenter: configuration.positionVector,
                boundingRadius: radius,
                maxDrawDistance: adaptiveDrawDistance(
                    defaultValue: visibilityDefault(140, for: residency),
                    boundingRadius: radius,
                    multiplier: visibilityMultiplier(2.4, for: residency)
                ),
                minimumViewDot: -1,
                textureKey: nil,
                material: legacyMaterial(
                    textureKey: nil,
                    overrides: nil,
                    roughnessFactor: 0.92
                ),
                retainedInJungleRenderer: false,
                castsShadow: false,
                receivesShadow: true
            )
        ]
    }

    private func continuityGroundDrawable(
        from surfaces: [GameGroundSurface],
        bounds: (minX: Float, maxX: Float, minZ: Float, maxZ: Float)
    ) -> SceneDrawable? {
        guard !surfaces.isEmpty else {
            return nil
        }

        let vertices = GeometryBuilder.makeGroundContinuity(
            from: surfaces,
            verticalBias: -0.12,
            color: SIMD4<Float>(0.37, 0.44, 0.32, 1.0)
        )

        guard let buffer = makeBuffer(from: vertices) else {
            return nil
        }

        let center = SIMD3<Float>(
            (bounds.minX + bounds.maxX) * 0.5,
            0,
            (bounds.minZ + bounds.maxZ) * 0.5
        )
        let radius = simd_length(
            SIMD3<Float>(
                (bounds.maxX - bounds.minX) * 0.5,
                24,
                (bounds.maxZ - bounds.minZ) * 0.5
            )
        )

        return SceneDrawable(
            name: "GlobalGroundContinuity",
            vertexBuffer: buffer,
            vertexCount: vertices.count,
            modelMatrix: .identity(),
            worldCenter: center,
            boundingRadius: radius,
            maxDrawDistance: max(bounds.maxX - bounds.minX, bounds.maxZ - bounds.minZ) * 2.4,
            minimumViewDot: -1,
            textureKey: .terrain,
            material: legacyMaterial(
                textureKey: .terrain,
                overrides: nil
            ),
            retainedInJungleRenderer: false
        )
    }

    private func assetDrawables(
        from configuration: AssetInstanceConfiguration,
        groundSampler: WorldGroundSurfaceSampler
    ) -> [SceneDrawable] {
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
            return []
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
        let groundedPosition = WorldRuntimeConversions.groundedPosition(
            for: configuration.positionVector,
            groundSampler: groundSampler
        )
        let worldCenter = groundedPosition + SIMD3<Float>(0, worldExtent.y * 0.5, 0)
        let modelMatrix = simd_float4x4.translation(groundedPosition) * rotation * normalization
        let drawDistance = adaptiveDrawDistance(
            defaultValue: 90,
            boundingRadius: simd_length(worldExtent) * 0.5,
            multiplier: 3.2
        )

        var drawables: [SceneDrawable] = []
        drawables.reserveCapacity(loadedAsset.submeshes.count)

        for submesh in loadedAsset.submeshes {
            guard let buffer = makeBuffer(from: submesh.vertices) else {
                continue
            }

            drawables.append(
                SceneDrawable(
                    name: "\(configuration.name):\(submesh.name)",
                    vertexBuffer: buffer,
                    vertexCount: submesh.vertices.count,
                    modelMatrix: modelMatrix,
                    worldCenter: worldCenter,
                    boundingRadius: simd_length(worldExtent) * 0.5,
                    maxDrawDistance: drawDistance,
                    minimumViewDot: -0.45,
                    textureKey: nil,
                    material: submesh.material.applying(configuration: configuration.material),
                    retainedInJungleRenderer: true,
                    castsShadow: configuration.castsShadow ?? true,
                    receivesShadow: configuration.receivesShadow ?? true
                )
            )
        }

        return drawables
    }

    private func routeMarkerDrawables(
        from configuration: RouteCheckpointConfiguration,
        groundSampler: WorldGroundSurfaceSampler
    ) -> [SceneDrawable] {
        let beaconHeight = configuration.beaconHeight ?? ((configuration.goal ?? false) ? 6.0 : 4.8)
        let beaconColor = configuration.beaconColorVector
        let markerPosition = WorldRuntimeConversions.groundedPosition(
            for: configuration.positionVector,
            groundSampler: groundSampler
        )
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
                    minimumViewDot: -0.92,
                    textureKey: nil,
                    retainedInJungleRenderer: true
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
                    minimumViewDot: -0.92,
                    textureKey: nil,
                    retainedInJungleRenderer: true
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
                    minimumViewDot: -0.85,
                    textureKey: nil,
                    retainedInJungleRenderer: false
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
                    minimumViewDot: -0.85,
                    textureKey: nil,
                    retainedInJungleRenderer: true
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
                    minimumViewDot: -0.88,
                    textureKey: nil,
                    retainedInJungleRenderer: true
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
                    minimumViewDot: -0.86,
                    textureKey: nil,
                    retainedInJungleRenderer: false
                )
            )
        }

        return drawables
    }

    private func guidanceDrawables(
        from configuration: GuidancePointConfiguration,
        groundSampler: WorldGroundSurfaceSampler
    ) -> [SceneDrawable] {
        let markerPosition = WorldRuntimeConversions.groundedPosition(
            for: configuration.positionVector,
            groundSampler: groundSampler
        )
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
                        minimumViewDot: -0.82,
                        textureKey: nil,
                        retainedInJungleRenderer: true
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
                        minimumViewDot: -0.9,
                        textureKey: nil,
                        retainedInJungleRenderer: true
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
                        minimumViewDot: -0.9,
                        textureKey: nil,
                        retainedInJungleRenderer: true
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
                    minimumViewDot: -0.82,
                    textureKey: nil,
                    retainedInJungleRenderer: false
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

    private func legacyMaterial(
        textureKey: SceneTextureKey?,
        overrides: MaterialConfiguration?,
        roughnessFactor: Float? = nil
    ) -> SceneMaterial {
        SceneMaterial
            .legacy(
                textureKey: textureKey,
                roughnessFactor: roughnessFactor ?? defaultRoughness(for: textureKey)
            )
            .applying(configuration: overrides)
    }

    private func facadeMaterial(
        overrides: MaterialConfiguration?,
        baseColorFactor: SIMD4<Float> = SIMD4<Float>(1, 1, 1, 1),
        roughnessFactor: Float = 0.74,
        normalScale: Float = 1.0
    ) -> SceneMaterial {
        SceneMaterial(
            albedoTexture: .assetRelativePath("Textures/Final/canberra_civic_facade_albedo.png"),
            normalTexture: .assetRelativePath("Textures/Final/canberra_civic_facade_normal.png"),
            roughnessTexture: .assetRelativePath("Textures/Final/canberra_civic_facade_roughness.png"),
            ambientOcclusionTexture: .assetRelativePath("Textures/Final/canberra_civic_facade_ao.png"),
            baseColorFactor: baseColorFactor,
            roughnessFactor: roughnessFactor,
            ambientOcclusionStrength: 1.0,
            normalScale: normalScale
        ).applying(configuration: overrides)
    }

    private func concreteMaterial(overrides: MaterialConfiguration?) -> SceneMaterial {
        SceneMaterial(
            albedoTexture: .assetRelativePath("Textures/Final/canberra_concrete_texture.png"),
            normalTexture: .assetRelativePath("Textures/Final/canberra_concrete_normal.png"),
            roughnessTexture: .assetRelativePath("Textures/Final/canberra_concrete_roughness.png"),
            ambientOcclusionTexture: .assetRelativePath("Textures/Final/canberra_concrete_ao.png"),
            baseColorFactor: SIMD4<Float>(1, 1, 1, 1),
            roughnessFactor: 0.84,
            ambientOcclusionStrength: 1.0,
            normalScale: 1.0
        ).applying(configuration: overrides)
    }

    private func waterMaterial(overrides: MaterialConfiguration?) -> SceneMaterial {
        SceneMaterial(
            albedoTexture: .sceneKey(.water),
            normalTexture: nil,
            roughnessTexture: nil,
            ambientOcclusionTexture: nil,
            baseColorFactor: SIMD4<Float>(0.88, 0.98, 1.08, 1.0),
            roughnessFactor: 0.16,
            ambientOcclusionStrength: 0.35,
            normalScale: 0.65
        ).applying(configuration: overrides)
    }

    private func arterialRoadMaterial(overrides: MaterialConfiguration?) -> SceneMaterial {
        SceneMaterial(
            albedoTexture: .assetRelativePath("Textures/Final/canberra_arterial_asphalt_albedo.png"),
            normalTexture: .assetRelativePath("Textures/Final/canberra_arterial_asphalt_normal.png"),
            roughnessTexture: .assetRelativePath("Textures/Final/canberra_arterial_asphalt_roughness.png"),
            ambientOcclusionTexture: .assetRelativePath("Textures/Final/canberra_arterial_asphalt_ao.png"),
            baseColorFactor: SIMD4<Float>(1, 1, 1, 1),
            roughnessFactor: 0.86,
            ambientOcclusionStrength: 1.0,
            normalScale: 1.0
        ).applying(configuration: overrides)
    }

    private func grayboxMaterial(
        for configuration: GrayboxBlockConfiguration,
        sectorID: String,
        landmarkBreakupStrength: Float
    ) -> SceneMaterial {
        let normalizedName = "\(sectorID) \(configuration.name)".lowercased()
        if usesWaterMaterial(for: configuration.name.lowercased()) {
            return waterMaterial(overrides: configuration.material)
        }

        if usesHardscapeMaterial(for: normalizedName, configuration: configuration) {
            return concreteMaterial(overrides: configuration.material)
        }

        if usesFacadeMaterial(for: normalizedName) {
            return landmarkFacadeMaterial(
                for: normalizedName,
                overrides: configuration.material,
                strength: landmarkBreakupStrength
            )
        }

        return configuration.halfExtentsVector.y <= 1.4
            ? concreteMaterial(overrides: configuration.material)
            : landmarkFacadeMaterial(
                for: normalizedName,
                overrides: configuration.material,
                strength: landmarkBreakupStrength
            )
    }

    private func landmarkFacadeMaterial(
        for normalizedName: String,
        overrides: MaterialConfiguration?,
        strength: Float
    ) -> SceneMaterial {
        guard usesLandmarkBreakupMaterial(for: normalizedName), strength > 0 else {
            return facadeMaterial(overrides: overrides)
        }

        let profile = landmarkBreakupProfile(for: normalizedName, strength: strength)
        return facadeMaterial(
            overrides: overrides,
            baseColorFactor: profile.tint,
            roughnessFactor: profile.roughness,
            normalScale: profile.normalScale
        )
    }

    private func roadMaterial(
        for configuration: RoadStripConfiguration,
        sectorID: String
    ) -> SceneMaterial {
        let normalizedName = "\(sectorID) \(configuration.name)".lowercased()
        return usesPedestrianPavingMaterial(for: normalizedName)
            ? concreteMaterial(overrides: configuration.material)
            : arterialRoadMaterial(overrides: configuration.material)
    }

    private func usesHardscapeMaterial(
        for normalizedName: String,
        configuration: GrayboxBlockConfiguration
    ) -> Bool {
        if configuration.contributesToGroundSurface {
            return true
        }

        if normalizedName.contains("telstratowercore") || normalizedName.contains("towerdeck") {
            return true
        }

        let tokens = [
            "wall", "barrier", "median", "divider", "edge", "screen", "promenade",
            "footing", "pylon", "retaining", "plinth", "pad", "deck", "marker",
            "forecourt", "boundary", "backstop", "fence", "lookout", "apron",
            "bridge", "interchange", "causeway"
        ]
        if tokens.contains(where: normalizedName.contains) {
            return true
        }

        if normalizedName.contains("frame") && !usesFacadeMaterial(for: normalizedName) {
            return true
        }

        return configuration.halfExtentsVector.y <= 0.9
    }

    private func usesWaterMaterial(for normalizedName: String) -> Bool {
        normalizedName.contains("lake") || normalizedName.contains("water")
    }

    private func usesFacadeMaterial(for normalizedName: String) -> Bool {
        let tokens = [
            "mass", "office", "hotel", "administrative", "gallery", "campus",
            "arena", "mall", "towncentre", "towncenter", "tower", "civic",
            "museum", "shelter", "club", "embassy", "block", "spine",
            "group", "cluster", "centre", "center", "podium", "band"
        ]
        return tokens.contains(where: normalizedName.contains)
    }

    private func usesLandmarkBreakupMaterial(for normalizedName: String) -> Bool {
        let tokens = [
            "parliament", "capitalhill", "civic", "library", "gallery",
            "museum", "telstra", "blackmountain", "belconnen", "woden",
            "arena", "mall", "campus", "tower", "embassy", "cluster",
            "towncentre", "towncenter"
        ]
        return tokens.contains(where: normalizedName.contains) && !usesWaterMaterial(for: normalizedName)
    }

    private func landmarkBreakupProfile(
        for normalizedName: String,
        strength: Float
    ) -> (tint: SIMD4<Float>, roughness: Float, normalScale: Float) {
        let clampedStrength = simd_clamp(strength, 0.0, 1.0)
        let tint: SIMD4<Float>
        let roughnessBase: Float

        if normalizedName.contains("parliament") || normalizedName.contains("capitalhill") {
            tint = SIMD4<Float>(1.02, 1.03, 0.96, 1.0)
            roughnessBase = 0.82
        } else if normalizedName.contains("telstra") || normalizedName.contains("blackmountain") || normalizedName.contains("tower") {
            tint = SIMD4<Float>(0.88, 0.94, 1.04, 1.0)
            roughnessBase = 0.68
        } else if normalizedName.contains("belconnen") || normalizedName.contains("woden") || normalizedName.contains("mall") {
            tint = SIMD4<Float>(0.98, 0.94, 0.90, 1.0)
            roughnessBase = 0.78
        } else if normalizedName.contains("gallery") || normalizedName.contains("museum") || normalizedName.contains("library") {
            tint = SIMD4<Float>(1.04, 1.01, 0.94, 1.0)
            roughnessBase = 0.76
        } else {
            tint = SIMD4<Float>(0.96, 0.99, 1.03, 1.0)
            roughnessBase = 0.74
        }

        let blendedTint = SIMD4<Float>(
            1.0 + ((tint.x - 1.0) * clampedStrength),
            1.0 + ((tint.y - 1.0) * clampedStrength),
            1.0 + ((tint.z - 1.0) * clampedStrength),
            1.0
        )
        return (
            tint: blendedTint,
            roughness: simd_clamp(0.74 + ((roughnessBase - 0.74) * clampedStrength), 0.45, 0.95),
            normalScale: simd_clamp(1.0 + (clampedStrength * 0.35), 0.0, 1.6)
        )
    }

    private func usesPedestrianPavingMaterial(for normalizedName: String) -> Bool {
        let tokens = [
            "promenade", "walk", "forecourt", "apron", "lookout", "plaza"
        ]
        return tokens.contains { normalizedName.contains($0) }
    }

    private func defaultRoughness(for textureKey: SceneTextureKey?) -> Float {
        switch textureKey {
        case .terrain:
            return 0.94
        case .road:
            return 0.76
        case .concrete:
            return 0.84
        case .water:
            return 0.18
        case nil:
            return 0.90
        }
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
                    minimumViewDot: -1,
                    textureKey: nil,
                    retainedInJungleRenderer: false
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
                hazeStrength: 0.14,
                shadow: SceneShadowSettings(
                    mapResolution: 2048,
                    coverage: 120,
                    depthBias: 0.015,
                    normalBias: 0.010,
                    strength: 0.72,
                    scopeCoverageMultiplier: 1.25,
                    forwardOffsetMultiplier: 0.35
                ),
                postProcess: ScenePostProcessSettings(
                    exposureBias: 0.18,
                    whitePoint: 1.25,
                    contrast: 1.04,
                    saturation: 1.02,
                    shadowTint: SIMD4<Float>(0.95, 0.99, 1.04, 1.0),
                    highlightTint: SIMD4<Float>(1.04, 1.01, 0.95, 1.0),
                    shadowBalance: 0.44,
                    vignetteStrength: 0.08,
                    ssaoStrength: 0.0,
                    ssaoRadius: 1.6,
                    ssaoBias: 0.0008
                )
            ),
            scopeConfiguration: ScopeConfiguration(),
            ballisticsSettings: SceneBallisticsSettings(
                muzzleVelocityMetersPerSecond: 820.0,
                gravityMetersPerSecondSquared: 9.81,
                maxSimulationTimeSeconds: 2.4,
                simulationStepSeconds: 1.0 / 120.0,
                launchHeightOffsetMeters: 0.0,
                scopedSpreadDegrees: 0.10,
                hipSpreadDegrees: 0.65,
                movementSpreadDegrees: 1.10,
                sprintSpreadDegrees: 1.80,
                settleDurationSeconds: 0.60,
                breathCycleSeconds: 3.40,
                breathAmplitudeDegrees: 0.16,
                holdBreathDurationSeconds: 2.60,
                holdBreathRecoverySeconds: 3.60
            ),
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
                checkpoints: [],
                routeName: "Fallback Route",
                routeStartLabel: "Fallback start",
                routeGoalLabel: "Fallback goal",
                routePlannedDistanceMeters: 0,
                routeSectorNames: [],
                activeRouteID: "fallback",
                activeRouteLabel: "Fallback Route",
                selectedAlternateRouteID: nil,
                selectedAlternateRouteLabel: nil,
                routeBindingStatus: "fallback route bound",
                routeLoaderStatus: "alternate route loader unavailable",
                routeValidationStatus: "route validation unavailable",
                routeValidationRule: "fallback scene has no staged route",
                routeSelectionStatus: "route selection unavailable",
                routeSelectionRule: "fallback scene has no staged route",
                routeActivationStatus: "route activation unavailable",
                routeActivationRule: "fallback scene has no staged route",
                routeRollbackStatus: "route rollback unavailable",
                routeRollbackRule: "fallback scene has no staged route",
                routeCommitStatus: "route commit unavailable",
                routeCommitRule: "fallback scene has no staged route",
                routeDryRunStatus: "route dry run unavailable",
                routeDryRunRule: "fallback scene has no staged route",
                routePromotionStatus: "route promotion unavailable",
                routePromotionRule: "fallback scene has no staged route",
                routeAuditStatus: "route audit unavailable",
                routeAuditRule: "fallback scene has no staged route",
                routeBoundaryStatus: "route boundary unavailable",
                routeBoundaryRule: "fallback scene has no staged route",
                routeArmingStatus: "route arming unavailable",
                routeArmingRule: "fallback scene has no staged route",
                routeConfirmationStatus: "route confirmation unavailable",
                routeConfirmationRule: "fallback scene has no staged route",
                routeReleaseStatus: "route release unavailable",
                routeReleaseRule: "fallback scene has no staged route",
                routePreflightStatus: "route preflight unavailable",
                routePreflightRule: "fallback scene has no staged route",
                routeHandoffStatus: "route handoff unavailable",
                routeHandoffRule: "fallback scene has no staged route",
                collisionAuthoringStatus: "collision authoring unavailable",
                collisionAuthoringRule: "fallback scene has no collision blockers",
                collisionAuthoringAudit: "fallback audit unavailable",
                collisionAuthoringBlockerScope: "fallback blockers unavailable",
                environmentalMotionStatus: "environmental motion unavailable",
                environmentalMotionRule: "fallback scene has no authored terrain motion",
                environmentalMotionWindSummary: "fallback scene has no authored terrain motion / wind 0.00 gust 0.00",
                surfaceFidelityStatus: "surface fidelity unavailable",
                surfaceFidelityRule: "fallback scene has no environmental fidelity stack",
                surfaceFidelitySummary: "fallback scene has no surface fidelity stack",
                sessionPersistenceStatus: "session persistence unavailable",
                sessionPersistenceRule: "fallback scene has no resumable route state",
                sessionPersistenceSummary: "fallback scene has no session persistence plan",
                reviewPackTitle: "Fallback Review Pack",
                reviewPackSummary: "Review pack data unavailable",
                referenceGallery: "Unavailable",
                textureLibrary: "Unavailable",
                captureFormat: "Unavailable",
                openRisks: [],
                comparisonStops: [],
                combatRehearsalTitle: "Fallback Combat Rehearsal",
                combatRehearsalSummary: "Combat rehearsal data unavailable",
                exposureGuide: "Unavailable",
                recoveryRule: "Unavailable",
                contactStops: [],
                missionScriptTitle: "Fallback Mission Script",
                missionScriptSummary: "Mission script data unavailable",
                missionPhases: [],
                alternateRoutes: [],
                threatObservers: []
            ),
            sectors: [],
            groundModel: WorldGroundModel(
                localSurfaces: [],
                continuitySurfaces: [],
                allSurfaces: [],
                sampler: WorldGroundSurfaceSampler(surfaces: [])
            ),
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
                checkpoints: [],
                startLabel: "Fallback start",
                goalLabel: "Fallback goal",
                plannedDistanceMeters: 0,
                sectorNames: [],
                missionTitle: "Fallback Mission Script",
                missionSummary: "Mission script data unavailable",
                missionPhases: [],
                routeSelection: RouteSelectionConfiguration(
                    activeRouteID: "fallback",
                    activeRouteLabel: "Fallback Route",
                    selectedAlternateRouteID: nil,
                    selectedAlternateRouteLabel: nil,
                    bindingStatus: "fallback route bound",
                    loaderStatus: "alternate route loader unavailable",
                    validationStatus: "route validation unavailable",
                    validationRule: "fallback scene has no staged route",
                    selectionStatus: "route selection unavailable",
                    selectionRule: "fallback scene has no staged route",
                    activationStatus: "route activation unavailable",
                    activationRule: "fallback scene has no staged route",
                    rollbackStatus: "route rollback unavailable",
                    rollbackRule: "fallback scene has no staged route",
                    commitStatus: "route commit unavailable",
                    commitRule: "fallback scene has no staged route",
                    dryRunStatus: "route dry run unavailable",
                    dryRunRule: "fallback scene has no staged route",
                    promotionStatus: "route promotion unavailable",
                    promotionRule: "fallback scene has no staged route",
                    auditStatus: "route audit unavailable",
                    auditRule: "fallback scene has no staged route",
                    boundaryStatus: "route boundary unavailable",
                    boundaryRule: "fallback scene has no staged route",
                    armingStatus: "route arming unavailable",
                    armingRule: "fallback scene has no staged route",
                    confirmationStatus: "route confirmation unavailable",
                    confirmationRule: "fallback scene has no staged route",
                    releaseStatus: "route release unavailable",
                    releaseRule: "fallback scene has no staged route",
                    preflightStatus: "route preflight unavailable",
                    preflightRule: "fallback scene has no staged route",
                    handoffStatus: "route handoff unavailable",
                    handoffRule: "fallback scene has no staged route"
                ),
                alternateRoutes: []
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
            ),
            environmentalMotion: EnvironmentalMotionConfiguration(
                status: "environmental motion unavailable",
                rule: "fallback scene has no authored terrain motion",
                windDirection: [0.86, 0.50],
                windStrength: 0.0,
                gustStrength: 0.0,
                vegetationResponse: 0.0,
                shorelineRippleStrength: 0.0
            ),
            spawnOptions: [
                SpawnConfiguration(
                    label: "Fallback start",
                    position: [0, 1.65, 6],
                    yawDegrees: 0,
                    pitchDegrees: -10
                )
            ]
        )
    }
}

private struct LoadedAssetSubmesh {
    let name: String
    let vertices: [SceneVertex]
    let material: SceneMaterial
}

private struct LoadedAsset {
    let submeshes: [LoadedAssetSubmesh]
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
                    uv0: SIMD2<Float>(0, 0),
                    uv1: SIMD2<Float>(1, 0),
                    uv2: SIMD2<Float>(1, 1),
                    uv3: SIMD2<Float>(0, 1),
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
        let widthRepeat = textureRepeat(for: halfExtents.x * 2, metersPerTile: 4.5)
        let heightRepeat = textureRepeat(for: halfExtents.y * 2, metersPerTile: 4.5)
        let depthRepeat = textureRepeat(for: halfExtents.z * 2, metersPerTile: 4.5)

        appendQuad(
            to: &vertices,
            p0: frontBottomLeft,
            p1: frontBottomRight,
            p2: frontTopRight,
            p3: frontTopLeft,
            uv0: SIMD2<Float>(0, heightRepeat),
            uv1: SIMD2<Float>(widthRepeat, heightRepeat),
            uv2: SIMD2<Float>(widthRepeat, 0),
            uv3: SIMD2<Float>(0, 0),
            color: color
        )
        appendQuad(
            to: &vertices,
            p0: backBottomRight,
            p1: backBottomLeft,
            p2: backTopLeft,
            p3: backTopRight,
            uv0: SIMD2<Float>(0, heightRepeat),
            uv1: SIMD2<Float>(widthRepeat, heightRepeat),
            uv2: SIMD2<Float>(widthRepeat, 0),
            uv3: SIMD2<Float>(0, 0),
            color: color
        )
        appendQuad(
            to: &vertices,
            p0: backBottomLeft,
            p1: frontBottomLeft,
            p2: frontTopLeft,
            p3: backTopLeft,
            uv0: SIMD2<Float>(0, heightRepeat),
            uv1: SIMD2<Float>(depthRepeat, heightRepeat),
            uv2: SIMD2<Float>(depthRepeat, 0),
            uv3: SIMD2<Float>(0, 0),
            color: color
        )
        appendQuad(
            to: &vertices,
            p0: frontBottomRight,
            p1: backBottomRight,
            p2: backTopRight,
            p3: frontTopRight,
            uv0: SIMD2<Float>(0, heightRepeat),
            uv1: SIMD2<Float>(depthRepeat, heightRepeat),
            uv2: SIMD2<Float>(depthRepeat, 0),
            uv3: SIMD2<Float>(0, 0),
            color: color
        )
        appendQuad(
            to: &vertices,
            p0: frontTopLeft,
            p1: frontTopRight,
            p2: backTopRight,
            p3: backTopLeft,
            uv0: SIMD2<Float>(0, 0),
            uv1: SIMD2<Float>(widthRepeat, 0),
            uv2: SIMD2<Float>(widthRepeat, depthRepeat),
            uv3: SIMD2<Float>(0, depthRepeat),
            color: color
        )
        appendQuad(
            to: &vertices,
            p0: backBottomLeft,
            p1: backBottomRight,
            p2: frontBottomRight,
            p3: frontBottomLeft,
            uv0: SIMD2<Float>(0, 0),
            uv1: SIMD2<Float>(widthRepeat, 0),
            uv2: SIMD2<Float>(widthRepeat, depthRepeat),
            uv3: SIMD2<Float>(0, depthRepeat),
            color: color
        )

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
        let widthRepeat = textureRepeat(for: width, metersPerTile: 10.0)
        let depthRepeat = textureRepeat(for: depth, metersPerTile: 10.0)
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
                    uv0: SIMD2<Float>(u0 * widthRepeat, v0 * depthRepeat),
                    uv1: SIMD2<Float>(u1 * widthRepeat, v0 * depthRepeat),
                    uv2: SIMD2<Float>(u1 * widthRepeat, v1 * depthRepeat),
                    uv3: SIMD2<Float>(u0 * widthRepeat, v1 * depthRepeat),
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
        let widthRepeat = textureRepeat(for: size.x, metersPerTile: 2.2)
        let lengthRepeat = textureRepeat(for: size.y, metersPerTile: 9.0)
        var vertices: [SceneVertex] = []

        let strips: [(Float, Float, SIMD4<Float>)] = [
            (-halfWidth, -halfWidth + clampedShoulderWidth, shoulderColor),
            (-halfWidth + clampedShoulderWidth, -clampedCenterLine * 0.5, roadColor),
            (-clampedCenterLine * 0.5, clampedCenterLine * 0.5, lineColor),
            (clampedCenterLine * 0.5, halfWidth - clampedShoulderWidth, roadColor),
            (halfWidth - clampedShoulderWidth, halfWidth, shoulderColor),
        ]

        for (x0, x1, color) in strips where x1 > x0 {
            let u0 = ((x0 + halfWidth) / (halfWidth * 2.0)) * widthRepeat
            let u1 = ((x1 + halfWidth) / (halfWidth * 2.0)) * widthRepeat
            appendQuad(
                to: &vertices,
                p0: SIMD3<Float>(x0, roadCrownHeight(x: x0, halfWidth: halfWidth, crownHeight: crownHeight), -halfDepth),
                p1: SIMD3<Float>(x1, roadCrownHeight(x: x1, halfWidth: halfWidth, crownHeight: crownHeight), -halfDepth),
                p2: SIMD3<Float>(x1, roadCrownHeight(x: x1, halfWidth: halfWidth, crownHeight: crownHeight), halfDepth),
                p3: SIMD3<Float>(x0, roadCrownHeight(x: x0, halfWidth: halfWidth, crownHeight: crownHeight), halfDepth),
                uv0: SIMD2<Float>(u0, 0),
                uv1: SIMD2<Float>(u1, 0),
                uv2: SIMD2<Float>(u1, lengthRepeat),
                uv3: SIMD2<Float>(u0, lengthRepeat),
                color: color
            )
        }

        return vertices
    }

    static func makeRoadSurfaceDecals(
        size: SIMD2<Float>,
        shoulderWidth: Float,
        crownHeight: Float,
        count: Int,
        strength: Float,
        color: SIMD4<Float>
    ) -> [SceneVertex] {
        let halfWidth = max(size.x * 0.5, 0.5)
        let halfDepth = max(size.y * 0.5, 0.5)
        let clampedShoulderWidth = min(max(shoulderWidth, 0.1), halfWidth * 0.45)
        let laneInset = clampedShoulderWidth + 0.28
        let laneHalfWidth = max(halfWidth - laneInset, halfWidth * 0.28)
        let decalCount = max(count, 0)
        guard decalCount > 0, laneHalfWidth > 0.2 else {
            return []
        }

        var vertices: [SceneVertex] = []
        vertices.reserveCapacity(decalCount * 6)

        for index in 0..<decalCount {
            let fraction = (Float(index) + 0.5) / Float(decalCount)
            let alternatingSide: Float = index.isMultiple(of: 2) ? -1.0 : 1.0
            let lateral = alternatingSide * laneHalfWidth * (0.34 + 0.17 * Float(index % 3))
            let length = min(max(size.y * (0.045 + strength * 0.035), 2.4), 8.5)
            let width = min(max(size.x * (0.055 + strength * 0.045), 0.45), max(laneHalfWidth * 0.52, 0.55))
            let centerZ = (-halfDepth + length) + (fraction * max((halfDepth * 2.0) - (length * 2.0), 0.1))
            let skew = alternatingSide * width * 0.28
            let x0 = lateral - width * 0.5
            let x1 = lateral + width * 0.5
            let z0 = centerZ - length * 0.5
            let z1 = centerZ + length * 0.5
            let y0 = roadCrownHeight(x: x0, halfWidth: halfWidth, crownHeight: crownHeight) + 0.026
            let y1 = roadCrownHeight(x: x1, halfWidth: halfWidth, crownHeight: crownHeight) + 0.026
            let decalTint = SIMD4<Float>(
                color.x * (0.88 + Float(index % 3) * 0.04),
                color.y * (0.88 + Float(index % 3) * 0.04),
                color.z * (0.88 + Float(index % 3) * 0.04),
                color.w
            )

            appendQuad(
                to: &vertices,
                p0: SIMD3<Float>(x0, y0, z0),
                p1: SIMD3<Float>(x1, y1, z0 + skew),
                p2: SIMD3<Float>(x1, y1, z1 + skew),
                p3: SIMD3<Float>(x0, y0, z1),
                uv0: SIMD2<Float>(0, 0),
                uv1: SIMD2<Float>(1, 0),
                uv2: SIMD2<Float>(1, 1),
                uv3: SIMD2<Float>(0, 1),
                color: decalTint
            )
        }

        return vertices
    }

    static func makeGroundContinuity(
        from surfaces: [GameGroundSurface],
        verticalBias: Float,
        color: SIMD4<Float>
    ) -> [SceneVertex] {
        var vertices: [SceneVertex] = []
        vertices.reserveCapacity(surfaces.count * 6)

        for surface in surfaces {
            let halfWidth = surface.halfWidth
            let halfDepth = surface.halfDepth
            let corners = [
                SIMD3<Float>(-halfWidth, surface.northWestHeight + verticalBias, -halfDepth),
                SIMD3<Float>(halfWidth, surface.northEastHeight + verticalBias, -halfDepth),
                SIMD3<Float>(halfWidth, surface.southEastHeight + verticalBias, halfDepth),
                SIMD3<Float>(-halfWidth, surface.southWestHeight + verticalBias, halfDepth),
            ]
            let rotation = simd_float4x4.rotation(y: surface.yawDegrees * (.pi / 180.0))
            let translation = simd_float4x4.translation(SIMD3<Float>(surface.centerX, 0, surface.centerZ))

            let worldCorners = corners.map { corner in
                let rotated = rotation * SIMD4<Float>(corner.x, corner.y, corner.z, 1)
                let positioned = translation * rotated
                return SIMD3<Float>(positioned.x, positioned.y, positioned.z)
            }

            appendQuad(
                to: &vertices,
                p0: worldCorners[0],
                p1: worldCorners[1],
                p2: worldCorners[2],
                p3: worldCorners[3],
                uv0: SIMD2<Float>(0, 0),
                uv1: SIMD2<Float>(1, 0),
                uv2: SIMD2<Float>(1, 1),
                uv3: SIMD2<Float>(0, 1),
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
            uv0: SIMD2<Float>(0, 0),
            uv1: SIMD2<Float>(1, 0),
            uv2: SIMD2<Float>(1, 1),
            uv3: SIMD2<Float>(0, 1),
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

    private static func textureRepeat(for length: Float, metersPerTile: Float) -> Float {
        max(length / max(metersPerTile, 0.25), 1)
    }

    private static func appendQuad(
        to vertices: inout [SceneVertex],
        p0: SIMD3<Float>,
        p1: SIMD3<Float>,
        p2: SIMD3<Float>,
        p3: SIMD3<Float>,
        uv0: SIMD2<Float>,
        uv1: SIMD2<Float>,
        uv2: SIMD2<Float>,
        uv3: SIMD2<Float>,
        color: SIMD4<Float>
    ) {
        let normal = simd_normalize(simd_cross(p1 - p0, p2 - p0))
        let firstTangent = triangleTangent(
            p0: p0,
            p1: p1,
            p2: p2,
            uv0: uv0,
            uv1: uv1,
            uv2: uv2,
            normal: normal
        )
        let secondTangent = triangleTangent(
            p0: p0,
            p1: p2,
            p2: p3,
            uv0: uv0,
            uv1: uv2,
            uv2: uv3,
            normal: normal
        )

        vertices.append(SceneVertex(position: p0, normal: normal, tangent: firstTangent, uv: uv0, color: color))
        vertices.append(SceneVertex(position: p1, normal: normal, tangent: firstTangent, uv: uv1, color: color))
        vertices.append(SceneVertex(position: p2, normal: normal, tangent: firstTangent, uv: uv2, color: color))
        vertices.append(SceneVertex(position: p0, normal: normal, tangent: secondTangent, uv: uv0, color: color))
        vertices.append(SceneVertex(position: p2, normal: normal, tangent: secondTangent, uv: uv2, color: color))
        vertices.append(SceneVertex(position: p3, normal: normal, tangent: secondTangent, uv: uv3, color: color))
    }

    private static func triangleTangent(
        p0: SIMD3<Float>,
        p1: SIMD3<Float>,
        p2: SIMD3<Float>,
        uv0: SIMD2<Float>,
        uv1: SIMD2<Float>,
        uv2: SIMD2<Float>,
        normal: SIMD3<Float>
    ) -> SIMD4<Float> {
        let deltaPosition0 = p1 - p0
        let deltaPosition1 = p2 - p0
        let deltaUV0 = uv1 - uv0
        let deltaUV1 = uv2 - uv0
        let determinant = (deltaUV0.x * deltaUV1.y) - (deltaUV0.y * deltaUV1.x)

        guard abs(determinant) > 0.000_01 else {
            return fallbackTangent(for: normal)
        }

        let inverseDeterminant = 1 / determinant
        let rawTangent = (deltaPosition0 * deltaUV1.y - deltaPosition1 * deltaUV0.y) * inverseDeterminant
        let rawBitangent = (deltaPosition1 * deltaUV0.x - deltaPosition0 * deltaUV1.x) * inverseDeterminant
        return orthogonalizedTangent(rawTangent, bitangent: rawBitangent, normal: normal)
    }

    private static func orthogonalizedTangent(
        _ tangent: SIMD3<Float>,
        bitangent: SIMD3<Float>,
        normal: SIMD3<Float>
    ) -> SIMD4<Float> {
        let tangentLength = simd_length(tangent)
        guard tangentLength > 0.000_01 else {
            return fallbackTangent(for: normal)
        }

        let normalizedTangent = tangent / tangentLength
        let orthogonalized = simd_normalize(normalizedTangent - (normal * simd_dot(normal, normalizedTangent)))
        if !isFinite(orthogonalized) {
            return fallbackTangent(for: normal)
        }

        let handedness: Float = simd_dot(simd_cross(normal, orthogonalized), bitangent) < 0 ? -1 : 1
        return SIMD4<Float>(orthogonalized.x, orthogonalized.y, orthogonalized.z, handedness)
    }

    private static func fallbackTangent(for normal: SIMD3<Float>) -> SIMD4<Float> {
        let candidate = abs(normal.y) < 0.999 ? SIMD3<Float>(0, 1, 0) : SIMD3<Float>(1, 0, 0)
        let tangent = simd_normalize(simd_cross(candidate, normal))
        return SIMD4<Float>(tangent.x, tangent.y, tangent.z, 1)
    }

    private static func isFinite(_ vector: SIMD3<Float>) -> Bool {
        vector.x.isFinite && vector.y.isFinite && vector.z.isFinite
    }
}

private enum OBJAssetLoader {
    private struct ParsedMaterial {
        var baseColorFactor: SIMD4<Float>
        var roughnessFactor: Float
        var albedoTexture: SceneTextureReference?
        var normalTexture: SceneTextureReference?
        var roughnessTexture: SceneTextureReference?
        var ambientOcclusionTexture: SceneTextureReference?

        init(
            baseColorFactor: SIMD4<Float> = SIMD4<Float>(0.72, 0.76, 0.82, 1),
            roughnessFactor: Float = 0.82,
            albedoTexture: SceneTextureReference? = nil,
            normalTexture: SceneTextureReference? = nil,
            roughnessTexture: SceneTextureReference? = nil,
            ambientOcclusionTexture: SceneTextureReference? = nil
        ) {
            self.baseColorFactor = baseColorFactor
            self.roughnessFactor = roughnessFactor
            self.albedoTexture = albedoTexture
            self.normalTexture = normalTexture
            self.roughnessTexture = roughnessTexture
            self.ambientOcclusionTexture = ambientOcclusionTexture
        }

        var sceneMaterial: SceneMaterial {
            SceneMaterial(
                albedoTexture: albedoTexture,
                normalTexture: normalTexture,
                roughnessTexture: roughnessTexture,
                ambientOcclusionTexture: ambientOcclusionTexture,
                baseColorFactor: baseColorFactor,
                roughnessFactor: roughnessFactor,
                ambientOcclusionStrength: 1.0,
                normalScale: 1.0
            )
        }
    }

    static func loadAsset(named name: String, category: String, assetRoot: String) -> LoadedAsset? {
        let assetDirectory = URL(fileURLWithPath: assetRoot, isDirectory: true).appendingPathComponent(category, isDirectory: true)
        let objectURL = assetDirectory.appendingPathComponent("\(name).obj")

        guard let objectSource = try? String(contentsOf: objectURL) else {
            print("[Scene] Failed to read OBJ at \(objectURL.path)")
            return nil
        }

        let defaultMaterialName = "__default__"
        var materials: [String: ParsedMaterial] = [
            defaultMaterialName: ParsedMaterial(baseColorFactor: fallbackColor(for: name), roughnessFactor: 0.84)
        ]
        var positions: [SIMD3<Float>] = []
        var textureCoordinates: [SIMD2<Float>] = []
        var normals: [SIMD3<Float>] = []
        var verticesByMaterial: [String: [SceneVertex]] = [:]
        var materialOrder: [String] = []
        var currentMaterialName = defaultMaterialName

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
                    let parsedMaterials = parseMaterialLibrary(
                        at: materialURL,
                        assetDirectory: assetDirectory,
                        assetRoot: assetRoot
                    )
                    for (materialName, material) in parsedMaterials {
                        materials[materialName] = material
                    }
                }
            case "usemtl":
                if parts.count > 1 {
                    currentMaterialName = String(parts[1])
                    if materials[currentMaterialName] == nil {
                        materials[currentMaterialName] = ParsedMaterial(
                            baseColorFactor: fallbackColor(for: currentMaterialName),
                            roughnessFactor: 0.84
                        )
                    }
                    if verticesByMaterial[currentMaterialName] == nil {
                        verticesByMaterial[currentMaterialName] = []
                        materialOrder.append(currentMaterialName)
                    }
                }
            case "v":
                if let vertex = parseVertex(parts) {
                    positions.append(vertex)
                }
            case "vt":
                if let textureCoordinate = parseTextureCoordinate(parts) {
                    textureCoordinates.append(textureCoordinate)
                }
            case "vn":
                if let normal = parseNormal(parts) {
                    normals.append(normal)
                }
            case "f":
                if verticesByMaterial[currentMaterialName] == nil {
                    verticesByMaterial[currentMaterialName] = []
                    materialOrder.append(currentMaterialName)
                }
                appendFaceVertices(
                    parts.dropFirst(),
                    positions: positions,
                    textureCoordinates: textureCoordinates,
                    normals: normals,
                    target: &verticesByMaterial[currentMaterialName, default: []]
                )
            default:
                continue
            }
        }

        let submeshes = materialOrder.compactMap { materialName -> LoadedAssetSubmesh? in
            guard let vertices = verticesByMaterial[materialName], !vertices.isEmpty else {
                return nil
            }

            let sceneMaterial = materials[materialName]?.sceneMaterial ?? ParsedMaterial(
                baseColorFactor: fallbackColor(for: materialName),
                roughnessFactor: 0.84
            ).sceneMaterial
            let readableName = materialName == defaultMaterialName ? "Default" : materialName
            return LoadedAssetSubmesh(name: readableName, vertices: vertices, material: sceneMaterial)
        }

        guard
            let firstSubmesh = submeshes.first,
            let firstVertex = firstSubmesh.vertices.first
        else {
            return nil
        }

        var boundsMin = firstVertex.position
        var boundsMax = firstVertex.position
        for submesh in submeshes {
            for vertex in submesh.vertices {
                boundsMin = simd_min(boundsMin, vertex.position)
                boundsMax = simd_max(boundsMax, vertex.position)
            }
        }

        return LoadedAsset(submeshes: submeshes, boundsMin: boundsMin, boundsMax: boundsMax)
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

    private static func parseTextureCoordinate(_ parts: [Substring]) -> SIMD2<Float>? {
        guard parts.count >= 3 else {
            return nil
        }

        guard
            let u = Float(parts[1]),
            let v = Float(parts[2])
        else {
            return nil
        }

        return SIMD2<Float>(u, 1 - v)
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
        textureCoordinates: [SIMD2<Float>],
        normals: [SIMD3<Float>],
        target: inout [SceneVertex]
    ) {
        let faceIndices = entries.compactMap {
            parseFaceIndex(
                String($0),
                positionCount: positions.count,
                textureCoordinateCount: textureCoordinates.count,
                normalCount: normals.count
            )
        }
        guard faceIndices.count >= 3 else {
            return
        }

        for triangleIndex in 1..<(faceIndices.count - 1) {
            let triangle = [faceIndices[0], faceIndices[triangleIndex], faceIndices[triangleIndex + 1]]
            let faceNormal = derivedFaceNormal(triangle: triangle, positions: positions)
            let faceTangent = derivedTriangleTangent(
                triangle: triangle,
                positions: positions,
                textureCoordinates: textureCoordinates,
                faceNormal: faceNormal
            )

            for corner in triangle {
                let normal = corner.normalIndex.flatMap { normals[safe: $0] } ?? faceNormal
                if let position = positions[safe: corner.positionIndex] {
                    let uv = corner.textureCoordinateIndex.flatMap { textureCoordinates[safe: $0] } ?? .zero
                    let tangent = orthogonalizedTangent(faceTangent, normal: normal)
                    target.append(
                        SceneVertex(
                            position: position,
                            normal: normal,
                            tangent: tangent,
                            uv: uv,
                            color: SIMD4<Float>(1, 1, 1, 1)
                        )
                    )
                }
            }
        }
    }

    private static func parseFaceIndex(
        _ token: String,
        positionCount: Int,
        textureCoordinateCount: Int,
        normalCount: Int
    ) -> (positionIndex: Int, textureCoordinateIndex: Int?, normalIndex: Int?)? {
        let components = token.split(separator: "/", omittingEmptySubsequences: false)
        guard let positionIndex = resolveIndex(from: components[safe: 0], count: positionCount) else {
            return nil
        }

        let textureCoordinateIndex: Int?
        if components.count >= 2 {
            textureCoordinateIndex = resolveIndex(from: components[safe: 1], count: textureCoordinateCount)
        } else {
            textureCoordinateIndex = nil
        }

        let normalIndex: Int?
        if components.count >= 3 {
            normalIndex = resolveIndex(from: components[safe: 2], count: normalCount)
        } else {
            normalIndex = nil
        }

        return (positionIndex, textureCoordinateIndex, normalIndex)
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
        triangle: [(positionIndex: Int, textureCoordinateIndex: Int?, normalIndex: Int?)],
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

    private static func derivedTriangleTangent(
        triangle: [(positionIndex: Int, textureCoordinateIndex: Int?, normalIndex: Int?)],
        positions: [SIMD3<Float>],
        textureCoordinates: [SIMD2<Float>],
        faceNormal: SIMD3<Float>
    ) -> SIMD4<Float> {
        guard
            let p0 = positions[safe: triangle[0].positionIndex],
            let p1 = positions[safe: triangle[1].positionIndex],
            let p2 = positions[safe: triangle[2].positionIndex],
            let uv0Index = triangle[0].textureCoordinateIndex,
            let uv1Index = triangle[1].textureCoordinateIndex,
            let uv2Index = triangle[2].textureCoordinateIndex,
            let uv0 = textureCoordinates[safe: uv0Index],
            let uv1 = textureCoordinates[safe: uv1Index],
            let uv2 = textureCoordinates[safe: uv2Index]
        else {
            return fallbackTangent(for: faceNormal)
        }

        let deltaPosition0 = p1 - p0
        let deltaPosition1 = p2 - p0
        let deltaUV0 = uv1 - uv0
        let deltaUV1 = uv2 - uv0
        let determinant = (deltaUV0.x * deltaUV1.y) - (deltaUV0.y * deltaUV1.x)

        guard abs(determinant) > 0.000_01 else {
            return fallbackTangent(for: faceNormal)
        }

        let inverseDeterminant = 1 / determinant
        let rawTangent = (deltaPosition0 * deltaUV1.y - deltaPosition1 * deltaUV0.y) * inverseDeterminant
        let rawBitangent = (deltaPosition1 * deltaUV0.x - deltaPosition0 * deltaUV1.x) * inverseDeterminant
        return orthogonalizedTangent(rawTangent, bitangent: rawBitangent, normal: faceNormal)
    }

    private static func orthogonalizedTangent(
        _ tangent: SIMD4<Float>,
        normal: SIMD3<Float>
    ) -> SIMD4<Float> {
        let xyz = SIMD3<Float>(tangent.x, tangent.y, tangent.z)
        let length = simd_length(xyz)
        guard length > 0.000_01 else {
            return fallbackTangent(for: normal)
        }

        let normalizedTangent = xyz / length
        let orthogonalized = simd_normalize(normalizedTangent - (normal * simd_dot(normal, normalizedTangent)))
        guard isFinite(orthogonalized) else {
            return fallbackTangent(for: normal)
        }

        return SIMD4<Float>(orthogonalized.x, orthogonalized.y, orthogonalized.z, tangent.w)
    }

    private static func orthogonalizedTangent(
        _ tangent: SIMD3<Float>,
        bitangent: SIMD3<Float>,
        normal: SIMD3<Float>
    ) -> SIMD4<Float> {
        let tangentLength = simd_length(tangent)
        guard tangentLength > 0.000_01 else {
            return fallbackTangent(for: normal)
        }

        let normalizedTangent = tangent / tangentLength
        let orthogonalized = simd_normalize(normalizedTangent - (normal * simd_dot(normal, normalizedTangent)))
        guard isFinite(orthogonalized) else {
            return fallbackTangent(for: normal)
        }

        let handedness: Float = simd_dot(simd_cross(normal, orthogonalized), bitangent) < 0 ? -1 : 1
        return SIMD4<Float>(orthogonalized.x, orthogonalized.y, orthogonalized.z, handedness)
    }

    private static func fallbackTangent(for normal: SIMD3<Float>) -> SIMD4<Float> {
        let candidate = abs(normal.y) < 0.999 ? SIMD3<Float>(0, 1, 0) : SIMD3<Float>(1, 0, 0)
        let tangent = simd_normalize(simd_cross(candidate, normal))
        return SIMD4<Float>(tangent.x, tangent.y, tangent.z, 1)
    }

    private static func isFinite(_ vector: SIMD3<Float>) -> Bool {
        vector.x.isFinite && vector.y.isFinite && vector.z.isFinite
    }

    private static func parseMaterialLibrary(
        at url: URL,
        assetDirectory: URL,
        assetRoot: String
    ) -> [String: ParsedMaterial] {
        guard let source = try? String(contentsOf: url) else {
            return [:]
        }

        let materialDirectory = url.deletingLastPathComponent()

        var materials: [String: ParsedMaterial] = [:]
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

            switch String(keyword).lowercased() {
            case "newmtl":
                currentMaterial = parts.count > 1 ? String(parts[1]) : nil
                if let currentMaterial, materials[currentMaterial] == nil {
                    materials[currentMaterial] = ParsedMaterial(
                        baseColorFactor: fallbackColor(for: currentMaterial),
                        roughnessFactor: 0.84
                    )
                }
            case "kd":
                guard
                    let currentMaterial,
                    parts.count >= 4,
                    let red = Float(parts[1]),
                    let green = Float(parts[2]),
                    let blue = Float(parts[3])
                else {
                    continue
                }

                var material = materials[currentMaterial] ?? ParsedMaterial(
                    baseColorFactor: fallbackColor(for: currentMaterial),
                    roughnessFactor: 0.84
                )
                material.baseColorFactor = SIMD4<Float>(red, green, blue, material.baseColorFactor.w)
                materials[currentMaterial] = material
            case "d":
                guard
                    let currentMaterial,
                    parts.count >= 2,
                    let opacity = Float(parts[1])
                else {
                    continue
                }

                var material = materials[currentMaterial] ?? ParsedMaterial(
                    baseColorFactor: fallbackColor(for: currentMaterial),
                    roughnessFactor: 0.84
                )
                material.baseColorFactor.w = simd_clamp(opacity, 0.0, 1.0)
                materials[currentMaterial] = material
            case "tr":
                guard
                    let currentMaterial,
                    parts.count >= 2,
                    let transparency = Float(parts[1])
                else {
                    continue
                }

                var material = materials[currentMaterial] ?? ParsedMaterial(
                    baseColorFactor: fallbackColor(for: currentMaterial),
                    roughnessFactor: 0.84
                )
                material.baseColorFactor.w = simd_clamp(1 - transparency, 0.0, 1.0)
                materials[currentMaterial] = material
            case "ns":
                guard
                    let currentMaterial,
                    parts.count >= 2,
                    let specularExponent = Float(parts[1])
                else {
                    continue
                }

                var material = materials[currentMaterial] ?? ParsedMaterial(
                    baseColorFactor: fallbackColor(for: currentMaterial),
                    roughnessFactor: 0.84
                )
                material.roughnessFactor = roughness(fromSpecularExponent: specularExponent)
                materials[currentMaterial] = material
            case "map_kd":
                guard
                    let currentMaterial,
                    let textureReference = parseTextureReference(
                        from: parts,
                        assetDirectory: materialDirectory,
                        assetRoot: assetRoot
                    )
                else {
                    continue
                }

                var material = materials[currentMaterial] ?? ParsedMaterial(
                    baseColorFactor: fallbackColor(for: currentMaterial),
                    roughnessFactor: 0.84
                )
                material.albedoTexture = textureReference
                materials[currentMaterial] = material
            case "map_bump", "bump", "norm", "map_normal":
                guard
                    let currentMaterial,
                    let textureReference = parseTextureReference(
                        from: parts,
                        assetDirectory: materialDirectory,
                        assetRoot: assetRoot
                    )
                else {
                    continue
                }

                var material = materials[currentMaterial] ?? ParsedMaterial(
                    baseColorFactor: fallbackColor(for: currentMaterial),
                    roughnessFactor: 0.84
                )
                material.normalTexture = textureReference
                materials[currentMaterial] = material
            case "map_pr", "map_roughness":
                guard
                    let currentMaterial,
                    let textureReference = parseTextureReference(
                        from: parts,
                        assetDirectory: materialDirectory,
                        assetRoot: assetRoot
                    )
                else {
                    continue
                }

                var material = materials[currentMaterial] ?? ParsedMaterial(
                    baseColorFactor: fallbackColor(for: currentMaterial),
                    roughnessFactor: 0.84
                )
                material.roughnessTexture = textureReference
                materials[currentMaterial] = material
            case "map_ao", "map_occ", "map_occlusion":
                guard
                    let currentMaterial,
                    let textureReference = parseTextureReference(
                        from: parts,
                        assetDirectory: materialDirectory,
                        assetRoot: assetRoot
                    )
                else {
                    continue
                }

                var material = materials[currentMaterial] ?? ParsedMaterial(
                    baseColorFactor: fallbackColor(for: currentMaterial),
                    roughnessFactor: 0.84
                )
                material.ambientOcclusionTexture = textureReference
                materials[currentMaterial] = material
            default:
                continue
            }
        }

        return materials
    }

    private static func parseTextureReference(
        from parts: [Substring],
        assetDirectory: URL,
        assetRoot: String
    ) -> SceneTextureReference? {
        guard let lastToken = parts.last else {
            return nil
        }

        let textureURL = assetDirectory.appendingPathComponent(String(lastToken))
        guard let relativePath = relativeAssetPath(for: textureURL, assetRoot: assetRoot) else {
            return nil
        }
        return .assetRelativePath(relativePath)
    }

    private static func relativeAssetPath(for url: URL, assetRoot: String) -> String? {
        let rootPath = URL(fileURLWithPath: assetRoot, isDirectory: true).standardizedFileURL.path
        let texturePath = url.standardizedFileURL.path

        if texturePath.hasPrefix(rootPath + "/") {
            return String(texturePath.dropFirst(rootPath.count + 1))
        }

        return nil
    }

    private static func roughness(fromSpecularExponent exponent: Float) -> Float {
        let sanitizedExponent = max(exponent, 1)
        let phongApproximation = sqrt(2 / (sanitizedExponent + 2))
        return simd_clamp(phongApproximation, 0.08, 1.0)
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
