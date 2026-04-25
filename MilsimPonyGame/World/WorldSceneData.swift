import Foundation
import simd

struct WorldManifest: Decodable {
    let worldName: String
    let sceneFile: String
    let coordinateSystemFile: String
    let sectorFiles: [String]
}

struct CoordinateSystemConfiguration: Decodable {
    let name: String
    let anchorName: String
    let axisX: String
    let axisY: String
    let axisZ: String
    let forwardHeadingDegrees: Float
    let notes: [String]
}

struct SceneConfiguration: Decodable {
    let cycleLabel: String?
    let sceneName: String
    let planningNotes: [String]?
    let spawn: SpawnConfiguration
    let randomSpawns: [SpawnConfiguration]?
    let sky: SkyConfiguration
    let sun: SunConfiguration
    let timeOfDay: TimeOfDayConfiguration?
    let atmosphere: AtmosphereConfiguration?
    let player: PlayerConfiguration?
    let scope: ScopeConfiguration?
    let shadow: ShadowConfiguration?
    let postProcess: PostProcessConfiguration?
    let ballistics: BallisticsConfiguration?
    let environmentalMotion: EnvironmentalMotionConfiguration?
    let materialBreakup: MaterialBreakupConfiguration?
    let surfaceFidelity: SurfaceFidelityConfiguration?
    let distantLOD: DistantLODConfiguration?
    let waterReflection: WaterReflectionConfiguration?
    let packagingAutomation: PackagingAutomationConfiguration?
    let testerDistribution: TesterDistributionConfiguration?
    let lightingArchitecture: LightingArchitectureConfiguration?
    let dynamicLights: [DynamicLightConfiguration]?
    let antiAliasing: AntiAliasingConfiguration?
    let physicalAtmosphere: PhysicalAtmosphereConfiguration?
    let indirectRendering: IndirectRenderingConfiguration?
    let sdfUI: SDFUIConfiguration?
    let renderGraph: RenderGraphConfiguration?
    let audioMix: AudioMixConfiguration?
    let sessionPersistence: SessionPersistenceConfiguration?
    let route: RouteConfiguration
    let reviewPack: ReviewPackConfiguration?
    let combatRehearsal: CombatRehearsalConfiguration?
    let missionScript: MissionScriptConfiguration?
    let routeSelection: RouteSelectionConfiguration?
    let collisionAuthoring: CollisionAuthoringConfiguration?
    let alternateRoutes: [AlternateRouteConfiguration]?
    let detection: DetectionConfiguration?
    let guidance: GuidanceConfiguration?
    let proceduralElements: [ProceduralElementConfiguration]
    let assetInstances: [AssetInstanceConfiguration]
    let includedSectors: [String]
}

struct AtmosphereConfiguration: Decodable {
    let fogColor: [Float]?
    let fogNear: Float?
    let fogFar: Float?
    let hazeStrength: Float?

    init(
        fogColor: [Float]? = nil,
        fogNear: Float? = nil,
        fogFar: Float? = nil,
        hazeStrength: Float? = nil
    ) {
        self.fogColor = fogColor
        self.fogNear = fogNear
        self.fogFar = fogFar
        self.hazeStrength = hazeStrength
    }

    var fogColorVector: SIMD4<Float> {
        fogColor?.simdColor(or: SIMD4<Float>(0.66, 0.74, 0.80, 1)) ?? SIMD4<Float>(0.66, 0.74, 0.80, 1)
    }
}

struct PlayerConfiguration: Decodable {
    let walkSpeed: Float?
    let sprintSpeed: Float?
    let lookSensitivity: Float?

    init(
        walkSpeed: Float? = nil,
        sprintSpeed: Float? = nil,
        lookSensitivity: Float? = nil
    ) {
        self.walkSpeed = walkSpeed
        self.sprintSpeed = sprintSpeed
        self.lookSensitivity = lookSensitivity
    }
}

struct ScopeConfiguration: Decodable {
    let label: String?
    let magnification: Float
    let fieldOfViewDegrees: Float
    let lookSensitivityMultiplier: Float?
    let drawDistanceMultiplier: Float?
    let farPlaneMultiplier: Float?
    let reticleColor: [Float]?
    let lensDirtStrength: Float?
    let edgeAberrationStrength: Float?
    let parallaxCompensation: Float?
    let milDotSpacingMils: Float?
    let calibrationRangeMeters: Float?

    init(
        label: String? = nil,
        magnification: Float = 4.0,
        fieldOfViewDegrees: Float = 15.0,
        lookSensitivityMultiplier: Float? = 0.26,
        drawDistanceMultiplier: Float? = 2.4,
        farPlaneMultiplier: Float? = 1.35,
        reticleColor: [Float]? = nil,
        lensDirtStrength: Float? = 0.0,
        edgeAberrationStrength: Float? = 0.0,
        parallaxCompensation: Float? = 0.0,
        milDotSpacingMils: Float? = 1.0,
        calibrationRangeMeters: Float? = 400.0
    ) {
        self.label = label
        self.magnification = magnification
        self.fieldOfViewDegrees = fieldOfViewDegrees
        self.lookSensitivityMultiplier = lookSensitivityMultiplier
        self.drawDistanceMultiplier = drawDistanceMultiplier
        self.farPlaneMultiplier = farPlaneMultiplier
        self.reticleColor = reticleColor
        self.lensDirtStrength = lensDirtStrength
        self.edgeAberrationStrength = edgeAberrationStrength
        self.parallaxCompensation = parallaxCompensation
        self.milDotSpacingMils = milDotSpacingMils
        self.calibrationRangeMeters = calibrationRangeMeters
    }

    var reticleColorVector: SIMD4<Float> {
        reticleColor?.simdColor(or: SIMD4<Float>(0.92, 0.86, 0.42, 0.94)) ?? SIMD4<Float>(0.92, 0.86, 0.42, 0.94)
    }
}

struct ShadowConfiguration: Decodable {
    let mapResolution: Int?
    let coverage: Float?
    let depthBias: Float?
    let normalBias: Float?
    let strength: Float?
    let scopeCoverageMultiplier: Float?
    let forwardOffsetMultiplier: Float?
    let cascadeCount: Int?
    let cascadeSplits: [Float]?
    let profileStatus: String?
    let profileRule: String?

    init(
        mapResolution: Int? = 2048,
        coverage: Float? = 120.0,
        depthBias: Float? = 0.015,
        normalBias: Float? = 0.010,
        strength: Float? = 0.72,
        scopeCoverageMultiplier: Float? = 1.25,
        forwardOffsetMultiplier: Float? = 0.35,
        cascadeCount: Int? = 1,
        cascadeSplits: [Float]? = nil,
        profileStatus: String? = nil,
        profileRule: String? = nil
    ) {
        self.mapResolution = mapResolution
        self.coverage = coverage
        self.depthBias = depthBias
        self.normalBias = normalBias
        self.strength = strength
        self.scopeCoverageMultiplier = scopeCoverageMultiplier
        self.forwardOffsetMultiplier = forwardOffsetMultiplier
        self.cascadeCount = cascadeCount
        self.cascadeSplits = cascadeSplits
        self.profileStatus = profileStatus
        self.profileRule = profileRule
    }
}

struct PostProcessConfiguration: Decodable {
    let exposureBias: Float?
    let whitePoint: Float?
    let contrast: Float?
    let saturation: Float?
    let shadowBalance: Float?
    let vignetteStrength: Float?
    let ssaoStrength: Float?
    let ssaoRadius: Float?
    let ssaoBias: Float?
    let shadowTint: [Float]?
    let highlightTint: [Float]?

