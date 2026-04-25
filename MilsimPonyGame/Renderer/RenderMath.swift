import Foundation
import simd

enum JungleBiomeKind {
    case grassland
    case jungle
    case beach
}

enum JungleWeatherKind {
    case clearBreeze
    case humidCanopy
    case coastalHaze
}

struct JungleMaterialChannel {
    let red: Float
    let green: Float
    let blue: Float
    let alpha: Float
    let motion: Float
    let wetnessResponse: Float
}

struct JungleTerrainSample {
    let position: SIMD3<Float>
    let groundCover: Float
    let waist: Float
    let head: Float
    let canopy: Float
    let wetness: Float
}

struct JungleTerrainPatch {
    let sampleSide: Int
    let spacing: Float
    let center: SIMD3<Float>
    let samples: [JungleTerrainSample]
}

struct JungleTerrainFrame {
    let cameraPosition: SIMD3<Float>
    let cameraForward: SIMD3<Float>
    let cameraRight: SIMD3<Float>
    let cameraFloorHeight: Float
    let simulatedTimeSeconds: Double
    let currentBiome: JungleBiomeKind
    let currentWeather: JungleWeatherKind
    let biomeBlend: Float
    let groundCoverHeight: Float
    let waistHeight: Float
    let headHeight: Float
    let canopyHeight: Float
    let visibilityDistance: Float
    let ambientWetness: Float
    let shorelineSpace: Float
    let windDirection: SIMD2<Float>
    let windStrength: Float
    let gustStrength: Float
    let vegetationResponse: Float
    let shorelineRippleStrength: Float
    let waterSurfaceResponse: Float
    let terrainPatch: JungleTerrainPatch
    let groundMaterial: JungleMaterialChannel
    let groundCoverMaterial: JungleMaterialChannel
    let waistMaterial: JungleMaterialChannel
    let headMaterial: JungleMaterialChannel
    let canopyMaterial: JungleMaterialChannel
    let viewProjectionMatrix: simd_float4x4
}

struct SceneVertex {
    var position: SIMD3<Float>
    var normal: SIMD3<Float>
    var tangent: SIMD4<Float>
    var uv: SIMD2<Float>
    var color: SIMD4<Float>
}

struct SceneUniforms {
    var viewProjectionMatrix: simd_float4x4
    var shadowViewProjectionMatrix: simd_float4x4
    var modelMatrix: simd_float4x4
    var lightDirection: SIMD4<Float>
    var sunColor: SIMD4<Float>
    var cameraPosition: SIMD4<Float>
    var fogColor: SIMD4<Float>
    var lightingParameters: SIMD4<Float>
    var atmosphereParameters: SIMD4<Float>
    var shadowParameters: SIMD4<Float>
    var motionParameters: SIMD4<Float>
    var dynamicLightParameters: SIMD4<Float>
    var dynamicLightPosition0: SIMD4<Float>
    var dynamicLightColor0: SIMD4<Float>
    var dynamicLightPosition1: SIMD4<Float>
    var dynamicLightColor1: SIMD4<Float>
    var dynamicLightPosition2: SIMD4<Float>
    var dynamicLightColor2: SIMD4<Float>
    var dynamicLightPosition3: SIMD4<Float>
    var dynamicLightColor3: SIMD4<Float>
}

struct SceneMaterialUniforms {
    var baseColorFactor: SIMD4<Float>
    var channelFactors: SIMD4<Float>
}

struct ScenePostProcessUniforms {
    var exposureParameters: SIMD4<Float>
    var shadowTint: SIMD4<Float>
    var highlightTint: SIMD4<Float>
    var gradeParameters: SIMD4<Float>
    var aoParameters: SIMD4<Float>
    var antiAliasingParameters: SIMD4<Float>
    var reflectionParameters: SIMD4<Float>
    var reflectionProbeColor: SIMD4<Float>
}

