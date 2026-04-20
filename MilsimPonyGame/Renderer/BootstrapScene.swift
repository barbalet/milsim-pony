import Foundation
import MetalKit
import simd

struct SceneDrawable {
    let name: String
    let vertexBuffer: MTLBuffer
    let vertexCount: Int
    let modelMatrix: simd_float4x4
}

final class BootstrapScene {
    let drawables: [SceneDrawable]
    let summary: String

    init(device: MTLDevice, assetRoot: String) {
        var sceneDrawables: [SceneDrawable] = []
        var loadedAssets: [String] = []

        let groundVertices = GeometryBuilder.makeCheckerboard(size: 16, tileSize: 1.2)
        if let buffer = device.makeBuffer(bytes: groundVertices, length: MemoryLayout<SceneVertex>.stride * groundVertices.count) {
            sceneDrawables.append(
                SceneDrawable(
                    name: "Ground",
                    vertexBuffer: buffer,
                    vertexCount: groundVertices.count,
                    modelMatrix: .identity()
                )
            )
        }

        let pedestalVertices = GeometryBuilder.makeBox(
            halfExtents: SIMD3<Float>(0.55, 0.35, 0.55),
            color: SIMD4<Float>(0.58, 0.60, 0.66, 1)
        )

        for (name, position) in [("Left Pedestal", SIMD3<Float>(-1.4, 0.35, 0)), ("Right Pedestal", SIMD3<Float>(1.4, 0.35, 0))] {
            if let buffer = device.makeBuffer(bytes: pedestalVertices, length: MemoryLayout<SceneVertex>.stride * pedestalVertices.count) {
                sceneDrawables.append(
                    SceneDrawable(
                        name: name,
                        vertexBuffer: buffer,
                        vertexCount: pedestalVertices.count,
                        modelMatrix: .translation(position)
                    )
                )
            }
        }

        let backdropVertices = GeometryBuilder.makeBox(
            halfExtents: SIMD3<Float>(7.5, 1.6, 0.25),
            color: SIMD4<Float>(0.30, 0.37, 0.44, 1)
        )
        if let buffer = device.makeBuffer(bytes: backdropVertices, length: MemoryLayout<SceneVertex>.stride * backdropVertices.count) {
            sceneDrawables.append(
                SceneDrawable(
                    name: "Backdrop",
                    vertexBuffer: buffer,
                    vertexCount: backdropVertices.count,
                    modelMatrix: .translation(SIMD3<Float>(0, 1.6, -5.8))
                )
            )
        }

        for (name, category, position, targetExtent) in [
            ("Compass_Open", "Props", SIMD3<Float>(-1.4, 0.70, 0), Float(1.1)),
            ("Knife", "Props", SIMD3<Float>(1.4, 0.70, 0), Float(1.25)),
        ] {
            if let asset = OBJAssetLoader.loadAsset(named: name, category: category, assetRoot: assetRoot),
               let buffer = device.makeBuffer(bytes: asset.vertices, length: MemoryLayout<SceneVertex>.stride * asset.vertices.count)
            {
                let maxExtent = max(asset.extent.x, max(asset.extent.y, asset.extent.z))
                let scale = targetExtent / max(maxExtent, 0.001)
                let normalization = simd_float4x4.scale(SIMD3<Float>(repeating: scale)) * simd_float4x4.translation(
                    SIMD3<Float>(
                        -asset.center.x,
                        -asset.boundsMin.y,
                        -asset.center.z
                    )
                )

                sceneDrawables.append(
                    SceneDrawable(
                        name: name,
                        vertexBuffer: buffer,
                        vertexCount: asset.vertices.count,
                        modelMatrix: simd_float4x4.translation(position) * normalization
                    )
                )

                loadedAssets.append(name)
            }
        }

        drawables = sceneDrawables
        summary = loadedAssets.isEmpty
            ? "Procedural ground and pedestals"
            : "Procedural ground plus props: \(loadedAssets.joined(separator: ", "))"
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
    static func makeCheckerboard(size: Int, tileSize: Float) -> [SceneVertex] {
        var vertices: [SceneVertex] = []
        let half = Float(size) * tileSize * 0.5

        for row in 0..<size {
            for column in 0..<size {
                let x0 = -half + (Float(column) * tileSize)
                let z0 = -half + (Float(row) * tileSize)
                let x1 = x0 + tileSize
                let z1 = z0 + tileSize
                let isDark = (row + column).isMultiple(of: 2)
                let color = isDark
                    ? SIMD4<Float>(0.18, 0.22, 0.26, 1)
                    : SIMD4<Float>(0.23, 0.28, 0.33, 1)

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