    init(
        exposureBias: Float? = 0.18,
        whitePoint: Float? = 1.25,
        contrast: Float? = 1.04,
        saturation: Float? = 1.02,
        shadowBalance: Float? = 0.44,
        vignetteStrength: Float? = 0.08,
        ssaoStrength: Float? = 0.18,
        ssaoRadius: Float? = 1.6,
        ssaoBias: Float? = 0.0008,
        shadowTint: [Float]? = nil,
        highlightTint: [Float]? = nil
    ) {
        self.exposureBias = exposureBias
        self.whitePoint = whitePoint
        self.contrast = contrast
        self.saturation = saturation
        self.shadowBalance = shadowBalance
        self.vignetteStrength = vignetteStrength
        self.ssaoStrength = ssaoStrength
        self.ssaoRadius = ssaoRadius
        self.ssaoBias = ssaoBias
        self.shadowTint = shadowTint
        self.highlightTint = highlightTint
    }

    var shadowTintVector: SIMD4<Float> {
        shadowTint?.simdColor(or: SIMD4<Float>(0.95, 0.99, 1.04, 1.0))
            ?? SIMD4<Float>(0.95, 0.99, 1.04, 1.0)
    }

    var highlightTintVector: SIMD4<Float> {
        highlightTint?.simdColor(or: SIMD4<Float>(1.04, 1.01, 0.95, 1.0))
            ?? SIMD4<Float>(1.04, 1.01, 0.95, 1.0)
    }
}

struct BallisticsConfiguration: Decodable {
    let muzzleVelocityMetersPerSecond: Float?
    let gravityMetersPerSecondSquared: Float?
    let maxSimulationTimeSeconds: Float?
    let simulationStepSeconds: Float?
    let launchHeightOffsetMeters: Float?
    let scopedSpreadDegrees: Float?
    let hipSpreadDegrees: Float?
    let movementSpreadDegrees: Float?
    let sprintSpreadDegrees: Float?
    let settleDurationSeconds: Float?
    let breathCycleSeconds: Float?
    let breathAmplitudeDegrees: Float?
    let holdBreathDurationSeconds: Float?
    let holdBreathRecoverySeconds: Float?

    init(
        muzzleVelocityMetersPerSecond: Float? = 820.0,
        gravityMetersPerSecondSquared: Float? = 9.81,
        maxSimulationTimeSeconds: Float? = 2.4,
        simulationStepSeconds: Float? = (1.0 / 120.0),
        launchHeightOffsetMeters: Float? = 0.0,
        scopedSpreadDegrees: Float? = 0.10,
        hipSpreadDegrees: Float? = 0.65,
        movementSpreadDegrees: Float? = 1.10,
        sprintSpreadDegrees: Float? = 1.80,
        settleDurationSeconds: Float? = 0.60,
        breathCycleSeconds: Float? = 3.40,
        breathAmplitudeDegrees: Float? = 0.16,
        holdBreathDurationSeconds: Float? = 2.60,
        holdBreathRecoverySeconds: Float? = 3.60
    ) {
        self.muzzleVelocityMetersPerSecond = muzzleVelocityMetersPerSecond
        self.gravityMetersPerSecondSquared = gravityMetersPerSecondSquared
        self.maxSimulationTimeSeconds = maxSimulationTimeSeconds
        self.simulationStepSeconds = simulationStepSeconds
        self.launchHeightOffsetMeters = launchHeightOffsetMeters
        self.scopedSpreadDegrees = scopedSpreadDegrees
        self.hipSpreadDegrees = hipSpreadDegrees
        self.movementSpreadDegrees = movementSpreadDegrees
        self.sprintSpreadDegrees = sprintSpreadDegrees
        self.settleDurationSeconds = settleDurationSeconds
        self.breathCycleSeconds = breathCycleSeconds
        self.breathAmplitudeDegrees = breathAmplitudeDegrees
        self.holdBreathDurationSeconds = holdBreathDurationSeconds
        self.holdBreathRecoverySeconds = holdBreathRecoverySeconds
    }
}

struct DetectionConfiguration: Decodable {
    let suspicionDecayPerSecond: Float
    let failThreshold: Float
    let observers: [ThreatObserverConfiguration]

    init(
        suspicionDecayPerSecond: Float = 0.28,
        failThreshold: Float = 1.0,
        observers: [ThreatObserverConfiguration] = []
    ) {
        self.suspicionDecayPerSecond = suspicionDecayPerSecond
        self.failThreshold = failThreshold
        self.observers = observers
    }
}

struct ThreatObserverConfiguration: Decodable {
    let id: String
    let label: String
    let position: [Float]
    let yawDegrees: Float
    let pitchDegrees: Float?
    let range: Float
    let fieldOfViewDegrees: Float
    let suspicionPerSecond: Float
    let groupID: String?
    let groupRelayRangeMeters: Float?
    let patrolRouteID: String?
    let patrolRole: String?
    let formationSpacingMeters: Float?
    let alertMemorySeconds: Float?
    let alertedFieldOfViewDegrees: Float?
    let turnRateDegreesPerSecond: Float?
    let scanArcDegrees: Float?
    let scanCycleSeconds: Float?
    let markerColor: [Float]?

    init(
        id: String,
        label: String,
        position: [Float],
        yawDegrees: Float,
        pitchDegrees: Float? = nil,
        range: Float,
        fieldOfViewDegrees: Float,
        suspicionPerSecond: Float,
        groupID: String? = nil,
        groupRelayRangeMeters: Float? = nil,
        patrolRouteID: String? = nil,
        patrolRole: String? = nil,
        formationSpacingMeters: Float? = nil,
        alertMemorySeconds: Float? = 2.4,
        alertedFieldOfViewDegrees: Float? = 74.0,
        turnRateDegreesPerSecond: Float? = 78.0,
        scanArcDegrees: Float? = 28.0,
        scanCycleSeconds: Float? = 5.2,
        markerColor: [Float]? = nil
    ) {
        self.id = id
        self.label = label
        self.position = position
        self.yawDegrees = yawDegrees
        self.pitchDegrees = pitchDegrees
        self.range = range
        self.fieldOfViewDegrees = fieldOfViewDegrees
        self.suspicionPerSecond = suspicionPerSecond
        self.groupID = groupID
        self.groupRelayRangeMeters = groupRelayRangeMeters
        self.patrolRouteID = patrolRouteID
        self.patrolRole = patrolRole
        self.formationSpacingMeters = formationSpacingMeters
        self.alertMemorySeconds = alertMemorySeconds
        self.alertedFieldOfViewDegrees = alertedFieldOfViewDegrees
        self.turnRateDegreesPerSecond = turnRateDegreesPerSecond
        self.scanArcDegrees = scanArcDegrees
        self.scanCycleSeconds = scanCycleSeconds
        self.markerColor = markerColor
    }

    var positionVector: SIMD3<Float> {
        position.simd3(or: SIMD3<Float>(0, 1.8, 0))
    }

    var markerColorVector: SIMD4<Float> {
        markerColor?.simdColor(or: SIMD4<Float>(0.86, 0.38, 0.22, 0.92)) ?? SIMD4<Float>(0.86, 0.38, 0.22, 0.92)
    }
}

struct GuidanceConfiguration: Decodable {
    let coverPoints: [GuidancePointConfiguration]
    let signposts: [GuidancePointConfiguration]

    init(
        coverPoints: [GuidancePointConfiguration] = [],
        signposts: [GuidancePointConfiguration] = []
    ) {
        self.coverPoints = coverPoints
        self.signposts = signposts
    }
}

