import Foundation
import simd

private struct AuditOptions {
    let manifestPath: String
    let reportPath: String
    let blacklistMarkdownPath: String
    let blacklistJSONPath: String
    let iterations: Int
    let cellSize: Float
    let seed: UInt64

    static func parse(arguments: [String]) -> AuditOptions {
        let defaultManifestPath = "MilsimPonyGame/Assets/WorldData/\(WorldBootstrap.worldManifestRelativePath)"
        let defaultReportPath = "Docs/NPC_TRAVERSAL_AUDIT.md"
        let defaultBlacklistMarkdownPath = "Docs/NPC_TRAVERSAL_BLACKLIST.md"
        let defaultBlacklistJSONPath = "Docs/NPC_TRAVERSAL_BLACKLIST.json"
        var manifestPath = defaultManifestPath
        var reportPath = defaultReportPath
        var blacklistMarkdownPath = defaultBlacklistMarkdownPath
        var blacklistJSONPath = defaultBlacklistJSONPath
        var iterations = 256
        var cellSize: Float = 6.0
        var seed: UInt64 = 0xC4A6_B2D1_15A0_2026
        var index = 1

        while index < arguments.count {
            let argument = arguments[index]
            switch argument {
            case "--manifest":
                index += 1
                if index < arguments.count {
                    manifestPath = arguments[index]
                }
            case "--report":
                index += 1
                if index < arguments.count {
                    reportPath = arguments[index]
                }
            case "--blacklist-md":
                index += 1
                if index < arguments.count {
                    blacklistMarkdownPath = arguments[index]
                }
            case "--blacklist-json":
                index += 1
                if index < arguments.count {
                    blacklistJSONPath = arguments[index]
                }
            case "--iterations":
                index += 1
                if index < arguments.count, let value = Int(arguments[index]), value > 0 {
                    iterations = max(value, 1)
                }
            case "--cell-size":
                index += 1
                if index < arguments.count, let value = Float(arguments[index]), value > 1 {
                    cellSize = value
                }
            case "--seed":
                index += 1
                if index < arguments.count, let value = UInt64(arguments[index]) {
                    seed = value
                }
            default:
                break
            }
            index += 1
        }

        return AuditOptions(
            manifestPath: manifestPath,
            reportPath: reportPath,
            blacklistMarkdownPath: blacklistMarkdownPath,
            blacklistJSONPath: blacklistJSONPath,
            iterations: max(iterations, 1),
            cellSize: cellSize,
            seed: seed
        )
    }
}

private struct AuditAnchor {
    let id: String
    let label: String
    let category: String
    let position: SIMD3<Float>
}

private struct AuditWorldRuntime {
    let scene: SceneConfiguration
    let sectors: [SectorConfiguration]
    let sectorBounds: [GameSectorBounds]
    let collisionVolumes: [GameCollisionVolume]
    let groundSurfaces: [GameGroundSurface]
    let anchors: [AuditAnchor]
    let manifestURL: URL
}

private struct GridPoint: Hashable {
    let x: Int
    let z: Int
}

private struct PlannedPath {
    let startCell: GridPoint
    let goalCell: GridPoint
    let waypoints: [SIMD3<Float>]
    let distanceMeters: Float
}

private enum AttemptOutcome: String {
    case success
    case invalidStart = "invalid_start"
    case invalidGoal = "invalid_goal"
    case noPath = "no_path"
    case stuck
    case timeLimit = "time_limit"
}

private struct AttemptResult {
    let index: Int
    let start: AuditAnchor
    let goal: AuditAnchor
    let outcome: AttemptOutcome
    let plannedDistanceMeters: Float
    let travelledDistanceMeters: Float
    let elapsedSeconds: Double
    let waypointCount: Int
    let lastPosition: SIMD3<Float>
    let note: String

    var succeeded: Bool {
        outcome == .success
    }
}

private struct AnchorValidation {
    let anchor: AuditAnchor
    let groundHeight: Float
    let walkable: Bool
    let reason: String
}

private struct BlacklistLinkSummary {
    let start: AuditAnchor
    let goal: AuditAnchor
    let outcome: AttemptOutcome
    let occurrences: Int
    let plannedDistanceMeters: Float
    let travelledDistanceMeters: Float
    let lastPosition: SIMD3<Float>
    let note: String
}

private struct EncodableAnchorBlacklistEntry: Encodable {
    let id: String
    let label: String
    let category: String
    let x: Float
    let y: Float
    let z: Float
    let groundHeight: Float
    let reason: String
}

private struct EncodableLinkBlacklistEntry: Encodable {
    let startID: String
    let startLabel: String
    let goalID: String
    let goalLabel: String
    let outcome: String
    let occurrences: Int
    let plannedDistanceMeters: Float
    let travelledDistanceMeters: Float
    let lastX: Float
    let lastY: Float
    let lastZ: Float
    let note: String
}

private struct EncodableTraversalBlacklist: Encodable {
    let generatedAt: String
    let manifestPath: String
    let blacklistedAnchors: [EncodableAnchorBlacklistEntry]
    let blacklistedLinks: [EncodableLinkBlacklistEntry]
}

