import Foundation
import simd

struct SceneVertex {
    var position: SIMD3<Float>
    var normal: SIMD3<Float>
    var uv: SIMD2<Float>
    var color: SIMD4<Float>
}

struct SceneUniforms {
    var viewProjectionMatrix: simd_float4x4
    var modelMatrix: simd_float4x4
    var lightDirection: SIMD4<Float>
    var sunColor: SIMD4<Float>
    var cameraPosition: SIMD4<Float>
    var fogColor: SIMD4<Float>
    var lightingParameters: SIMD4<Float>
    var atmosphereParameters: SIMD4<Float>
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