enum GuidancePointKind: String, Decodable {
    case cover
    case signpost
}

struct GuidancePointConfiguration: Decodable {
    let id: String
    let label: String
    let kind: GuidancePointKind
    let position: [Float]
    let yawDegrees: Float?
    let color: [Float]?
    let height: Float?

    var positionVector: SIMD3<Float> {
        position.simd3(or: .zero)
    }

    var colorVector: SIMD4<Float> {
        switch kind {
        case .cover:
            return color?.simdColor(or: SIMD4<Float>(0.26, 0.74, 0.56, 0.92)) ?? SIMD4<Float>(0.26, 0.74, 0.56, 0.92)
        case .signpost:
            return color?.simdColor(or: SIMD4<Float>(0.92, 0.80, 0.36, 0.92)) ?? SIMD4<Float>(0.92, 0.80, 0.36, 0.92)
        }
    }
}

struct SpawnConfiguration: Decodable {
    let label: String?
    let position: [Float]
    let yawDegrees: Float
    let pitchDegrees: Float

    var positionVector: SIMD3<Float> {
        position.simd3(or: SIMD3<Float>(0, 1.65, 4.5))
    }
}

struct SkyConfiguration: Decodable {
    let horizonColor: [Float]
    let zenithColor: [Float]

    var horizonColorVector: SIMD4<Float> {
        horizonColor.simdColor(or: SIMD4<Float>(0.55, 0.70, 0.84, 1))
    }

    var zenithColorVector: SIMD4<Float> {
        zenithColor.simdColor(or: SIMD4<Float>(0.17, 0.30, 0.48, 1))
    }
}

struct SunConfiguration: Decodable {
    let direction: [Float]
    let color: [Float]
    let ambientIntensity: Float
    let diffuseIntensity: Float

    var directionVector: SIMD3<Float> {
        direction.simd3(or: SIMD3<Float>(-0.45, -1.0, -0.25))
    }

    var colorVector: SIMD3<Float> {
        color.simd3(or: SIMD3<Float>(1.0, 0.95, 0.86))
    }
}

struct TimeOfDayConfiguration: Decodable {
    let enabled: Bool?
    let status: String?
    let rule: String?
    let label: String?
    let hour: Float?
    let sunAzimuthDegrees: Float?
    let sunElevationDegrees: Float?
    let horizonColor: [Float]?
    let zenithColor: [Float]?
    let sunColor: [Float]?
    let fogColor: [Float]?
    let ambientIntensity: Float?
    let diffuseIntensity: Float?
    let shadowStrength: Float?
    let shadowCoverageMultiplier: Float?
    let hazeStrength: Float?

    var horizonColorVector: SIMD4<Float>? {
        horizonColor?.simdColor(or: SIMD4<Float>(0.55, 0.70, 0.84, 1))
    }

    var zenithColorVector: SIMD4<Float>? {
        zenithColor?.simdColor(or: SIMD4<Float>(0.17, 0.30, 0.48, 1))
    }

    var sunColorVector: SIMD3<Float>? {
        sunColor?.simd3(or: SIMD3<Float>(1.0, 0.95, 0.86))
    }

    var fogColorVector: SIMD4<Float>? {
        fogColor?.simdColor(or: SIMD4<Float>(0.66, 0.74, 0.80, 1))
    }
}

struct EnvironmentalMotionConfiguration: Decodable {
    let status: String?
    let rule: String?
    let windDirection: [Float]?
    let windStrength: Float?
    let gustStrength: Float?
    let vegetationResponse: Float?
    let shorelineRippleStrength: Float?
    let waterSurfaceResponse: Float?

    init(
        status: String? = "environmental motion pending",
        rule: String? = "scene uses default terrain breeze",
        windDirection: [Float]? = nil,
        windStrength: Float? = 0.55,
        gustStrength: Float? = 0.25,
        vegetationResponse: Float? = 1.0,
        shorelineRippleStrength: Float? = 0.18,
        waterSurfaceResponse: Float? = 0.72
    ) {
        self.status = status
        self.rule = rule
        self.windDirection = windDirection
        self.windStrength = windStrength
        self.gustStrength = gustStrength
        self.vegetationResponse = vegetationResponse
        self.shorelineRippleStrength = shorelineRippleStrength
        self.waterSurfaceResponse = waterSurfaceResponse
    }

    var windDirectionVector: SIMD2<Float> {
        guard let windDirection, windDirection.count >= 2 else {
            return SIMD2<Float>(0.86, 0.50)
        }

        let vector = SIMD2<Float>(windDirection[0], windDirection[1])
        let length = simd_length(vector)
        return length > 0.0001 ? vector / length : SIMD2<Float>(0.86, 0.50)
    }
}

struct MaterialBreakupConfiguration: Decodable {
    let status: String?
    let rule: String?
    let roadDecalDensity: Float?
    let roadScuffStrength: Float?
    let landmarkBreakupStrength: Float?

    init(
        status: String? = "material breakup pending",
        rule: String? = "use default road scuff decals",
        roadDecalDensity: Float? = 0.55,
        roadScuffStrength: Float? = 0.42,
        landmarkBreakupStrength: Float? = 0.20
    ) {
        self.status = status
        self.rule = rule
        self.roadDecalDensity = roadDecalDensity
        self.roadScuffStrength = roadScuffStrength
        self.landmarkBreakupStrength = landmarkBreakupStrength
    }
}

struct SurfaceFidelityConfiguration: Decodable {
    let status: String?
    let rule: String?

    init(
        status: String? = "surface fidelity review pending",
        rule: String? = "review environmental motion, water, SSAO, decals, and material breakup together"
    ) {
        self.status = status
        self.rule = rule
    }
}

struct DistantLODConfiguration: Decodable {
    let status: String?
    let rule: String?
    let landmarkTargets: [String]?
    let impostorStartMeters: Float?
    let scopeStabilityRule: String?

    init(
        status: String? = "distant LOD planning pending",
        rule: String? = "author key landmark impostor metadata before renderer promotion",
        landmarkTargets: [String]? = nil,
        impostorStartMeters: Float? = 420.0,
        scopeStabilityRule: String? = "scope mode keeps stable far silhouettes until impostor swap is implemented"
    ) {
        self.status = status
        self.rule = rule
        self.landmarkTargets = landmarkTargets
        self.impostorStartMeters = impostorStartMeters
        self.scopeStabilityRule = scopeStabilityRule
    }
}

struct WaterReflectionConfiguration: Decodable {
    let status: String?
    let rule: String?
    let probeTargets: [String]?
    let approach: String?
    let deferredReason: String?
    let screenSpaceReflectionStatus: String?
    let ssrStrength: Float?
    let ssrMaxDistancePixels: Float?
    let ssrDepthThickness: Float?
    let probeFallbackStrength: Float?
    let reflectionHorizonY: Float?
    let probeColor: [Float]?

