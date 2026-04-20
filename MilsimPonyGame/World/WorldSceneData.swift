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
    let proceduralElements: [ProceduralElementConfiguration]
    let assetInstances: [AssetInstanceConfiguration]
    let includedSectors: [String]
}

struct SpawnConfiguration: Decodable {
    let position: [Float]
    let yawDegrees: Float
    let pitchDegrees: Float

    var positionVector: SIMD3<Float> {
        position.simd3(or: SIMD3<Float>(0, 1.65, 4.5))
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
    let grayboxBlocks: [GrayboxBlockConfiguration]
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

struct GrayboxBlockConfiguration: Decodable {
    let name: String
    let position: [Float]
    let halfExtents: [Float]
    let color: [Float]
    let yawDegrees: Float?

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

extension Array where Element == Float {
    func simd3(or fallback: SIMD3<Float>) -> SIMD3<Float> {
        guard count >= 3 else {
            return fallback
        }

        return SIMD3<Float>(self[0], self[1], self[2])
    }

    func simdColor(or fallback: SIMD4<Float>) -> SIMD4<Float> {
        guard count >= 3 else {
            return fallback
        }

        let alpha = count >= 4 ? self[3] : 1
        return SIMD4<Float>(self[0], self[1], self[2], alpha)
    }
}
