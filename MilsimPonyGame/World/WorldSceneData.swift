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
    let atmosphere: AtmosphereConfiguration?
    let player: PlayerConfiguration?
    let scope: ScopeConfiguration?
    let route: RouteConfiguration
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

    init(
        label: String? = nil,
        magnification: Float = 4.0,
        fieldOfViewDegrees: Float = 15.0,
        lookSensitivityMultiplier: Float? = 0.26,
        drawDistanceMultiplier: Float? = 2.4,
        farPlaneMultiplier: Float? = 1.35,
        reticleColor: [Float]? = nil
    ) {
        self.label = label
        self.magnification = magnification
        self.fieldOfViewDegrees = fieldOfViewDegrees
        self.lookSensitivityMultiplier = lookSensitivityMultiplier
        self.drawDistanceMultiplier = drawDistanceMultiplier
        self.farPlaneMultiplier = farPlaneMultiplier
        self.reticleColor = reticleColor
    }

    var reticleColorVector: SIMD4<Float> {
        reticleColor?.simdColor(or: SIMD4<Float>(0.92, 0.86, 0.42, 0.94)) ?? SIMD4<Float>(0.92, 0.86, 0.42, 0.94)
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
    let markerColor: [Float]?

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

struct RouteConfiguration: Decodable {
    let name: String
    let summary: String
    let checkpoints: [RouteCheckpointConfiguration]
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
    let collisionEnabled: Bool?
    let contributesToGround: Bool?

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
        observers.map { observer in
            GameThreatObserver(
                positionX: observer.positionVector.x,
                positionY: observer.positionVector.y,
                positionZ: observer.positionVector.z,
                yawDegrees: observer.yawDegrees,
                pitchDegrees: observer.pitchDegrees ?? 0,
                range: observer.range,
                fieldOfViewDegrees: observer.fieldOfViewDegrees,
                suspicionPerSecond: observer.suspicionPerSecond
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