    init(
        status: String? = "water reflection planning pending",
        rule: String? = "prototype or defer reflection probe after water motion closeout",
        probeTargets: [String]? = nil,
        approach: String? = "material probe metadata before SSR",
        deferredReason: String? = "SSR waits for stable distant LOD and water probe evidence",
        screenSpaceReflectionStatus: String? = "SSR deferred",
        ssrStrength: Float? = 0.0,
        ssrMaxDistancePixels: Float? = 36.0,
        ssrDepthThickness: Float? = 0.018,
        probeFallbackStrength: Float? = 0.0,
        reflectionHorizonY: Float? = 0.54,
        probeColor: [Float]? = nil
    ) {
        self.status = status
        self.rule = rule
        self.probeTargets = probeTargets
        self.approach = approach
        self.deferredReason = deferredReason
        self.screenSpaceReflectionStatus = screenSpaceReflectionStatus
        self.ssrStrength = ssrStrength
        self.ssrMaxDistancePixels = ssrMaxDistancePixels
        self.ssrDepthThickness = ssrDepthThickness
        self.probeFallbackStrength = probeFallbackStrength
        self.reflectionHorizonY = reflectionHorizonY
        self.probeColor = probeColor
    }
}

struct PackagingAutomationConfiguration: Decodable {
    let status: String?
    let rule: String?
    let versionPolicy: String?
    let archivePattern: String?
    let manifestChecks: [String]?
    let smokeCommand: String?

    init(
        status: String? = "packaging automation planning pending",
        rule: String? = "package release only after version, manifest, archive, and smoke checks pass",
        versionPolicy: String? = "cycle-based version policy pending",
        archivePattern: String? = "MilsimPonyGame-v<version>-b<build>-cycle<cycle>-<utc>",
        manifestChecks: [String]? = nil,
        smokeCommand: String? = "Tools/package_release.sh --validate-only"
    ) {
        self.status = status
        self.rule = rule
        self.versionPolicy = versionPolicy
        self.archivePattern = archivePattern
        self.manifestChecks = manifestChecks
        self.smokeCommand = smokeCommand
    }
}

struct TesterDistributionConfiguration: Decodable {
    let status: String?
    let rule: String?
    let channel: String?
    let notarizationStatus: String?
    let ciPlan: String?
    let deliveryChecklist: [String]?
    let sdfUIPlan: String?
    let smokeCommand: String?

    init(
        status: String? = "tester distribution planning pending",
        rule: String? = "share tester builds only after package validation and delivery-plan checks pass",
        channel: String? = "local-review",
        notarizationStatus: String? = "notarization workflow planned",
        ciPlan: String? = "CI packaging gate planned",
        deliveryChecklist: [String]? = nil,
        sdfUIPlan: String? = "SDF UI migration scoped for later polish",
        smokeCommand: String? = "Tools/package_release.sh --check-distribution"
    ) {
        self.status = status
        self.rule = rule
        self.channel = channel
        self.notarizationStatus = notarizationStatus
        self.ciPlan = ciPlan
        self.deliveryChecklist = deliveryChecklist
        self.sdfUIPlan = sdfUIPlan
        self.smokeCommand = smokeCommand
    }
}

struct LightingArchitectureConfiguration: Decodable {
    let status: String?
    let rule: String?
    let scenario: String?
    let timeOfDay: String?
    let sunPolicy: String?
    let atmospherePolicy: String?
    let clusteredLightingDecision: String?
    let renderGraphDecision: String?
    let measuredPrerequisites: [String]?
    let smokeCommand: String?

    init(
        status: String? = "lighting architecture planning pending",
        rule: String? = "lock time-of-day, atmosphere, clustered lighting, and render graph decisions before renderer rewrites",
        scenario: String? = "static Canberra daylight baseline",
        timeOfDay: String? = "fixed review daylight",
        sunPolicy: String? = "single authored sun remains shipping path",
        atmospherePolicy: String? = "authored fog and haze remain data-driven",
        clusteredLightingDecision: String? = "defer Forward+ until dynamic light counts justify it",
        renderGraphDecision: String? = "defer render graph until pass-count and dependency pressure are measured",
        measuredPrerequisites: [String]? = nil,
        smokeCommand: String? = "Docs/CYCLE_98_SMOKE_TEST.md"
    ) {
        self.status = status
        self.rule = rule
        self.scenario = scenario
        self.timeOfDay = timeOfDay
        self.sunPolicy = sunPolicy
        self.atmospherePolicy = atmospherePolicy
        self.clusteredLightingDecision = clusteredLightingDecision
        self.renderGraphDecision = renderGraphDecision
        self.measuredPrerequisites = measuredPrerequisites
        self.smokeCommand = smokeCommand
    }
}

struct DynamicLightConfiguration: Decodable {
    let id: String
    let label: String
    let position: [Float]
    let color: [Float]
    let intensity: Float?
    let radius: Float?
    let clusterTag: String?

    var positionVector: SIMD3<Float> {
        position.simd3(or: SIMD3<Float>(0, 3, 0))
    }

    var colorVector: SIMD3<Float> {
        color.simd3(or: SIMD3<Float>(1, 0.92, 0.74))
    }
}

struct AntiAliasingConfiguration: Decodable {
    let status: String?
    let rule: String?
    let mode: String?
    let edgeThreshold: Float?
    let blendStrength: Float?
    let depthRejection: Float?
    let scopeStabilityRule: String?
}

struct PhysicalAtmosphereConfiguration: Decodable {
    let status: String?
    let rule: String?
    let model: String?
    let rayleighStrength: Float?
    let mieStrength: Float?
    let mieAnisotropy: Float?
    let ozoneAbsorption: Float?
    let turbidity: Float?
    let horizonLift: Float?
    let densityFalloff: Float?
    let scopeStabilityRule: String?
}

struct IndirectRenderingConfiguration: Decodable {
    let status: String?
    let rule: String?
    let mode: String?
    let drawClass: String?
    let commandPath: String?
    let capacity: Int?
    let coverageNote: String?
    let fallbackRule: String?
    let measurementRule: String?
}

struct SDFUIConfiguration: Decodable {
    let status: String?
    let rule: String?
    let mode: String?
    let fontFamily: String?
    let coverage: [String]?
    let outlinePixels: Float?
    let shadowPixels: Float?
    let minimumScaleFactor: Float?
    let mapLabelRule: String?
    let scopeRule: String?
    let fallbackRule: String?
    let measurementRule: String?

    init(
        status: String? = "SDF UI rendering planning pending",
        rule: String? = "render HUD, scope, and map labels through a scalable text path",
        mode: String? = "signed-distance-style SwiftUI text pass",
        fontFamily: String? = "monospaced system",
        coverage: [String]? = nil,
        outlinePixels: Float? = 1.0,
        shadowPixels: Float? = 2.0,
        minimumScaleFactor: Float? = 0.58,
        mapLabelRule: String? = "keep map road and sector labels crisp across canvas scale",
        scopeRule: String? = "keep scope status text readable over reticle and aperture",
        fallbackRule: String? = "fall back to system vector text if SDF atlas generation is unavailable",
        measurementRule: String? = "verify HUD, scope, and map text at capture resolutions"
    ) {
        self.status = status
        self.rule = rule
        self.mode = mode
        self.fontFamily = fontFamily
        self.coverage = coverage
        self.outlinePixels = outlinePixels
        self.shadowPixels = shadowPixels
        self.minimumScaleFactor = minimumScaleFactor
        self.mapLabelRule = mapLabelRule
        self.scopeRule = scopeRule
        self.fallbackRule = fallbackRule
        self.measurementRule = measurementRule
    }
}

struct RenderGraphConfiguration: Decodable {
    let status: String?
    let rule: String?
    let mode: String?
    let passOrder: [String]?
    let importedResources: [String]?
    let transientResources: [String]?
    let aliasingRule: String?
    let validationRule: String?
    let expansionRule: String?