struct SkyUniforms {
    var horizonColor: SIMD4<Float>
    var zenithColor: SIMD4<Float>
    var sunColor: SIMD4<Float>
    var skyParameters: SIMD4<Float>
}

enum RenderMath {
    static func forwardVector(yawDegrees: Float, pitchDegrees: Float) -> SIMD3<Float> {
        let yaw = yawDegrees * (.pi / 180.0)
        let pitch = pitchDegrees * (.pi / 180.0)

        return simd_normalize(
            SIMD3<Float>(
                sinf(yaw) * cosf(pitch),
                sinf(pitch),
                -cosf(yaw) * cosf(pitch)
            )
        )
    }
}

extension simd_float4x4 {
    static func identity() -> simd_float4x4 {
        matrix_identity_float4x4
    }

    static func translation(_ translation: SIMD3<Float>) -> simd_float4x4 {
        simd_float4x4(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(translation.x, translation.y, translation.z, 1)
        )
    }

    static func scale(_ scale: SIMD3<Float>) -> simd_float4x4 {
        simd_float4x4(
            SIMD4<Float>(scale.x, 0, 0, 0),
            SIMD4<Float>(0, scale.y, 0, 0),
            SIMD4<Float>(0, 0, scale.z, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    }

    static func rotation(x radians: Float) -> simd_float4x4 {
        let cosine = cosf(radians)
        let sine = sinf(radians)

        return simd_float4x4(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, cosine, sine, 0),
            SIMD4<Float>(0, -sine, cosine, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    }

    static func rotation(y radians: Float) -> simd_float4x4 {
        let cosine = cosf(radians)
        let sine = sinf(radians)

        return simd_float4x4(
            SIMD4<Float>(cosine, 0, -sine, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(sine, 0, cosine, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    }

    static func perspective(fieldOfViewY: Float, aspectRatio: Float, nearZ: Float, farZ: Float) -> simd_float4x4 {
        let yScale = 1 / tanf(fieldOfViewY * 0.5)
        let xScale = yScale / aspectRatio
        let zRange = farZ - nearZ
        let zScale = -(farZ + nearZ) / zRange
        let wzScale = -2 * farZ * nearZ / zRange

        return simd_float4x4(
            SIMD4<Float>(xScale, 0, 0, 0),
            SIMD4<Float>(0, yScale, 0, 0),
            SIMD4<Float>(0, 0, zScale, -1),
            SIMD4<Float>(0, 0, wzScale, 0)
        )
    }

    static func orthographic(
        left: Float,
        right: Float,
        bottom: Float,
        top: Float,
        nearZ: Float,
        farZ: Float
    ) -> simd_float4x4 {
        let width = max(right - left, 0.001)
        let height = max(top - bottom, 0.001)
        let depth = max(farZ - nearZ, 0.001)

        return simd_float4x4(
            SIMD4<Float>(2.0 / width, 0, 0, 0),
            SIMD4<Float>(0, 2.0 / height, 0, 0),
            SIMD4<Float>(0, 0, -2.0 / depth, 0),
            SIMD4<Float>(
                -((right + left) / width),
                -((top + bottom) / height),
                -((farZ + nearZ) / depth),
                1
            )
        )
    }

    static func lookAt(eye: SIMD3<Float>, center: SIMD3<Float>, up: SIMD3<Float>) -> simd_float4x4 {
        let forward = simd_normalize(center - eye)
        let right = simd_normalize(simd_cross(forward, up))
        let correctedUp = simd_cross(right, forward)

        return simd_float4x4(
            SIMD4<Float>(right.x, correctedUp.x, -forward.x, 0),
            SIMD4<Float>(right.y, correctedUp.y, -forward.y, 0),
            SIMD4<Float>(right.z, correctedUp.z, -forward.z, 0),
            SIMD4<Float>(-simd_dot(right, eye), -simd_dot(correctedUp, eye), simd_dot(forward, eye), 1)
        )
    }
}