private func anchorDeduplicationKey(_ anchor: AuditAnchor) -> String {
    let roundedX = String(format: "%.3f", anchor.position.x)
    let roundedY = String(format: "%.3f", anchor.position.y)
    let roundedZ = String(format: "%.3f", anchor.position.z)
    return "\(anchor.category)|\(anchor.label)|\(roundedX)|\(roundedY)|\(roundedZ)"
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0xA5A5_A5A5_A5A5_A5A5 : seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

private struct PriorityQueue<Element> {
    private var storage: [Element] = []
    private let areInIncreasingOrder: (Element, Element) -> Bool

    init(sort: @escaping (Element, Element) -> Bool) {
        self.areInIncreasingOrder = sort
    }

    var isEmpty: Bool {
        storage.isEmpty
    }

    mutating func push(_ element: Element) {
        storage.append(element)
        siftUp(from: storage.count - 1)
    }

    mutating func pop() -> Element? {
        guard !storage.isEmpty else {
            return nil
        }

        if storage.count == 1 {
            return storage.removeLast()
        }

        let value = storage[0]
        storage[0] = storage.removeLast()
        siftDown(from: 0)
        return value
    }

    private mutating func siftUp(from index: Int) {
        var child = index
        var parent = (child - 1) / 2

        while child > 0 && areInIncreasingOrder(storage[child], storage[parent]) {
            storage.swapAt(child, parent)
            child = parent
            parent = (child - 1) / 2
        }
    }

    private mutating func siftDown(from index: Int) {
        var parent = index

        while true {
            let left = (parent * 2) + 1
            let right = left + 1
            var candidate = parent

            if left < storage.count && areInIncreasingOrder(storage[left], storage[candidate]) {
                candidate = left
            }
            if right < storage.count && areInIncreasingOrder(storage[right], storage[candidate]) {
                candidate = right
            }
            if candidate == parent {
                return
            }

            storage.swapAt(parent, candidate)
            parent = candidate
        }
    }
}

private final class AuditPlanner {
    private let minimumX: Float
    private let maximumX: Float
    private let minimumZ: Float
    private let maximumZ: Float
    private let cellSize: Float
    private let radius: Float
    private let fallbackHeight: Float
    private var walkableCache: [GridPoint: SIMD3<Float>?] = [:]

    init(bounds: (minX: Float, maxX: Float, minZ: Float, maxZ: Float), cellSize: Float, radius: Float, fallbackHeight: Float) {
        self.minimumX = bounds.minX
        self.maximumX = bounds.maxX
        self.minimumZ = bounds.minZ
        self.maximumZ = bounds.maxZ
        self.cellSize = cellSize
        self.radius = radius
        self.fallbackHeight = fallbackHeight
    }

    private func worldPosition(for cell: GridPoint) -> SIMD3<Float> {
        let x = minimumX + (Float(cell.x) * cellSize)
        let z = minimumZ + (Float(cell.z) * cellSize)
        var groundHeight: Float = fallbackHeight
        let foundGround = GameCoreSampleGroundHeightAt(x, z, fallbackHeight, &groundHeight)
        if !foundGround {
            return SIMD3<Float>(x, fallbackHeight, z)
        }
        return SIMD3<Float>(x, groundHeight, z)
    }

    private func gridPoint(for position: SIMD3<Float>) -> GridPoint {
        let rawX = Int(round((position.x - minimumX) / cellSize))
        let rawZ = Int(round((position.z - minimumZ) / cellSize))
        return GridPoint(x: rawX, z: rawZ)
    }

    private func isInsideBounds(_ cell: GridPoint) -> Bool {
        let position = worldPosition(for: cell)
        return position.x >= minimumX &&
            position.x <= maximumX &&
            position.z >= minimumZ &&
            position.z <= maximumZ
    }

    private func walkablePosition(for cell: GridPoint) -> SIMD3<Float>? {
        if let cached = walkableCache[cell] {
            return cached
        }

        guard isInsideBounds(cell) else {
            walkableCache[cell] = nil
            return nil
        }

        let candidate = worldPosition(for: cell)
        let walkable: SIMD3<Float>? = GameCoreCanOccupyPosition(candidate.x, candidate.z, candidate.y, radius)
            ? candidate
            : nil
        walkableCache[cell] = walkable
        return walkable
    }

    func nearestWalkableCell(to position: SIMD3<Float>, searchRadius: Int = 6) -> GridPoint? {
        let origin = gridPoint(for: position)

        if walkablePosition(for: origin) != nil {
            return origin
        }

        for ring in 1...searchRadius {
            for deltaX in (-ring)...ring {
                for deltaZ in (-ring)...ring {
                    if abs(deltaX) != ring && abs(deltaZ) != ring {
                        continue
                    }
                    let candidate = GridPoint(x: origin.x + deltaX, z: origin.z + deltaZ)
                    if walkablePosition(for: candidate) != nil {
                        return candidate
                    }
                }
            }
        }

        return nil
    }

    func planPath(from start: SIMD3<Float>, to goal: SIMD3<Float>) -> PlannedPath? {
        guard
            let startCell = nearestWalkableCell(to: start),
            let goalCell = nearestWalkableCell(to: goal)
        else {
            return nil
        }

        if startCell == goalCell, let waypoint = walkablePosition(for: startCell) {
            return PlannedPath(
                startCell: startCell,
                goalCell: goalCell,
                waypoints: [waypoint],
                distanceMeters: 0
            )
        }

        struct Node {
            let cell: GridPoint
            let priority: Float
        }

        var frontier = PriorityQueue<Node> { lhs, rhs in
            lhs.priority < rhs.priority
        }
        frontier.push(Node(cell: startCell, priority: 0))

        var cameFrom: [GridPoint: GridPoint] = [:]
        var costSoFar: [GridPoint: Float] = [startCell: 0]

        let neighborOffsets = [
            GridPoint(x: -1, z: 0), GridPoint(x: 1, z: 0),
            GridPoint(x: 0, z: -1), GridPoint(x: 0, z: 1),
            GridPoint(x: -1, z: -1), GridPoint(x: -1, z: 1),
            GridPoint(x: 1, z: -1), GridPoint(x: 1, z: 1),
        ]

        while let currentNode = frontier.pop() {
            if currentNode.cell == goalCell {
                break
            }

            guard let currentPosition = walkablePosition(for: currentNode.cell) else {
                continue
            }

            for offset in neighborOffsets {
                let neighbor = GridPoint(x: currentNode.cell.x + offset.x, z: currentNode.cell.z + offset.z)
                guard let neighborPosition = walkablePosition(for: neighbor) else {
                    continue
                }

                let stepCost = simd_distance(currentPosition, neighborPosition)
                let newCost = (costSoFar[currentNode.cell] ?? .infinity) + stepCost
                if newCost >= (costSoFar[neighbor] ?? .infinity) {
                    continue
                }

                costSoFar[neighbor] = newCost
                let heuristic = simd_distance(neighborPosition, worldPosition(for: goalCell))
                frontier.push(Node(cell: neighbor, priority: newCost + heuristic))
                cameFrom[neighbor] = currentNode.cell
            }
        }

        guard costSoFar[goalCell] != nil else {
            return nil
        }

        var cells: [GridPoint] = [goalCell]
        var current = goalCell
        while current != startCell {
            guard let previous = cameFrom[current] else {
                return nil
            }
            current = previous
            cells.append(current)
        }
        cells.reverse()

        let waypoints = cells.compactMap(walkablePosition(for:))
        return PlannedPath(
            startCell: startCell,
            goalCell: goalCell,
            waypoints: waypoints,
            distanceMeters: costSoFar[goalCell] ?? 0
        )
    }
}

private func loadJSON<T: Decodable>(_ type: T.Type, at url: URL) throws -> T {
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(T.self, from: data)
}

private func loadAuditWorld(manifestPath: String) throws -> AuditWorldRuntime {
    let fileManager = FileManager.default
    let repoRoot = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
    let manifestURL = URL(fileURLWithPath: manifestPath, relativeTo: repoRoot).standardizedFileURL
    let manifest = try loadJSON(WorldManifest.self, at: manifestURL)
    let packageRootURL = manifestURL.deletingLastPathComponent()
    let scene = try loadJSON(SceneConfiguration.self, at: packageRootURL.appendingPathComponent(manifest.sceneFile))

    let sectorLookup = try Dictionary(uniqueKeysWithValues: manifest.sectorFiles.map { relativePath in
        let sector = try loadJSON(SectorConfiguration.self, at: packageRootURL.appendingPathComponent(relativePath))
        return (sector.id, sector)
    })
    let loadedSectors = scene.includedSectors.isEmpty
        ? manifest.sectorFiles.compactMap { relativePath in
            let sectorID = URL(fileURLWithPath: relativePath).deletingPathExtension().lastPathComponent
            return sectorLookup[sectorID]
        }
        : scene.includedSectors.compactMap { sectorLookup[$0] }

    let sectorBounds = WorldRuntimeConversions.sectorBounds(from: loadedSectors)
    let collisionVolumes = WorldRuntimeConversions.collisionVolumes(from: loadedSectors)
    let groundSurfaces = WorldRuntimeConversions.groundSurfaces(from: loadedSectors)

    let detection = scene.detection ?? DetectionConfiguration()
    var anchors: [AuditAnchor] = []
    anchors.append(
        AuditAnchor(
            id: "spawn.primary",
            label: scene.spawn.label ?? "Primary Spawn",
            category: "Spawn",
            position: scene.spawn.positionVector
        )
    )
    for (index, spawn) in (scene.randomSpawns ?? []).enumerated() {
        anchors.append(
            AuditAnchor(
                id: "spawn.random.\(index)",
                label: spawn.label ?? "Spawn \(index + 1)",
                category: "Spawn",
                position: spawn.positionVector
            )
        )
    }
    for checkpoint in scene.route.checkpoints {
        anchors.append(
            AuditAnchor(
                id: "checkpoint.\(checkpoint.id)",
                label: checkpoint.label,
                category: "Checkpoint",
                position: checkpoint.positionVector
            )
        )
    }
    for coverPoint in (scene.guidance?.coverPoints ?? []) {
        anchors.append(
            AuditAnchor(
                id: "cover.\(coverPoint.id)",
                label: coverPoint.label,
                category: "Cover",
                position: coverPoint.positionVector
            )
        )
    }
    let deduplicatedAnchors = Dictionary(
        anchors.map { (anchorDeduplicationKey($0), $0) },
        uniquingKeysWith: { existing, _ in existing }
    )
        .values
        .sorted { lhs, rhs in
            if lhs.category == rhs.category {
                return lhs.label < rhs.label
            }
            return lhs.category < rhs.category
        }

    _ = detection
    return AuditWorldRuntime(
        scene: scene,
        sectors: loadedSectors,
        sectorBounds: sectorBounds,
        collisionVolumes: collisionVolumes,
        groundSurfaces: groundSurfaces,
        anchors: deduplicatedAnchors,
        manifestURL: manifestURL
    )
}

private func validateAnchors(_ anchors: [AuditAnchor]) -> [String: AnchorValidation] {
    var validations: [String: AnchorValidation] = [:]
    validations.reserveCapacity(anchors.count)

    for anchor in anchors {
        var groundHeight = anchor.position.y
        let grounded = GameCoreSampleGroundHeightAt(
            anchor.position.x,
            anchor.position.z,
            anchor.position.y,
            &groundHeight
        )
        let walkable = grounded && GameCoreCanOccupyPosition(
            anchor.position.x,
            anchor.position.z,
            groundHeight,
            0.36
        )
        let reason: String
        if !grounded {
            reason = "No ground surface exists at the authored anchor position"
        } else if !walkable {
            reason = "Anchor position overlaps collision or blocked occupancy"
        } else {
            reason = "walkable"
        }

        validations[anchor.id] = AnchorValidation(
            anchor: anchor,
            groundHeight: groundHeight,
            walkable: walkable,
            reason: reason
        )
    }

    return validations
}

private func buildAttemptPairs(anchors: [AuditAnchor], routeCheckpoints: [RouteCheckpointConfiguration], iterations: Int, seed: UInt64) -> [(Int, Int, String)] {
    var anchorIndexByLabel: [String: Int] = [:]
    for (index, anchor) in anchors.enumerated() {
        anchorIndexByLabel[anchor.label] = index
    }

    var pairs: [(Int, Int, String)] = []
    var seen = Set<String>()

    func appendPair(start: Int, goal: Int, source: String) {
        guard start != goal else {
            return
        }
        let key = "\(start)->\(goal)"
        guard !seen.contains(key) else {
            return
        }
        seen.insert(key)
        pairs.append((start, goal, source))
    }

    for checkpointPair in zip(routeCheckpoints, routeCheckpoints.dropFirst()) {
        guard
            let startIndex = anchorIndexByLabel[checkpointPair.0.label],
            let goalIndex = anchorIndexByLabel[checkpointPair.1.label]
        else {
            continue
        }
        appendPair(start: startIndex, goal: goalIndex, source: "route_forward")
        appendPair(start: goalIndex, goal: startIndex, source: "route_reverse")
    }

    let spawnIndices = anchors.enumerated().compactMap { index, anchor in
        anchor.category == "Spawn" ? index : nil
    }
    let checkpointIndices = anchors.enumerated().compactMap { index, anchor in
        anchor.category == "Checkpoint" ? index : nil
    }

    for spawnIndex in spawnIndices {
        guard
            let nearestCheckpoint = checkpointIndices.min(by: { lhs, rhs in
                let leftDistance = simd_distance(anchors[spawnIndex].position, anchors[lhs].position)
                let rightDistance = simd_distance(anchors[spawnIndex].position, anchors[rhs].position)
                return leftDistance < rightDistance
            })
        else {
            continue
        }
        appendPair(start: spawnIndex, goal: nearestCheckpoint, source: "spawn_to_checkpoint")
        appendPair(start: nearestCheckpoint, goal: spawnIndex, source: "checkpoint_to_spawn")
    }

    var generator = SeededGenerator(seed: seed)
    while pairs.count < iterations {
        let start = Int.random(in: 0..<anchors.count, using: &generator)
        let goal = Int.random(in: 0..<anchors.count, using: &generator)
        appendPair(start: start, goal: goal, source: "random")
    }

    return pairs
}

private func formatPosition(_ position: SIMD3<Float>) -> String {
    String(format: "(%.1f, %.1f)", position.x, position.z)
}

private func runAttempt(
    index: Int,
    start: AuditAnchor,
    goal: AuditAnchor,
    source: String,
    anchorValidations: [String: AnchorValidation],
    planner: AuditPlanner,
    walkSpeed: Float,
    sprintSpeed: Float
) -> AttemptResult {
    guard let startValidation = anchorValidations[start.id] else {
        return AttemptResult(
            index: index,
            start: start,
            goal: goal,
            outcome: .invalidStart,
            plannedDistanceMeters: 0,
            travelledDistanceMeters: 0,
            elapsedSeconds: 0,
            waypointCount: 0,
            lastPosition: start.position,
            note: "Start anchor validation is missing"
        )
    }

    guard let goalValidation = anchorValidations[goal.id] else {
        return AttemptResult(
            index: index,
            start: start,
            goal: goal,
            outcome: .invalidGoal,
            plannedDistanceMeters: 0,
            travelledDistanceMeters: 0,
            elapsedSeconds: 0,
            waypointCount: 0,
            lastPosition: start.position,
            note: "Goal anchor validation is missing"
        )
    }

    if !startValidation.walkable {
        return AttemptResult(
            index: index,
            start: start,
            goal: goal,
            outcome: .invalidStart,
            plannedDistanceMeters: 0,
            travelledDistanceMeters: 0,
            elapsedSeconds: 0,
            waypointCount: 0,
            lastPosition: start.position,
            note: startValidation.reason
        )
    }

    if !goalValidation.walkable {
        return AttemptResult(
            index: index,
            start: start,
            goal: goal,
            outcome: .invalidGoal,
            plannedDistanceMeters: 0,
            travelledDistanceMeters: 0,
            elapsedSeconds: 0,
            waypointCount: 0,
            lastPosition: start.position,
            note: goalValidation.reason
        )
    }

    guard let plannedPath = planner.planPath(from: start.position, to: goal.position) else {
        return AttemptResult(
            index: index,
            start: start,
            goal: goal,
            outcome: .noPath,
            plannedDistanceMeters: 0,
            travelledDistanceMeters: 0,
            elapsedSeconds: 0,
            waypointCount: 0,
            lastPosition: start.position,
            note: "No grid path found between anchors (\(source))"
        )
    }

    var npc = GameNPCState()
    GameCoreInitializeNPC(&npc, start.position.x, startValidation.groundHeight + 1.65, start.position.z, 0, 0)
    GameCoreConfigureNPCTraversal(&npc, walkSpeed, sprintSpeed, 0.36)
    if npc.stuck {
        return AttemptResult(
            index: index,
            start: start,
            goal: goal,
            outcome: .invalidStart,
            plannedDistanceMeters: plannedPath.distanceMeters,
            travelledDistanceMeters: 0,
            elapsedSeconds: 0,
            waypointCount: plannedPath.waypoints.count,
            lastPosition: SIMD3<Float>(npc.positionX, npc.positionY, npc.positionZ),
            note: "NPC spawn initialization failed because the start anchor is blocked"
        )
    }

    let dt = 1.0 / 30.0
    let maxDuration = max(45.0, Double(plannedPath.distanceMeters / max(walkSpeed, 0.1)) * 4.0)
    let pathWaypoints = plannedPath.waypoints + [SIMD3<Float>(goal.position.x, goalValidation.groundHeight, goal.position.z)]
    var waypointIndex = 0
    var elapsedSeconds = 0.0
    var note = source

    while waypointIndex < pathWaypoints.count && elapsedSeconds < maxDuration {
        let waypoint = pathWaypoints[waypointIndex]
        let acceptanceRadius: Float = waypointIndex == pathWaypoints.count - 1 ? 2.5 : 2.0
        GameCoreSetNPCTarget(&npc, waypoint.x, waypoint.y, waypoint.z, acceptanceRadius, false)

        while npc.hasTarget && !npc.targetReached && !npc.stuck && elapsedSeconds < maxDuration {
            GameCoreTickNPC(&npc, dt)
            elapsedSeconds += dt
        }

        if npc.stuck {
            note = "NPC stuck while approaching waypoint \(waypointIndex + 1) / \(pathWaypoints.count)"
            return AttemptResult(
                index: index,
                start: start,
                goal: goal,
                outcome: .stuck,
                plannedDistanceMeters: plannedPath.distanceMeters,
                travelledDistanceMeters: npc.travelledDistanceMeters,
                elapsedSeconds: elapsedSeconds,
                waypointCount: pathWaypoints.count,
                lastPosition: SIMD3<Float>(npc.positionX, npc.positionY, npc.positionZ),
                note: note
            )
        }

        waypointIndex += 1
    }

    if waypointIndex < pathWaypoints.count {
        return AttemptResult(
            index: index,
            start: start,
            goal: goal,
            outcome: .timeLimit,
            plannedDistanceMeters: plannedPath.distanceMeters,
            travelledDistanceMeters: npc.travelledDistanceMeters,
            elapsedSeconds: elapsedSeconds,
            waypointCount: pathWaypoints.count,
            lastPosition: SIMD3<Float>(npc.positionX, npc.positionY, npc.positionZ),
            note: "Exceeded \(Int(maxDuration))s without reaching the final goal"
        )
    }

    return AttemptResult(
        index: index,
        start: start,
        goal: goal,
        outcome: .success,
        plannedDistanceMeters: plannedPath.distanceMeters,
        travelledDistanceMeters: npc.travelledDistanceMeters,
        elapsedSeconds: elapsedSeconds,
        waypointCount: pathWaypoints.count,
        lastPosition: SIMD3<Float>(npc.positionX, npc.positionY, npc.positionZ),
        note: source
    )
}

private func buildBlacklistLinkSummaries(from results: [AttemptResult]) -> [BlacklistLinkSummary] {
    let grouped = Dictionary(grouping: results.filter {
        $0.outcome == .stuck || $0.outcome == .noPath || $0.outcome == .timeLimit
    }, by: { "\($0.start.id)->\($0.goal.id)->\($0.outcome.rawValue)" })

    return grouped.values.compactMap { attempts in
        guard let sample = attempts.first else {
            return nil
        }

        return BlacklistLinkSummary(
            start: sample.start,
            goal: sample.goal,
            outcome: sample.outcome,
            occurrences: attempts.count,
            plannedDistanceMeters: sample.plannedDistanceMeters,
            travelledDistanceMeters: sample.travelledDistanceMeters,
            lastPosition: sample.lastPosition,
            note: sample.note
        )
    }.sorted { lhs, rhs in
        if lhs.occurrences == rhs.occurrences {
            if lhs.start.label == rhs.start.label {
                return lhs.goal.label < rhs.goal.label
            }
            return lhs.start.label < rhs.start.label
        }
        return lhs.occurrences > rhs.occurrences
    }
}

private func writeBlacklist(
    anchorValidations: [AnchorValidation],
    blacklistedLinks: [BlacklistLinkSummary],
    manifestURL: URL,
    markdownURL: URL,
    jsonURL: URL
) throws {
    let timestamp = ISO8601DateFormatter().string(from: Date())
    let blacklistedAnchors = anchorValidations
        .filter { !$0.walkable }
        .sorted { lhs, rhs in
            if lhs.anchor.category == rhs.anchor.category {
                return lhs.anchor.label < rhs.anchor.label
            }
            return lhs.anchor.category < rhs.anchor.category
        }

    var markdown = ""
    markdown += "# NPC Traversal Blacklist\n\n"
    markdown += "Generated on \(timestamp) from `\(manifestURL.path)`.\n\n"
    markdown += "Every entry in this file is a bug to check and fix. None of these anchors or links are treated as expected traversal failures.\n\n"
    markdown += "## Anchor Blacklist\n\n"
    markdown += "| Anchor | Category | Position | Ground Height | Bug | Reason |\n"
    markdown += "| --- | --- | --- | ---: | --- | --- |\n"
    if blacklistedAnchors.isEmpty {
        markdown += "| None | - | - | 0.0 | clear | No authored actor anchors are currently blacklisted |\n"
    } else {
        for validation in blacklistedAnchors {
            markdown += "| \(validation.anchor.label) | \(validation.anchor.category) | \(formatPosition(validation.anchor.position)) | \(String(format: "%.1f", validation.groundHeight)) | unwalkable_anchor | \(validation.reason) |\n"
        }
    }
    markdown += "\n"
    markdown += "## Link Blacklist\n\n"
    markdown += "| Start | Goal | Bug | Occurrences | Planned m | Travelled m | Last Position | Reason |\n"
    markdown += "| --- | --- | --- | ---: | ---: | ---: | --- | --- |\n"
    if blacklistedLinks.isEmpty {
        markdown += "| None | None | clear | 0 | 0.0 | 0.0 | (0.0, 0.0) | No traversal links are currently blacklisted |\n"
    } else {
        for link in blacklistedLinks {
            markdown += "| \(link.start.label) | \(link.goal.label) | \(link.outcome.rawValue) | \(link.occurrences) | \(String(format: "%.1f", link.plannedDistanceMeters)) | \(String(format: "%.1f", link.travelledDistanceMeters)) | \(formatPosition(link.lastPosition)) | \(link.note) |\n"
        }
    }
    markdown += "\n"
    markdown += "## Use\n\n"
    markdown += "- Treat every `unwalkable_anchor`, `stuck`, `no_path`, or `time_limit` entry here as a world-data or traversal bug.\n"
    markdown += "- Remove entries only by fixing the authored space or the NPC traversal logic and rerunning the audit.\n"

    try markdown.write(to: markdownURL, atomically: true, encoding: .utf8)

    let jsonDocument = EncodableTraversalBlacklist(
        generatedAt: timestamp,
        manifestPath: manifestURL.path,
        blacklistedAnchors: blacklistedAnchors.map { validation in
            EncodableAnchorBlacklistEntry(
                id: validation.anchor.id,
                label: validation.anchor.label,
                category: validation.anchor.category,
                x: validation.anchor.position.x,
                y: validation.anchor.position.y,
                z: validation.anchor.position.z,
                groundHeight: validation.groundHeight,
                reason: validation.reason
            )
        },
        blacklistedLinks: blacklistedLinks.map { link in
            EncodableLinkBlacklistEntry(
                startID: link.start.id,
                startLabel: link.start.label,
                goalID: link.goal.id,
                goalLabel: link.goal.label,
                outcome: link.outcome.rawValue,
                occurrences: link.occurrences,
                plannedDistanceMeters: link.plannedDistanceMeters,
                travelledDistanceMeters: link.travelledDistanceMeters,
                lastX: link.lastPosition.x,
                lastY: link.lastPosition.y,
                lastZ: link.lastPosition.z,
                note: link.note
            )
        }
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(jsonDocument)
    try data.write(to: jsonURL)
}

private func writeReport(
    results: [AttemptResult],
    anchorValidations: [AnchorValidation],
    blacklistedLinks: [BlacklistLinkSummary],
    options: AuditOptions,
    world: AuditWorldRuntime,
    reportURL: URL,
    blacklistMarkdownURL: URL,
    blacklistJSONURL: URL
) throws {
    let totalAttempts = results.count
    let successfulAttempts = results.filter(\.succeeded)
    let failingAttempts = results.filter { !$0.succeeded }
    let blacklistedAnchorCount = anchorValidations.filter { !$0.walkable }.count

    let outcomeCounts = Dictionary(grouping: results, by: \.outcome).mapValues(\.count)
    let averagePlannedDistance = successfulAttempts.isEmpty
        ? 0
        : successfulAttempts.reduce(0) { $0 + $1.plannedDistanceMeters } / Float(successfulAttempts.count)
    let averageElapsedSeconds = successfulAttempts.isEmpty
        ? 0
        : successfulAttempts.reduce(0.0) { $0 + $1.elapsedSeconds } / Double(successfulAttempts.count)

    let hotspotCounts = Dictionary(grouping: failingAttempts, by: { "\($0.start.label) -> \($0.goal.label)" })
        .map { key, attempts in
            (key, attempts.count, attempts.first?.outcome.rawValue ?? "unknown")
        }
        .sorted { lhs, rhs in
            if lhs.1 == rhs.1 {
                return lhs.0 < rhs.0
            }
            return lhs.1 > rhs.1
        }

    var markdown = ""
    markdown += "# NPC Traversal Audit\n\n"
    markdown += "Generated on \(ISO8601DateFormatter().string(from: Date())) from `\(world.manifestURL.path)`.\n\n"
    markdown += "This audit drives reusable `GameNPCState` movement through the Canberra world package and records where the agent cannot start, cannot plan a path, gets stuck, or times out.\n\n"
    markdown += "Anchor set: authored spawns, route checkpoints, and cover points that should all be valid actor locations.\n\n"
    markdown += "Generated bug blacklists:\n"
    markdown += "- Markdown: `\(blacklistMarkdownURL.path)`\n"
    markdown += "- JSON: `\(blacklistJSONURL.path)`\n\n"
    markdown += "Every blacklist entry is a bug to check and fix. None of these failures are treated as acceptable behavior.\n\n"
    markdown += "## Summary\n\n"
    markdown += "| Metric | Value |\n"
    markdown += "| --- | --- |\n"
    markdown += "| Iterations requested | \(options.iterations) |\n"
    markdown += "| Iterations executed | \(totalAttempts) |\n"
    markdown += "| Anchors audited | \(world.anchors.count) |\n"
    markdown += "| Blacklisted anchors | \(blacklistedAnchorCount) |\n"
    markdown += "| Blacklisted links | \(blacklistedLinks.count) |\n"
    markdown += "| Successful traversals | \(successfulAttempts.count) |\n"
    markdown += "| Failed traversals | \(failingAttempts.count) |\n"
    markdown += "| `invalid_start` | \(outcomeCounts[.invalidStart, default: 0]) |\n"
    markdown += "| `invalid_goal` | \(outcomeCounts[.invalidGoal, default: 0]) |\n"
    markdown += "| `no_path` | \(outcomeCounts[.noPath, default: 0]) |\n"
    markdown += "| `stuck` | \(outcomeCounts[.stuck, default: 0]) |\n"
    markdown += "| `time_limit` | \(outcomeCounts[.timeLimit, default: 0]) |\n"
    markdown += "| Average successful planned distance | \(String(format: "%.1f m", averagePlannedDistance)) |\n"
    markdown += "| Average successful elapsed time | \(String(format: "%.1f s", averageElapsedSeconds)) |\n\n"

    markdown += "## Frequent Failures\n\n"
    markdown += "| Path | Failures | Dominant Outcome |\n"
    markdown += "| --- | ---: | --- |\n"
    if hotspotCounts.isEmpty {
        markdown += "| None | 0 | success-only audit |\n"
    } else {
        for hotspot in hotspotCounts.prefix(20) {
            markdown += "| \(hotspot.0) | \(hotspot.1) | \(hotspot.2) |\n"
        }
    }
    markdown += "\n"

    markdown += "## Failure Table\n\n"
    markdown += "| # | Start | Goal | Outcome | Planned m | Travelled m | Last Position | Note |\n"
    markdown += "| ---: | --- | --- | --- | ---: | ---: | --- | --- |\n"
    if failingAttempts.isEmpty {
        markdown += "| 0 | None | None | success-only audit | 0.0 | 0.0 | (0.0, 0.0) | All traversals reached their goals |\n"
    } else {
        for result in failingAttempts {
            markdown += "| \(result.index) | \(result.start.label) | \(result.goal.label) | \(result.outcome.rawValue) | \(String(format: "%.1f", result.plannedDistanceMeters)) | \(String(format: "%.1f", result.travelledDistanceMeters)) | \(formatPosition(result.lastPosition)) | \(result.note) |\n"
        }
    }
    markdown += "\n"

    markdown += "## Notes\n\n"
    markdown += "- The audit used a `\(String(format: "%.1f", options.cellSize))m` planning grid with the same ground and collision queries that the live `GameCore` world uses.\n"
    markdown += "- Successful paths only confirm that an NPC can follow the planned route under the current collision and ground setup.\n"
    markdown += "- Every blacklist entry is a real bug candidate to fix in world data, authored anchor placement, or NPC traversal logic. The audit no longer treats these failures as expected.\n"
    markdown += "- The agent movement runs in `GameNPCState` so the audit exercises reusable NPC traversal logic instead of a test-only teleport script.\n"

    try markdown.write(to: reportURL, atomically: true, encoding: .utf8)
}

private func runAudit() throws {
    let options = AuditOptions.parse(arguments: CommandLine.arguments)
    let fileManager = FileManager.default
    let repoRoot = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
    let reportURL = URL(fileURLWithPath: options.reportPath, relativeTo: repoRoot).standardizedFileURL
    let blacklistMarkdownURL = URL(fileURLWithPath: options.blacklistMarkdownPath, relativeTo: repoRoot).standardizedFileURL
    let blacklistJSONURL = URL(fileURLWithPath: options.blacklistJSONPath, relativeTo: repoRoot).standardizedFileURL
    let world = try loadAuditWorld(manifestPath: options.manifestPath)

    GameCoreBootstrap("npc-traversal-audit")
    world.sectorBounds.withUnsafeBufferPointer { sectorBounds in
        world.collisionVolumes.withUnsafeBufferPointer { collisionVolumes in
            world.groundSurfaces.withUnsafeBufferPointer { groundSurfaces in
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

    let routeCheckpoints = world.scene.route.checkpoints
    let bounds = (
        minX: world.sectors.map { $0.bounds.minimum.x }.min() ?? -200,
        maxX: world.sectors.map { $0.bounds.maximum.x }.max() ?? 200,
        minZ: world.sectors.map { $0.bounds.minimum.z }.min() ?? -200,
        maxZ: world.sectors.map { $0.bounds.maximum.z }.max() ?? 200
    )
    let planner = AuditPlanner(
        bounds: bounds,
        cellSize: options.cellSize,
        radius: 0.36,
        fallbackHeight: world.scene.spawn.positionVector.y
    )
    let pairs = buildAttemptPairs(
        anchors: world.anchors,
        routeCheckpoints: routeCheckpoints,
        iterations: options.iterations,
        seed: options.seed
    )

    let walkSpeed = max(world.scene.player?.walkSpeed ?? 4.2, 1.0)
    let sprintSpeed = max(world.scene.player?.sprintSpeed ?? 6.8, walkSpeed + 0.6)
    let anchorValidationMap = validateAnchors(world.anchors)
    var results: [AttemptResult] = []
    results.reserveCapacity(pairs.count)

    for (attemptIndex, pair) in pairs.enumerated() {
        let result = runAttempt(
            index: attemptIndex + 1,
            start: world.anchors[pair.0],
            goal: world.anchors[pair.1],
            source: pair.2,
            anchorValidations: anchorValidationMap,
            planner: planner,
            walkSpeed: walkSpeed,
            sprintSpeed: sprintSpeed
        )
        results.append(result)
        print("[NPC Audit] \(attemptIndex + 1)/\(pairs.count) \(result.start.label) -> \(result.goal.label): \(result.outcome.rawValue)")
    }

    let blacklistLinks = buildBlacklistLinkSummaries(from: results)
    let anchorValidations = world.anchors.compactMap { anchorValidationMap[$0.id] }

    try writeBlacklist(
        anchorValidations: anchorValidations,
        blacklistedLinks: blacklistLinks,
        manifestURL: world.manifestURL,
        markdownURL: blacklistMarkdownURL,
        jsonURL: blacklistJSONURL
    )
    try writeReport(
        results: results,
        anchorValidations: anchorValidations,
        blacklistedLinks: blacklistLinks,
        options: options,
        world: world,
        reportURL: reportURL,
        blacklistMarkdownURL: blacklistMarkdownURL,
        blacklistJSONURL: blacklistJSONURL
    )

    let successCount = results.filter(\.succeeded).count
    print("[NPC Audit] Wrote \(reportURL.path)")
    print("[NPC Audit] Wrote \(blacklistMarkdownURL.path)")
    print("[NPC Audit] Wrote \(blacklistJSONURL.path)")
    print("[NPC Audit] Success \(successCount) / \(results.count), Failures \(results.count - successCount)")
}

@main
private struct NPCAuditTool {
    static func main() {
        do {
            try runAudit()
        } catch {
            fputs("[NPC Audit] \(error)\n", stderr)
            exit(1)
        }
    }
}