    init(
        status: String? = "render graph planning pending",
        rule: String? = "describe renderer pass order and resource ownership before adding more passes",
        mode: String? = "manual frame graph descriptor",
        passOrder: [String]? = nil,
        importedResources: [String]? = nil,
        transientResources: [String]? = nil,
        aliasingRule: String? = "no transient aliasing until graph validation is visible",
        validationRule: String? = "verify pass reads are produced or imported before execution",
        expansionRule: String? = "promote CSM, SSR, SSAO, and capture passes into graph nodes as they mature"
    ) {
        self.status = status
        self.rule = rule
        self.mode = mode
        self.passOrder = passOrder
        self.importedResources = importedResources
        self.transientResources = transientResources
        self.aliasingRule = aliasingRule
        self.validationRule = validationRule
        self.expansionRule = expansionRule
    }
}

struct AudioMixConfiguration: Decodable {
    let status: String?
    let rule: String?
    let mode: String?
    let masterGain: Float?
    let ambienceGain: Float?
    let movementGain: Float?
    let scopeGain: Float?
    let weaponGain: Float?
    let observerGain: Float?
    let footstepSurfaces: [String]?
    let ambienceBeds: [String]?
    let mixRule: String?
    let smokeRule: String?
}

struct SessionPersistenceConfiguration: Decodable {
    let status: String?
    let rule: String?

    init(
        status: String? = "session persistence planning pending",
        rule: String? = "capture route, checkpoint, difficulty, map, and review state before save/resume activation"
    ) {
        self.status = status
        self.rule = rule
    }
}

struct RouteConfiguration: Decodable {
    let name: String
    let summary: String
    let checkpoints: [RouteCheckpointConfiguration]
}

struct ReviewPackConfiguration: Decodable {
    let title: String
    let summary: String
    let referenceGallery: String
    let textureLibrary: String
    let captureFormat: String
    let openRisks: [String]
    let comparisonStops: [ReviewComparisonStopConfiguration]

    init(
        title: String = "Review Pack unavailable",
        summary: String = "Reference-backed review data unavailable.",
        referenceGallery: String = "Unavailable",
        textureLibrary: String = "Unavailable",
        captureFormat: String = "Unavailable",
        openRisks: [String] = [],
        comparisonStops: [ReviewComparisonStopConfiguration] = []
    ) {
        self.title = title
        self.summary = summary
        self.referenceGallery = referenceGallery
        self.textureLibrary = textureLibrary
        self.captureFormat = captureFormat
        self.openRisks = openRisks
        self.comparisonStops = comparisonStops
    }
}

struct ReviewComparisonStopConfiguration: Decodable {
    let checkpointID: String
    let district: String
    let sourceFocus: String
    let combatLane: String
    let captureNote: String
}

struct CombatRehearsalConfiguration: Decodable {
    let title: String
    let summary: String
    let exposureGuide: String
    let recoveryRule: String
    let contactStops: [CombatContactStopConfiguration]

    init(
        title: String = "Combat rehearsal unavailable",
        summary: String = "Combat-lane rehearsal data unavailable.",
        exposureGuide: String = "Unavailable",
        recoveryRule: String = "Unavailable",
        contactStops: [CombatContactStopConfiguration] = []
    ) {
        self.title = title
        self.summary = summary
        self.exposureGuide = exposureGuide
        self.recoveryRule = recoveryRule
        self.contactStops = contactStops
    }
}

struct CombatContactStopConfiguration: Decodable {
    let checkpointID: String
    let district: String
    let lane: String
    let exposure: String
    let expectedObservers: Int
    let coverHint: String
    let recoveryNote: String
}

struct MissionScriptConfiguration: Decodable {
    let title: String
    let summary: String
    let phases: [MissionPhaseConfiguration]

    init(
        title: String = "Mission script unavailable",
        summary: String = "Mission scripting hooks unavailable.",
        phases: [MissionPhaseConfiguration] = []
    ) {
        self.title = title
        self.summary = summary
        self.phases = phases
    }
}

struct MissionPhaseConfiguration: Decodable {
    let checkpointID: String
    let phase: String
    let objective: String
    let trigger: String
    let successCue: String
    let failureCue: String
    let mapCode: String?
}

struct RouteSelectionConfiguration: Decodable {
    let activeRouteID: String
    let activeRouteLabel: String
    let selectedAlternateRouteID: String?
    let selectedAlternateRouteLabel: String?
    let bindingStatus: String
    let loaderStatus: String
    let validationStatus: String
    let validationRule: String
    let selectionStatus: String?
    let selectionRule: String?
    let activationStatus: String?
    let activationRule: String?
    let rollbackStatus: String?
    let rollbackRule: String?
    let commitStatus: String?
    let commitRule: String?
    let dryRunStatus: String?
    let dryRunRule: String?
    let promotionStatus: String?
    let promotionRule: String?
    let auditStatus: String?
    let auditRule: String?
    let boundaryStatus: String?
    let boundaryRule: String?
    let armingStatus: String?
    let armingRule: String?
    let confirmationStatus: String?
    let confirmationRule: String?
    let releaseStatus: String?
    let releaseRule: String?
    let preflightStatus: String?
    let preflightRule: String?
    let handoffStatus: String
    let handoffRule: String
}

struct CollisionAuthoringConfiguration: Decodable {
    let status: String
    let rule: String
    let audit: String
    let blockerScope: String
    let selectedVolumeID: String?
    let selectedVolumeLabel: String?
    let validationStatus: String?
    let exportStatus: String?
    let reviewGuidance: String?
    let minimumClearanceMeters: Float?
}

struct AlternateRouteConfiguration: Decodable {
    let id: String
    let name: String
    let summary: String
    let startCheckpointID: String
    let goalCheckpointID: String
    let checkpointIDs: [String]
    let routeType: String
    let authoringStatus: String
    let selectionMode: String?
    let selectionStatus: String?
    let activationRule: String?
    let checkpointOwnershipStatus: String?
    let sharedCheckpointIDs: [String]?
    let exclusiveCheckpointIDs: [String]?
}

struct RouteCheckpointConfiguration: Decodable {
    let id: String
    let label: String
    let position: [Float]
    let triggerRadius: Float
    let yawDegrees: Float?
    let pitchDegrees: Float?
    let goal: Bool?
    let beaconColor: [Float]?
    let beaconHeight: Float?

    var positionVector: SIMD3<Float> {
        position.simd3(or: .zero)
    }

    var beaconColorVector: SIMD4<Float> {
        beaconColor?.simdColor(or: defaultBeaconColor) ?? defaultBeaconColor
    }

    var defaultBeaconColor: SIMD4<Float> {
        (goal ?? false)
            ? SIMD4<Float>(0.36, 0.86, 0.56, 0.88)
            : SIMD4<Float>(0.33, 0.72, 0.96, 0.84)
    }
}

struct MaterialConfiguration: Decodable {
    let albedoTexture: String?
    let normalTexture: String?
    let roughnessTexture: String?
    let ambientOcclusionTexture: String?
    let baseColor: [Float]?
    let roughness: Float?
    let ambientOcclusionStrength: Float?
    let normalScale: Float?

    init(
        albedoTexture: String? = nil,
        normalTexture: String? = nil,
        roughnessTexture: String? = nil,
        ambientOcclusionTexture: String? = nil,
        baseColor: [Float]? = nil,
        roughness: Float? = nil,
        ambientOcclusionStrength: Float? = nil,
        normalScale: Float? = nil
    ) {
        self.albedoTexture = albedoTexture
        self.normalTexture = normalTexture
        self.roughnessTexture = roughnessTexture
        self.ambientOcclusionTexture = ambientOcclusionTexture
        self.baseColor = baseColor
        self.roughness = roughness
        self.ambientOcclusionStrength = ambientOcclusionStrength
        self.normalScale = normalScale
    }

