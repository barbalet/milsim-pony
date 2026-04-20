import Foundation
import MetalKit
import simd

struct SceneDrawable {
    let name: String
    let vertexBuffer: MTLBuffer
    let vertexCount: Int
    let modelMatrix: simd_float4x4
}

struct SceneDebugInfo {
    let sceneName: String
    let summary: String
    let details: [String]
    let spawn: SpawnConfiguration
}

final class BootstrapScene {
    let drawables: [SceneDrawable]
    let debugInfo: SceneDebugInfo

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
        } catch {
            let fallbackResult = FallbackSceneFactory.build(
                device: device,
                worldDataRoot: worldDataRoot,
                worldManifestPath: worldManifestPath,
                errorDescription: error.localizedDescription
            )

            drawables = fallbackResult.drawables
            debugInfo = fallbackResult.debugInfo
            print("[Scene] Falling back to procedural scene: \(error)")
        }
    }
}

private struct SceneBuildResult {
    let drawables: [SceneDrawable]
    let debugInfo: SceneDebugInfo
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
        var proceduralCount = 0
        var assetCount = 0
        var grayboxCount = 0

        for element in sceneConfiguration.proceduralElements {
            if let drawable = proceduralDrawable(from: element) {
                sceneDrawables.append(drawable)
                proceduralCount += 1
            }
        }

        let includedSectorIDs = sceneConfiguration.includedSectors.isEmpty
            ? Array(sectorLookup.keys).sorted()
            : sceneConfiguration.includedSectors

        let loadedSectors = includedSectorIDs.compactMap { sectorLookup[$0] }
        for sector in loadedSectors {
            for block in sector.grayboxBlocks {
                if let drawable = grayboxDrawable(from: block, sectorID: sector.id) {
                    sceneDrawables.append(drawable)
                    grayboxCount += 1
                }
            }
        }

        for assetInstance in sceneConfiguration.assetInstances {
            if let drawable = assetDrawable(from: assetInstance) {
                sceneDrawables.append(drawable)
                assetCount += 1
            }
        }

        let detailLines = [
            "Grid: \(coordinateSystem.name)",
            "Axes: x \(coordinateSystem.axisX) / z \(coordinateSystem.axisZ)",
            "Sectors: \(loadedSectors.map(\.displayName).joined(separator: ", "))",
            "Data Root: \(URL(fileURLWithPath: worldDataRoot).lastPathComponent)",
        ]

        let summary = "\(assetCount) assets, \(grayboxCount) graybox, \(proceduralCount) procedural"

        return SceneBuildResult(
            drawables: sceneDrawables,
            debugInfo: SceneDebugInfo(
                sceneName: sceneConfiguration.sceneName,
                summary: summary,
                details: detailLines,
                spawn: sceneConfiguration.spawn
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
                modelMatrix: simd_float4x4.translation(configuration.positionVector)
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
                modelMatrix: simd_float4x4.translation(configuration.positionVector) * rotation
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
            modelMatrix: simd_float4x4.translation(configuration.positionVector) * rotation
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

        return SceneDrawable(
            name: configuration.name,
            vertexBuffer: buffer,
            vertexCount: loadedAsset.vertices.count,
            modelMatrix: simd_float4x4.translation(configuration.positionVector) * rotation * normalization
        )
    }

    private func makeBuffer(from vertices: [SceneVertex]) -> MTLBuffer? {
        device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<SceneVertex>.stride * vertices.count
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
                    modelMatrix: .identity()
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
                    position: [0, 1.65, 6],
                    yawDegrees: 0,
                    pitchDegrees: -10
                )
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
