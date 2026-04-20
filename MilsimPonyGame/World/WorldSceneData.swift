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
    let sceneName: String
    let spawn: SpawnConfiguration
    let sky: SkyConfiguration
    let sun: SunConfiguration
    let proceduralElements: [ProceduralElementConfiguration]
    let assetInstances: [AssetInstanceConfiguration]
    let includedSectors: [String]
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
    let bounds: BoundsConfiguration
    let streamingPadding: Float?
    let terrainPatches: [TerrainPatchConfiguration]
    let roadStrips: [RoadStripConfiguration]
    let grayboxBlocks: [GrayboxBlockConfiguration]
    let collisionVolumes: [CollisionVolumeConfiguration]
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

    var positionVector: SIMD3<Float> {
        position.simd3(or: .zero)
    }

    var halfExtentsVector: SIMD3<Float> {
        halfExtents.simd3(or: SIMD3<Float>(1, 1, 1))
    }

    var colorVector: SIMD4<Float> {
        color.simdColor(or: SIMD4<Float>(0.45, 0.50, 0.56, 1))
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