    var baseColorVector: SIMD4<Float>? {
        baseColor?.simdColor(or: SIMD4<Float>(1, 1, 1, 1))
    }
}

enum ProceduralElementKind: String, Decodable {
    case checkerboard
    case box
}

struct ProceduralElementConfiguration: Decodable {
    let kind: ProceduralElementKind
    let name: String
    let position: [Float]?
    let halfExtents: [Float]?
    let size: Int?
    let tileSize: Float?
    let color: [Float]?
    let colorA: [Float]?
    let colorB: [Float]?
    let yawDegrees: Float?
    let material: MaterialConfiguration?
    let castsShadow: Bool?
    let receivesShadow: Bool?

    var positionVector: SIMD3<Float> {
        position?.simd3(or: .zero) ?? .zero
    }

    var halfExtentsVector: SIMD3<Float> {
        halfExtents?.simd3(or: SIMD3<Float>(1, 1, 1)) ?? SIMD3<Float>(1, 1, 1)
    }

    var colorVector: SIMD4<Float> {
        color?.simdColor(or: SIMD4<Float>(0.60, 0.63, 0.68, 1)) ?? SIMD4<Float>(0.60, 0.63, 0.68, 1)
    }

    var checkerColorA: SIMD4<Float> {
        colorA?.simdColor(or: SIMD4<Float>(0.18, 0.22, 0.26, 1)) ?? SIMD4<Float>(0.18, 0.22, 0.26, 1)
    }

    var checkerColorB: SIMD4<Float> {
        colorB?.simdColor(or: SIMD4<Float>(0.23, 0.28, 0.33, 1)) ?? SIMD4<Float>(0.23, 0.28, 0.33, 1)
    }
}

struct AssetInstanceConfiguration: Decodable {
    let category: String
    let name: String
    let position: [Float]
    let targetExtent: Float
    let yawDegrees: Float?
    let material: MaterialConfiguration?
    let castsShadow: Bool?
    let receivesShadow: Bool?

    var positionVector: SIMD3<Float> {
        position.simd3(or: .zero)
    }
}

struct SectorConfiguration: Decodable {
    let id: String
    let displayName: String
    let residency: SectorResidency?
    let farFieldPadding: Float?
    let bounds: BoundsConfiguration
    let streamingPadding: Float?
    let terrainPatches: [TerrainPatchConfiguration]
    let roadStrips: [RoadStripConfiguration]
    let grayboxBlocks: [GrayboxBlockConfiguration]
    let collisionVolumes: [CollisionVolumeConfiguration]
}

enum SectorResidency: String, Decodable {
    case local
    case farField
    case always
}

struct BoundsConfiguration: Decodable {
    let min: [Float]
    let max: [Float]

    var minimum: SIMD3<Float> {
        min.simd3(or: SIMD3<Float>(-1, 0, -1))
    }

    var maximum: SIMD3<Float> {
        max.simd3(or: SIMD3<Float>(1, 1, 1))
    }
}

struct TerrainPatchConfiguration: Decodable {
    let name: String
    let position: [Float]
    let size: [Float]
    let cornerHeights: [Float]
    let subdivisions: Int?
    let color: [Float]
    let yawDegrees: Float?
    let material: MaterialConfiguration?
    let castsShadow: Bool?
    let receivesShadow: Bool?

    var positionVector: SIMD3<Float> {
        position.simd3(or: .zero)
    }

    var sizeVector: SIMD2<Float> {
        size.simd2(or: SIMD2<Float>(8, 8))
    }

    var cornerHeightVector: SIMD4<Float> {
        cornerHeights.simd4(or: SIMD4<Float>(repeating: 0))
    }

    var colorVector: SIMD4<Float> {
        color.simdColor(or: SIMD4<Float>(0.33, 0.42, 0.30, 1))
    }
}

struct RoadStripConfiguration: Decodable {
    let name: String
    let position: [Float]
    let size: [Float]
    let roadColor: [Float]?
    let shoulderColor: [Float]?
    let lineColor: [Float]?
    let shoulderWidth: Float?
    let centerLineWidth: Float?
    let crownHeight: Float?
    let yawDegrees: Float?
    let material: MaterialConfiguration?
    let castsShadow: Bool?
    let receivesShadow: Bool?

    var positionVector: SIMD3<Float> {
        position.simd3(or: .zero)
    }

    var sizeVector: SIMD2<Float> {
        size.simd2(or: SIMD2<Float>(6, 14))
    }

    var roadColorVector: SIMD4<Float> {
        roadColor?.simdColor(or: SIMD4<Float>(0.18, 0.19, 0.21, 1)) ?? SIMD4<Float>(0.18, 0.19, 0.21, 1)
    }

    var shoulderColorVector: SIMD4<Float> {
        shoulderColor?.simdColor(or: SIMD4<Float>(0.39, 0.42, 0.35, 1)) ?? SIMD4<Float>(0.39, 0.42, 0.35, 1)
    }

    var lineColorVector: SIMD4<Float> {
        lineColor?.simdColor(or: SIMD4<Float>(0.89, 0.84, 0.49, 1)) ?? SIMD4<Float>(0.89, 0.84, 0.49, 1)
    }
}

struct GrayboxBlockConfiguration: Decodable {
    let name: String
    let position: [Float]
    let halfExtents: [Float]
    let color: [Float]
    let yawDegrees: Float?
    let material: MaterialConfiguration?
    let collisionEnabled: Bool?
    let contributesToGround: Bool?
    let castsShadow: Bool?
    let receivesShadow: Bool?

    var positionVector: SIMD3<Float> {
        position.simd3(or: .zero)
    }

    var halfExtentsVector: SIMD3<Float> {
        halfExtents.simd3(or: SIMD3<Float>(1, 1, 1))
    }

    var colorVector: SIMD4<Float> {
        color.simdColor(or: SIMD4<Float>(0.45, 0.50, 0.56, 1))
    }

    var contributesToGroundSurface: Bool {
        contributesToGround ?? false
    }
}

struct CollisionVolumeConfiguration: Decodable {
    let name: String
    let position: [Float]
    let halfExtents: [Float]
    let yawDegrees: Float?

    var positionVector: SIMD3<Float> {
        position.simd3(or: .zero)
    }

    var halfExtentsVector: SIMD3<Float> {
        halfExtents.simd3(or: SIMD3<Float>(1, 1, 1))
    }
}

struct WorldGroundSurfaceSampler {
    let surfaces: [GameGroundSurface]

    func sampleHeight(at position: SIMD3<Float>) -> Float? {
        sampleHeight(x: position.x, z: position.z)
    }

    func sampleHeight(x: Float, z: Float) -> Float? {
        var highestHeight: Float = 0
        var foundSurface = false

        for surface in surfaces {
            let sample = projectedSample(x: x, z: z, surface: surface)

            if !sample.isWithinSurface {
                continue
            }

            if !foundSurface || sample.height > highestHeight {
                highestHeight = sample.height
                foundSurface = true
            }
        }

        return foundSurface ? highestHeight : nil
    }

    func groundedPosition(_ position: SIMD3<Float>, verticalOffset: Float = 0) -> SIMD3<Float> {
        guard let sampledHeight = sampleHeight(at: position) else {
            return SIMD3<Float>(position.x, position.y + verticalOffset, position.z)
        }

        return SIMD3<Float>(position.x, sampledHeight + verticalOffset, position.z)
    }

    func projectedSample(x: Float, z: Float, surface: GameGroundSurface) -> (height: Float, distanceSquared: Float, isWithinSurface: Bool) {
        let localPosition = rotateIntoLocalFrame(
            point: SIMD2<Float>(x - surface.centerX, z - surface.centerZ),
            yawDegrees: surface.yawDegrees
        )
        let clampedX = min(max(localPosition.x, -surface.halfWidth), surface.halfWidth)
        let clampedZ = min(max(localPosition.y, -surface.halfDepth), surface.halfDepth)
        let deltaX = localPosition.x - clampedX
        let deltaZ = localPosition.y - clampedZ
        let u = surface.halfWidth > 0
            ? (clampedX + surface.halfWidth) / (surface.halfWidth * 2)
            : 0.5
        let v = surface.halfDepth > 0
            ? (clampedZ + surface.halfDepth) / (surface.halfDepth * 2)
            : 0.5

        return (
            height: sampledHeight(on: surface, u: u, v: v),
            distanceSquared: (deltaX * deltaX) + (deltaZ * deltaZ),
            isWithinSurface: deltaX == 0 && deltaZ == 0
        )
    }

    private func rotateIntoLocalFrame(point: SIMD2<Float>, yawDegrees: Float) -> SIMD2<Float> {
        let radians = (-yawDegrees) * (.pi / 180)
        let cosine = cosf(radians)
        let sine = sinf(radians)
        return SIMD2<Float>(
            (point.x * cosine) - (point.y * sine),
            (point.x * sine) + (point.y * cosine)
        )
    }

    private func sampledHeight(on surface: GameGroundSurface, u: Float, v: Float) -> Float {
        let northHeight = surface.northWestHeight + ((surface.northEastHeight - surface.northWestHeight) * u)
        let southHeight = surface.southWestHeight + ((surface.southEastHeight - surface.southWestHeight) * u)
        return northHeight + ((southHeight - northHeight) * v)
    }
}

struct WorldGroundModel {
    let localSurfaces: [GameGroundSurface]
    let continuitySurfaces: [GameGroundSurface]
    let allSurfaces: [GameGroundSurface]
    let sampler: WorldGroundSurfaceSampler
}

enum WorldRuntimeConversions {
    static let playerEyeHeight: Float = 1.65
    static let continuityTileSize: Float = 24

    static func sectorBounds(from sectors: [SectorConfiguration]) -> [GameSectorBounds] {
        sectors.map { sector in
            let minimum = sector.bounds.minimum
            let maximum = sector.bounds.maximum
            return GameSectorBounds(
                minX: minimum.x,
                minZ: minimum.z,
                maxX: maximum.x,
                maxZ: maximum.z,
                activationPadding: sector.streamingPadding ?? 10
            )
        }
    }

    static func groundModel(from sectors: [SectorConfiguration]) -> WorldGroundModel {
        let localSurfaces = localGroundSurfaces(from: sectors)
        let continuitySurfaces = continuityGroundSurfaces(from: sectors)
        let allSurfaces = localSurfaces + continuitySurfaces
        let sampler = WorldGroundSurfaceSampler(surfaces: allSurfaces)

        return WorldGroundModel(
            localSurfaces: localSurfaces,
            continuitySurfaces: continuitySurfaces,
            allSurfaces: allSurfaces,
            sampler: sampler
        )
    }

    static func groundSurfaces(from sectors: [SectorConfiguration]) -> [GameGroundSurface] {
        groundModel(from: sectors).allSurfaces
    }

    static func localGroundSurfaces(from sectors: [SectorConfiguration]) -> [GameGroundSurface] {
        var surfaces: [GameGroundSurface] = []

        for sector in sectors {
            surfaces.append(contentsOf: sector.terrainPatches.map(groundSurface(from:)))
            surfaces.append(contentsOf: sector.roadStrips.map(groundSurface(from:)))
            surfaces.append(contentsOf: sector.grayboxBlocks.compactMap(groundSurface(from:)))
        }

        return surfaces
    }

    static func terrainGroundSurfaces(from sectors: [SectorConfiguration]) -> [GameGroundSurface] {
        sectors.flatMap { sector in
            sector.terrainPatches.map(groundSurface(from:))
        }
    }

    static func continuityGroundSurfaces(
        from sectors: [SectorConfiguration],
        tileSize: Float = continuityTileSize
    ) -> [GameGroundSurface] {
        let terrainSurfaces = terrainGroundSurfaces(from: sectors)
        guard
            !terrainSurfaces.isEmpty,
            let bounds = combinedGroundBounds(from: sectors)
        else {
            return []
        }

        let width = max(bounds.maxX - bounds.minX, tileSize)
        let depth = max(bounds.maxZ - bounds.minZ, tileSize)
        let columns = max(Int(ceil(width / tileSize)), 1)
        let rows = max(Int(ceil(depth / tileSize)), 1)
        let stepX = width / Float(columns)
        let stepZ = depth / Float(rows)
        let terrainSampler = WorldGroundSurfaceSampler(surfaces: terrainSurfaces)

        var heightGrid = [Float](repeating: 0, count: (columns + 1) * (rows + 1))

        func gridIndex(column: Int, row: Int) -> Int {
            (row * (columns + 1)) + column
        }

        for row in 0...rows {
            let z = bounds.minZ + (Float(row) * stepZ)

            for column in 0...columns {
                let x = bounds.minX + (Float(column) * stepX)
                heightGrid[gridIndex(column: column, row: row)] = continuityHeight(
                    x: x,
                    z: z,
                    sampler: terrainSampler
                )
            }
        }

        var continuitySurfaces: [GameGroundSurface] = []
        continuitySurfaces.reserveCapacity(columns * rows)

        for row in 0..<rows {
            let z0 = bounds.minZ + (Float(row) * stepZ)
            let z1 = bounds.minZ + (Float(row + 1) * stepZ)

            for column in 0..<columns {
                let x0 = bounds.minX + (Float(column) * stepX)
                let x1 = bounds.minX + (Float(column + 1) * stepX)
                continuitySurfaces.append(
                    GameGroundSurface(
                        centerX: (x0 + x1) * 0.5,
                        centerZ: (z0 + z1) * 0.5,
                        halfWidth: (x1 - x0) * 0.5,
                        halfDepth: (z1 - z0) * 0.5,
                        yawDegrees: 0,
                        northWestHeight: heightGrid[gridIndex(column: column, row: row)],
                        northEastHeight: heightGrid[gridIndex(column: column + 1, row: row)],
                        southEastHeight: heightGrid[gridIndex(column: column + 1, row: row + 1)],
                        southWestHeight: heightGrid[gridIndex(column: column, row: row + 1)]
                    )
                )
            }
        }

        return continuitySurfaces
    }

    static func collisionVolumes(from sectors: [SectorConfiguration]) -> [GameCollisionVolume] {
        var volumes: [GameCollisionVolume] = []

        for sector in sectors {
            for block in sector.grayboxBlocks where block.collisionEnabled ?? true {
                volumes.append(collisionVolume(from: block))
            }
            volumes.append(contentsOf: sector.collisionVolumes.map(collisionVolume(from:)))
        }

        return volumes
    }

    static func routeCheckpoints(
        from checkpoints: [RouteCheckpointConfiguration],
        groundSampler: WorldGroundSurfaceSampler?
    ) -> [GameRouteCheckpoint] {
        checkpoints.map { checkpoint in
            let groundedPosition = groundedPosition(
                for: checkpoint.positionVector,
                groundSampler: groundSampler
            )

            return GameRouteCheckpoint(
                positionX: groundedPosition.x,
                positionY: groundedPosition.y + playerEyeHeight,
                positionZ: groundedPosition.z,
                triggerRadius: checkpoint.triggerRadius,
                yawDegrees: checkpoint.yawDegrees ?? 0,
                pitchDegrees: checkpoint.pitchDegrees ?? -12,
                isGoal: checkpoint.goal ?? false
            )
        }
    }

    static func threatObservers(from observers: [ThreatObserverConfiguration]) -> [GameThreatObserver] {
        var groupIndices: [String: Int32] = [:]
        var nextGroupIndex: Int32 = 1

        return observers.map { observer in
            let trimmedGroupID = observer.groupID?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let resolvedGroupIndex: Int32
            if let trimmedGroupID, !trimmedGroupID.isEmpty {
                if let existingIndex = groupIndices[trimmedGroupID] {
                    resolvedGroupIndex = existingIndex
                } else {
                    resolvedGroupIndex = nextGroupIndex
                    groupIndices[trimmedGroupID] = resolvedGroupIndex
                    nextGroupIndex += 1
                }
            } else {
                resolvedGroupIndex = 0
            }

            let patrolRouteID = observer.patrolRouteID?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let patrolRole = observer.patrolRole?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            let formationSpacing = max(observer.formationSpacingMeters ?? 0.0, 0.0)
            let patrolEnabled = patrolRouteID?.isEmpty == false && formationSpacing > 0.0
            let rolePhaseOffset: Float = patrolRole?.contains("wing") == true ? .pi : 0.0
            let scanCycleSeconds = max(observer.scanCycleSeconds ?? 5.2, 0.0)

            return GameThreatObserver(
                positionX: observer.positionVector.x,
                positionY: observer.positionVector.y,
                positionZ: observer.positionVector.z,
                yawDegrees: observer.yawDegrees,
                pitchDegrees: observer.pitchDegrees ?? 0,
                range: observer.range,
                fieldOfViewDegrees: observer.fieldOfViewDegrees,
                suspicionPerSecond: observer.suspicionPerSecond,
                groupIndex: resolvedGroupIndex,
                groupRelayRangeMeters: max(
                    observer.groupRelayRangeMeters
                        ?? (resolvedGroupIndex > 0 ? 28.0 : 0.0),
                    0.0
                ),
                alertMemorySeconds: max(observer.alertMemorySeconds ?? 2.4, 0.0),
                alertedFieldOfViewDegrees: max(
                    observer.alertedFieldOfViewDegrees ?? 74.0,
                    observer.fieldOfViewDegrees
                ),
                turnRateDegreesPerSecond: max(observer.turnRateDegreesPerSecond ?? 78.0, 0.0),
                scanArcDegrees: max(observer.scanArcDegrees ?? (resolvedGroupIndex > 0 ? 28.0 : 0.0), 0.0),
                scanCycleSeconds: scanCycleSeconds,
                patrolStrideMeters: patrolEnabled
                    ? min(max(formationSpacing * 0.65, 2.4), 16.0)
                    : 0.0,
                patrolPhaseOffsetRadians: rolePhaseOffset,
                patrolCycleSeconds: patrolEnabled
                    ? min(max(scanCycleSeconds * 1.9, 6.0), 24.0)
                    : 0.0,
                patrolEnabled: patrolEnabled
            )
        }
    }

    static func groundedPosition(
        for position: SIMD3<Float>,
        groundSampler: WorldGroundSurfaceSampler?,
        verticalOffset: Float = 0
    ) -> SIMD3<Float> {
        groundSampler?.groundedPosition(position, verticalOffset: verticalOffset)
            ?? SIMD3<Float>(position.x, position.y + verticalOffset, position.z)
    }

    static func groundedSpawn(
        from spawn: SpawnConfiguration,
        groundSampler: WorldGroundSurfaceSampler?
    ) -> SpawnConfiguration {
        let groundedPosition = groundedPosition(
            for: SIMD3<Float>(spawn.positionVector.x, 0, spawn.positionVector.z),
            groundSampler: groundSampler,
            verticalOffset: playerEyeHeight
        )

        return SpawnConfiguration(
            label: spawn.label,
            position: [groundedPosition.x, groundedPosition.y, groundedPosition.z],
            yawDegrees: spawn.yawDegrees,
            pitchDegrees: spawn.pitchDegrees
        )
    }

    static func groundSurface(from configuration: TerrainPatchConfiguration) -> GameGroundSurface {
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

    static func groundSurface(from configuration: RoadStripConfiguration) -> GameGroundSurface {
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

    static func groundSurface(from configuration: GrayboxBlockConfiguration) -> GameGroundSurface? {
        guard configuration.contributesToGroundSurface else {
            return nil
        }

        let topHeight = configuration.positionVector.y + configuration.halfExtentsVector.y
        return GameGroundSurface(
            centerX: configuration.positionVector.x,
            centerZ: configuration.positionVector.z,
            halfWidth: configuration.halfExtentsVector.x,
            halfDepth: configuration.halfExtentsVector.z,
            yawDegrees: configuration.yawDegrees ?? 0,
            northWestHeight: topHeight,
            northEastHeight: topHeight,
            southEastHeight: topHeight,
            southWestHeight: topHeight
        )
    }

    static func collisionVolume(from configuration: GrayboxBlockConfiguration) -> GameCollisionVolume {
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

    static func collisionVolume(from configuration: CollisionVolumeConfiguration) -> GameCollisionVolume {
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

    private static func combinedGroundBounds(from sectors: [SectorConfiguration]) -> (minX: Float, maxX: Float, minZ: Float, maxZ: Float)? {
        guard let firstSector = sectors.first else {
            return nil
        }

        var minX = firstSector.bounds.minimum.x
        var maxX = firstSector.bounds.maximum.x
        var minZ = firstSector.bounds.minimum.z
        var maxZ = firstSector.bounds.maximum.z

        for sector in sectors.dropFirst() {
            minX = min(minX, sector.bounds.minimum.x)
            maxX = max(maxX, sector.bounds.maximum.x)
            minZ = min(minZ, sector.bounds.minimum.z)
            maxZ = max(maxZ, sector.bounds.maximum.z)
        }

        return (minX, maxX, minZ, maxZ)
    }

    private static func continuityHeight(
        x: Float,
        z: Float,
        sampler: WorldGroundSurfaceSampler
    ) -> Float {
        if let authoredHeight = sampler.sampleHeight(x: x, z: z) {
            return authoredHeight
        }

        let nearestSamples = sampler.surfaces
            .map { sampler.projectedSample(x: x, z: z, surface: $0) }
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
}

extension Array where Element == Float {
    func simd2(or fallback: SIMD2<Float>) -> SIMD2<Float> {
        guard count >= 2 else {
            return fallback
        }

        return SIMD2<Float>(self[0], self[1])
    }

    func simd3(or fallback: SIMD3<Float>) -> SIMD3<Float> {
        guard count >= 3 else {
            return fallback
        }

        return SIMD3<Float>(self[0], self[1], self[2])
    }

    func simd4(or fallback: SIMD4<Float>) -> SIMD4<Float> {
        guard count >= 4 else {
            return fallback
        }

        return SIMD4<Float>(self[0], self[1], self[2], self[3])
    }

    func simdColor(or fallback: SIMD4<Float>) -> SIMD4<Float> {
        guard count >= 3 else {
            return fallback
        }

        let alpha = count >= 4 ? self[3] : 1
        return SIMD4<Float>(self[0], self[1], self[2], alpha)
    }
}
