import AppKit
import Combine
import Foundation
import simd

enum DemoFlowState: String {
    case title
    case playing
    case paused
    case failed
    case complete

    var label: String {
        switch self {
        case .title:
            return "briefing"
        case .playing:
            return "live"
        case .paused:
            return "paused"
        case .failed:
            return "compromised"
        case .complete:
            return "complete"
        }
    }
}

enum GameMenuPanel {
    case title
    case paused
    case failed
    case complete
    case settings
}

private struct StoredSessionSettings {
    let hudOpacity: Double
    let invertLookY: Bool
    let lookSensitivityScale: Double
}

struct OverheadMapSnapshot {
    let configuration: SceneMapConfiguration
    let playerX: Float
    let playerZ: Float
    let headingX: Float
    let headingZ: Float
    let currentSectorName: String
    let completedCheckpointCount: Int
    let totalCheckpointCount: Int
    let nextCheckpointLabel: String?
    let nextComparisonStop: SceneMapComparisonStop?
    let nextCombatStop: SceneMapCombatStop?
    let suspicionLevel: Float
    let activeObserverCount: Int
    let seeingObserverCount: Int
    let failCount: Int
}

final class GameSession: ObservableObject {
    @Published private(set) var statusLine = "Bootstrapping game session"
    @Published private(set) var overlayLines: [String] = []
    @Published private(set) var overlayTitle = "Cycle 21 Combat-Lane Rehearsal"
    @Published private(set) var demoFlowState: DemoFlowState = .title
    @Published private(set) var isSettingsPresented = false
    @Published private(set) var isScopeActive = false
    @Published private(set) var isMapPresented = false
    @Published private(set) var hudOpacity: Double
    @Published private(set) var invertLookY: Bool
    @Published private(set) var lookSensitivityScale: Double
    @Published private(set) var inputFocusRequestID = 0

    private let configuration: LaunchConfiguration
    private var pressedCommands: Set<InputCommand> = []
    private var lastMouseDelta: CGSize = .zero
    private var shouldIgnoreNextMouseDelta = true
    private var latestSnapshot: GameFrameSnapshot?
    private var viewportSize: CGSize = .zero
    private var rendererName = "Waiting for Metal"
    private var sceneLabel = WorldBootstrap.sceneLabel
    private var sceneSummary = "Preparing scene"
    private var sceneDetails: [String] = []
    private var briefingSummary = "Briefing: building route readout"
    private var briefingDetails: [String] = []
    private var routeSummary = "Route: waiting for route state"
    private var routeDetails: [String] = []
    private var evasionSummary = "Evasion: waiting for detection state"
    private var evasionDetails: [String] = []
    private var streamingSummary = "Chunks: waiting for stream state"
    private var streamingDetails: [String] = []
    private var frameTimingLine = "Frame: collecting samples"
    private var completedCheckpointCount = 0
    private var routeWasComplete = false
    private var routeWasFailed = false
    private var sceneReady = false
    private var baseWalkSpeed: Float?
    private var baseSprintSpeed: Float?
    private var baseLookSensitivity: Float?
    private var scopeLabel = "4x Scope"
    private var scopeMagnification: Float = 4.0
    private var scopeFieldOfViewDegrees: Float = 15.0
    private var scopeLookSensitivityMultiplier: Float = 0.26
    private var scopeDrawDistanceMultiplier: Float = 2.4
    private var scopeFarPlaneMultiplierValue: Float = 1.35
    private var scopeReticleColorComponents = SIMD4<Float>(0.92, 0.86, 0.42, 0.94)
    private var mapConfiguration: SceneMapConfiguration?
    private var cachedOverheadMapSnapshot: OverheadMapSnapshot?
    private var freshRunHandler: (() -> Void)?
    private var pendingOverlayLines: [String]?
    private var isOverlayPublishScheduled = false

    init(configuration: LaunchConfiguration) {
        let storedSettings = Self.loadStoredSettings()
        self.configuration = configuration
        self.hudOpacity = storedSettings.hudOpacity
        self.invertLookY = storedSettings.invertLookY
        self.lookSensitivityScale = storedSettings.lookSensitivityScale

        configuration.bootMode.withCString { bootMode in
            GameCoreBootstrap(bootMode)
        }

        print("[App] Booting \(configuration.worldName) in \(configuration.bootMode) mode")
        rebuildOverlay()
    }

    var assetRootPath: String {
        configuration.assetRoot
    }

    var worldDataRootPath: String {
        configuration.worldDataRoot
    }

    var worldManifestPath: String {
        configuration.worldManifestPath
    }

    var menuPanel: GameMenuPanel? {
        if isSettingsPresented {
            return .settings
        }

        switch demoFlowState {
        case .playing:
            return nil
        case .title:
            return .title
        case .paused:
            return .paused
        case .failed:
            return .failed
        case .complete:
            return .complete
        }
    }

    var shouldAdvanceSimulation: Bool {
        sceneReady && menuPanel == nil
    }

    var hudCardOpacity: Double {
        switch menuPanel {
        case .title?, .settings?:
            return max(hudOpacity * 0.55, 0.22)
        default:
            return isScopeActive ? max(hudOpacity * 0.62, 0.20) : hudOpacity
        }
    }

    var inputCardSubtitle: String {
        let cycleLabel = overlayTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return menuPanel == nil
            ? "\(cycleLabel) traversal, scoped observation, map lookup, and landmark validation controls"
            : "Deploy, pause, map, retry, and tune field settings"
    }

    var canBeginMission: Bool {
        sceneReady
    }

    var activeCommands: Set<InputCommand> {
        pressedCommands
    }

    var canShowMap: Bool {
        mapConfiguration != nil
    }

    var scopeStatusText: String {
        if isScopeActive {
            return String(format: "%.1fx scope active / %.1f deg FOV", scopeMagnification, scopeFieldOfViewDegrees)
        }

        return String(format: "%.1fx scope ready / press Space", scopeMagnification)
    }

    var scopeInstructionText: String {
        isScopeActive ? "Press Space to lower scope" : "Raise scope on the contact and skyline markers"
    }

    var scopeReticleColor: NSColor {
        NSColor(
            calibratedRed: CGFloat(scopeReticleColorComponents.x),
            green: CGFloat(scopeReticleColorComponents.y),
            blue: CGFloat(scopeReticleColorComponents.z),
            alpha: CGFloat(scopeReticleColorComponents.w)
        )
    }

    var scopeFieldOfViewYRadians: Float {
        max(scopeFieldOfViewDegrees, 4.0) * (.pi / 180.0)
    }

    var scopeFarPlaneMultiplier: Float {
        max(scopeFarPlaneMultiplierValue, 1.0)
    }

    var overheadMapSnapshot: OverheadMapSnapshot? {
        cachedOverheadMapSnapshot
    }

    private var currentMapSectorName: String {
        cachedOverheadMapSnapshot?.currentSectorName ?? "waiting for Canberra layout"
    }

    private func refreshOverheadMapSnapshot() {
        guard let mapConfiguration else {
            cachedOverheadMapSnapshot = nil
            return
        }

        let snapshot = latestSnapshot
        let playerX = snapshot?.cameraX ?? mapConfiguration.spawnPoint.x
        let playerZ = snapshot?.cameraZ ?? mapConfiguration.spawnPoint.z
        let yawDegrees = snapshot?.yawDegrees ?? mapConfiguration.spawnYawDegrees
        let yawRadians = yawDegrees * (.pi / 180.0)
        let completedCheckpointCount = min(
            Int(snapshot?.completedCheckpointCount ?? 0),
            mapConfiguration.checkpoints.count
        )
        let nextCheckpointLabel = completedCheckpointCount < mapConfiguration.checkpoints.count
            ? mapConfiguration.checkpoints[completedCheckpointCount].label
            : nil
        let nextComparisonStop = completedCheckpointCount < mapConfiguration.checkpoints.count
            ? mapConfiguration.comparisonStops.first { comparisonStop in
                comparisonStop.checkpointID == mapConfiguration.checkpoints[completedCheckpointCount].id
            }
            : nil
        let nextCombatStop = completedCheckpointCount < mapConfiguration.checkpoints.count
            ? mapConfiguration.contactStops.first { contactStop in
                contactStop.checkpointID == mapConfiguration.checkpoints[completedCheckpointCount].id
            }
            : nil
        let currentSectorName = preferredSectorName(
            for: mapConfiguration.sectors,
            playerX: playerX,
            playerZ: playerZ
        )

        cachedOverheadMapSnapshot = OverheadMapSnapshot(
            configuration: mapConfiguration,
            playerX: playerX,
            playerZ: playerZ,
            headingX: sinf(yawRadians),
            headingZ: -cosf(yawRadians),
            currentSectorName: currentSectorName,
            completedCheckpointCount: completedCheckpointCount,
            totalCheckpointCount: mapConfiguration.checkpoints.count,
            nextCheckpointLabel: nextCheckpointLabel,
            nextComparisonStop: nextComparisonStop,
            nextCombatStop: nextCombatStop,
            suspicionLevel: snapshot?.suspicionLevel ?? 0,
            activeObserverCount: Int(snapshot?.activeObserverCount ?? 0),
            seeingObserverCount: Int(snapshot?.seeingObserverCount ?? 0),
            failCount: Int(snapshot?.failCount ?? 0)
        )
    }

    func menuTitle(for panel: GameMenuPanel) -> String {
        switch panel {
        case .title:
            return sceneReady ? sceneLabel : WorldBootstrap.sceneLabel
        case .paused:
            return "Demo Paused"
        case .failed:
            return "Compromised"
        case .complete:
            return "Rehearsal Complete"
        case .settings:
            return "Field Settings"
        }
    }

    func menuSubtitle(for panel: GameMenuPanel) -> String {
        switch panel {
        case .title:
            return sceneReady ? overlayTitle : "Loading Canberra combat rehearsal"
        case .paused:
            return routeSummary
        case .failed:
            return "Observer pressure forced a checkpoint fallback"
        case .complete:
            return routeSummary
        case .settings:
            return "Controls, Canberra locator, and overlay tuning"
        }
    }

    func menuLines(for panel: GameMenuPanel) -> [String] {
        switch panel {
        case .title:
            return titlePanelLines()
        case .paused:
            return pausedPanelLines()
        case .failed:
            return failedPanelLines()
        case .complete:
            return completePanelLines()
        case .settings:
            return settingsPanelLines()
        }
    }

    func noteRendererReady(deviceName: String) {
        rendererName = deviceName
        statusLine = "Metal ready on \(deviceName)"
        rebuildOverlay()
    }

    func noteRendererUnavailable() {
        rendererName = "No compatible Metal device"
        statusLine = "Metal initialization failed"
        rebuildOverlay()
    }

    func noteViewActivation() {
        shouldIgnoreNextMouseDelta = true
        statusLine = sceneReady && demoFlowState == .title
            ? "Demo briefing ready"
            : "Input focus captured"
        print("[Input] MTKView accepted first responder")
        rebuildOverlay()
    }

    func noteSceneReady(label: String, summary: String, details: [String]) {
        sceneLabel = label
        sceneSummary = summary
        sceneDetails = details
        sceneReady = true
        statusLine = "Demo briefing ready"
        rebuildOverlay()
    }

    func noteOverlayTitle(_ title: String) {
        overlayTitle = title
        rebuildOverlay()
    }

    func noteSceneBootstrap(
        label: String,
        summary: String,
        details: [String],
        overlayTitle: String,
        scopeConfiguration: ScopeConfiguration,
        mapConfiguration: SceneMapConfiguration
    ) {
        sceneLabel = label
        sceneSummary = summary
        sceneDetails = details
        sceneReady = true
        statusLine = "Demo briefing ready"
        self.overlayTitle = overlayTitle
        scopeLabel = scopeConfiguration.label ?? "4x Scope"
        scopeMagnification = max(scopeConfiguration.magnification, 1.0)
        scopeFieldOfViewDegrees = max(scopeConfiguration.fieldOfViewDegrees, 4.0)
        scopeLookSensitivityMultiplier = max(scopeConfiguration.lookSensitivityMultiplier ?? 0.26, 0.08)
        scopeDrawDistanceMultiplier = max(scopeConfiguration.drawDistanceMultiplier ?? 2.4, 1.0)
        scopeFarPlaneMultiplierValue = max(scopeConfiguration.farPlaneMultiplier ?? 1.35, 1.0)
        scopeReticleColorComponents = scopeConfiguration.reticleColorVector
        self.mapConfiguration = mapConfiguration
        refreshOverheadMapSnapshot()
        rebuildOverlay()
    }

    func noteScopeConfiguration(_ configuration: ScopeConfiguration) {
        scopeLabel = configuration.label ?? "4x Scope"
        scopeMagnification = max(configuration.magnification, 1.0)
        scopeFieldOfViewDegrees = max(configuration.fieldOfViewDegrees, 4.0)
        scopeLookSensitivityMultiplier = max(configuration.lookSensitivityMultiplier ?? 0.26, 0.08)
        scopeDrawDistanceMultiplier = max(configuration.drawDistanceMultiplier ?? 2.4, 1.0)
        scopeFarPlaneMultiplierValue = max(configuration.farPlaneMultiplier ?? 1.35, 1.0)
        scopeReticleColorComponents = configuration.reticleColorVector
        rebuildOverlay()
    }

    func noteMapConfiguration(_ configuration: SceneMapConfiguration) {
        mapConfiguration = configuration
        refreshOverheadMapSnapshot()
        rebuildOverlay()
    }

    func setFreshRunHandler(_ handler: @escaping () -> Void) {
        freshRunHandler = handler
    }

    func noteFrameTiming(milliseconds: Double, framesPerSecond: Double, drawableCount: Int) {
        updateFrameTimingLine(
            milliseconds: milliseconds,
            framesPerSecond: framesPerSecond,
            drawableCount: drawableCount
        )
        rebuildOverlay()
    }

    func noteStreamingState(summary: String, details: [String]) {
        streamingSummary = summary
        streamingDetails = details
        rebuildOverlay()
    }

    func noteRouteState(summary: String, details: [String]) {
        routeSummary = summary
        routeDetails = details
        rebuildOverlay()
    }

    func noteBriefingState(summary: String, details: [String]) {
        briefingSummary = summary
        briefingDetails = details
        rebuildOverlay()
    }

    func noteEvasionState(summary: String, details: [String]) {
        evasionSummary = summary
        evasionDetails = details
        rebuildOverlay()
    }

    func startDemo() {
        guard sceneReady else {
            statusLine = "Scene data still loading"
            rebuildOverlay()
            return
        }

        isSettingsPresented = false
        demoFlowState = .playing
        resetMissionRuntime()
        statusLine = "Demo live - move through the current Canberra contact rehearsal"
        requestInputFocusIfNeeded()
        rebuildOverlay()
    }

    func resumeDemo() {
        guard sceneReady else {
            return
        }

        isSettingsPresented = false
        demoFlowState = .playing
        clearGameplayInputState()
        statusLine = "Demo resumed"
        requestInputFocusIfNeeded()
        rebuildOverlay()
    }

    func retryFromCheckpoint() {
        guard sceneReady else {
            return
        }

        if latestSnapshot?.routeFailed ?? false {
            GameCoreClearFailure()
        }
        GameCoreRestartRoute()
        isSettingsPresented = false
        demoFlowState = .playing
        clearGameplayInputState()
        refreshSnapshotFromCore()
        statusLine = "Retry from latest checkpoint"
        requestInputFocusIfNeeded()
        rebuildOverlay()
    }

    func restartMission() {
        guard sceneReady else {
            return
        }

        freshRunHandler?()
        isSettingsPresented = false
        demoFlowState = .playing
        resetMissionRuntime()
        statusLine = "Demo restarted from a fresh rehearsal start"
        requestInputFocusIfNeeded()
        rebuildOverlay()
    }

    func returnToBriefing() {
        guard sceneReady else {
            return
        }

        freshRunHandler?()
        isSettingsPresented = false
        demoFlowState = .title
        resetMissionRuntime()
        statusLine = "Demo briefing ready"
        rebuildOverlay()
    }

    func openSettings() {
        guard sceneReady else {
            return
        }

        isSettingsPresented = true
        clearGameplayInputState()
        statusLine = "Settings open"
        rebuildOverlay()
    }

    func closeSettings() {
        isSettingsPresented = false
        statusLine = statusLineForCurrentFlowState()
        requestInputFocusIfNeeded()
        rebuildOverlay()
    }

    func setHUDOpacity(_ value: Double) {
        hudOpacity = max(min(value, 1.0), 0.35)
        persistSettings()
        rebuildOverlay()
    }

    func setInvertLookY(_ value: Bool) {
        invertLookY = value
        persistSettings()
        rebuildOverlay()
    }

    func setLookSensitivityScale(_ value: Double) {
        lookSensitivityScale = max(min(value, 1.8), 0.6)
        persistSettings()
        applyLookSettings()
        rebuildOverlay()
    }

    func setMapPresented(_ value: Bool) {
        guard mapConfiguration != nil else {
            isMapPresented = false
            if value {
                statusLine = sceneReady
                    ? "Canberra map unavailable in this scene"
                    : "Canberra map unlocks when Canberra finishes loading"
                rebuildOverlay()
            }
            return
        }

        guard isMapPresented != value else {
            return
        }

        isMapPresented = value
        statusLine = value ? "Canberra map opened" : statusLineForCurrentFlowState()
        if !value {
            requestInputFocusIfNeeded()
        }
        rebuildOverlay()
    }

    func handleKey(_ keyCode: UInt16, characters: String?, isPressed: Bool, isRepeat: Bool) {
        guard let command = InputBindings.command(for: keyCode, characters: characters) else {
            return
        }

        if isPressed, isRepeat, !command.isContinuous {
            return
        }

        if isPressed {
            switch command {
            case .pause:
                handlePauseToggle()
                print("[Input] \(command.label) pressed")
                rebuildOverlay()
                return
            case .toggleMap:
                setMapPresented(!isMapPresented)
                print("[Input] \(command.label) pressed")
                rebuildOverlay()
                return
            case .interact where handleMenuPrimaryAction():
                print("[Input] \(command.label) pressed")
                rebuildOverlay()
                return
            case .interact where toggleScopeIfPossible():
                print("[Input] \(command.label) pressed")
                rebuildOverlay()
                return
            case .restart where handleMenuRestartAction():
                print("[Input] \(command.label) pressed")
                rebuildOverlay()
                return
            default:
                break
            }
        }

        guard menuPanel == nil else {
            return
        }

        let changed: Bool
        if isPressed {
            changed = pressedCommands.insert(command).inserted
        } else {
            changed = pressedCommands.remove(command) != nil
        }

        guard changed else {
            return
        }

        switch command {
        case .restart where isPressed:
            if latestSnapshot?.routeFailed ?? false {
                GameCoreClearFailure()
            }
            GameCoreRestartRoute()
            lastMouseDelta = .zero
            shouldIgnoreNextMouseDelta = true
            refreshSnapshotFromCore()
            statusLine = (latestSnapshot?.routeFailed ?? false)
                ? "Retry triggered from checkpoint"
                : "Route restart triggered"
        default:
            statusLine = "\(command.label) \(isPressed ? "pressed" : "released")"
        }

        print("[Input] \(command.label) \(isPressed ? "pressed" : "released")")
        synchronizeMovementIntent()
        rebuildOverlay()
    }

    func handleMouseDelta(x: CGFloat, y: CGFloat) {
        guard menuPanel == nil else {
            return
        }

        guard x != 0 || y != 0 else {
            return
        }

        if shouldIgnoreNextMouseDelta {
            shouldIgnoreNextMouseDelta = false
            lastMouseDelta = .zero
            rebuildOverlay()
            return
        }

        let adjustedY = invertLookY ? -y : y
        lastMouseDelta = CGSize(width: x, height: adjustedY)
        GameCoreAddLookDelta(Float(x), Float(adjustedY))
    }

    func updateViewport(size: CGSize) {
        viewportSize = size
        rebuildOverlay()
    }

    func accept(snapshot: GameFrameSnapshot, drawableSize: CGSize) {
        captureBaseTraversalIfNeeded(from: snapshot)

        if demoFlowState == .playing {
            if snapshot.routeFailed && !routeWasFailed {
                demoFlowState = .failed
                clearGameplayInputState()
                statusLine = "Compromised - choose retry or restart"
            } else if snapshot.routeComplete && !routeWasComplete {
                demoFlowState = .complete
                clearGameplayInputState()
                statusLine = "Survey route complete"
            } else if Int(snapshot.completedCheckpointCount) > completedCheckpointCount {
                statusLine = "Checkpoint \(snapshot.completedCheckpointCount) reached"
            }
        }

        completedCheckpointCount = Int(snapshot.completedCheckpointCount)
        routeWasComplete = snapshot.routeComplete
        routeWasFailed = snapshot.routeFailed
        latestSnapshot = snapshot
        viewportSize = drawableSize
        refreshOverheadMapSnapshot()
        rebuildOverlay()
    }

    func applyRendererUpdate(
        snapshot: GameFrameSnapshot,
        drawableSize: CGSize,
        briefing: (summary: String, details: [String]),
        route: (summary: String, details: [String]),
        evasion: (summary: String, details: [String]),
        streaming: (summary: String, details: [String]),
        frameTiming: (milliseconds: Double, framesPerSecond: Double, drawableCount: Int)?
    ) {
        captureBaseTraversalIfNeeded(from: snapshot)

        if demoFlowState == .playing {
            if snapshot.routeFailed && !routeWasFailed {
                demoFlowState = .failed
                clearGameplayInputState()
                statusLine = "Compromised - choose retry or restart"
            } else if snapshot.routeComplete && !routeWasComplete {
                demoFlowState = .complete
                clearGameplayInputState()
                statusLine = "Survey route complete"
            } else if Int(snapshot.completedCheckpointCount) > completedCheckpointCount {
                statusLine = "Checkpoint \(snapshot.completedCheckpointCount) reached"
            }
        }

        completedCheckpointCount = Int(snapshot.completedCheckpointCount)
        routeWasComplete = snapshot.routeComplete
        routeWasFailed = snapshot.routeFailed
        latestSnapshot = snapshot
        viewportSize = drawableSize
        briefingSummary = briefing.summary
        briefingDetails = briefing.details
        routeSummary = route.summary
        routeDetails = route.details
        evasionSummary = evasion.summary
        evasionDetails = evasion.details
        streamingSummary = streaming.summary
        streamingDetails = streaming.details

        if let frameTiming {
            updateFrameTimingLine(
                milliseconds: frameTiming.milliseconds,
                framesPerSecond: frameTiming.framesPerSecond,
                drawableCount: frameTiming.drawableCount
            )
        }

        refreshOverheadMapSnapshot()
        rebuildOverlay()
    }

    func applyRendererFrameTimingUpdate(milliseconds: Double, framesPerSecond: Double, drawableCount: Int) {
        updateFrameTimingLine(
            milliseconds: milliseconds,
            framesPerSecond: framesPerSecond,
            drawableCount: drawableCount
        )
        rebuildOverlay()
    }

    func resetDebugState() {
        GameCoreResetDebugState()
        clearGameplayInputState()
        demoFlowState = .title
        isSettingsPresented = false
        refreshSnapshotFromCore()
        statusLine = "Demo briefing ready"
        rebuildOverlay()
    }

    private func handlePauseToggle() {
        if isSettingsPresented {
            closeSettings()
            return
        }

        guard sceneReady else {
            return
        }

        switch demoFlowState {
        case .playing:
            demoFlowState = .paused
            clearGameplayInputState()
            statusLine = "Demo paused"
        case .paused:
            resumeDemo()
        case .title, .failed, .complete:
            break
        }
    }

    private func handleMenuPrimaryAction() -> Bool {
        guard let panel = menuPanel else {
            return false
        }

        switch panel {
        case .title:
            startDemo()
        case .paused:
            resumeDemo()
        case .failed:
            retryFromCheckpoint()
        case .complete:
            restartMission()
        case .settings:
            closeSettings()
        }

        return true
    }

    private func handleMenuRestartAction() -> Bool {
        guard let panel = menuPanel else {
            return false
        }

        switch panel {
        case .title:
            startDemo()
        case .paused, .failed, .complete:
            restartMission()
        case .settings:
            return false
        }

        return true
    }

    private func resetMissionRuntime() {
        GameCoreResetDebugState()
        clearGameplayInputState()
        refreshSnapshotFromCore()
    }

    private func clearGameplayInputState() {
        pressedCommands.removeAll()
        isScopeActive = false
        lastMouseDelta = .zero
        shouldIgnoreNextMouseDelta = true
        GameCoreSetMoveIntent(0, 0)
        GameCoreSetSprint(false)
        applyLookSettings()
    }

    private func refreshSnapshotFromCore() {
        let snapshot = GameCoreGetSnapshot()
        captureBaseTraversalIfNeeded(from: snapshot)
        latestSnapshot = snapshot
        completedCheckpointCount = Int(snapshot.completedCheckpointCount)
        routeWasComplete = snapshot.routeComplete
        routeWasFailed = snapshot.routeFailed
        refreshOverheadMapSnapshot()
    }

    private func updateFrameTimingLine(milliseconds: Double, framesPerSecond: Double, drawableCount: Int) {
        frameTimingLine = String(
            format: "Frame: %.2f ms / %.1f fps / %d drawables",
            milliseconds,
            framesPerSecond,
            drawableCount
        )
    }

    private func captureBaseTraversalIfNeeded(from snapshot: GameFrameSnapshot) {
        guard baseWalkSpeed == nil || baseSprintSpeed == nil || baseLookSensitivity == nil else {
            return
        }

        baseWalkSpeed = snapshot.walkSpeed
        baseSprintSpeed = snapshot.sprintSpeed
        baseLookSensitivity = snapshot.lookSensitivity

        if abs(lookSensitivityScale - 1.0) > 0.001 {
            applyLookSettings()
        }
    }

    private func applyLookSettings() {
        guard
            let walkSpeed = baseWalkSpeed,
            let sprintSpeed = baseSprintSpeed,
            let baseLookSensitivity = baseLookSensitivity
        else {
            return
        }

        GameCoreConfigureTraversal(
            walkSpeed,
            sprintSpeed,
            baseLookSensitivity * Float(lookSensitivityScale) * (isScopeActive ? scopeLookSensitivityMultiplier : 1.0)
        )
        refreshSnapshotFromCore()
    }

    private func toggleScopeIfPossible() -> Bool {
        guard sceneReady, demoFlowState == .playing, menuPanel == nil else {
            return false
        }

        isScopeActive.toggle()
        applyLookSettings()
        statusLine = isScopeActive
            ? String(format: "%.1fx scope active", scopeMagnification)
            : String(format: "%.1fx scope lowered", scopeMagnification)
        return true
    }

    private func synchronizeMovementIntent() {
        let strafe = axisValue(negative: .strafeLeft, positive: .strafeRight)
        let forward = axisValue(negative: .backward, positive: .forward)

        GameCoreSetMoveIntent(strafe, forward)
        GameCoreSetSprint(pressedCommands.contains(.sprint))
    }

    private func axisValue(negative: InputCommand, positive: InputCommand) -> Float {
        var value: Float = 0
        if pressedCommands.contains(negative) {
            value -= 1
        }
        if pressedCommands.contains(positive) {
            value += 1
        }
        return value
    }

    private func titlePanelLines() -> [String] {
        let riskLine: String
        if evasionSummary == "Evasion: unavailable" {
            riskLine = "Threats: no live opposition in this preview; focus on Canberra scale, streaming, and sightlines."
        } else {
            riskLine = "Threats: active observers can still trigger a checkpoint fallback if the route enters an exposed lane."
        }
        let objectiveLine: String
        if let routeObjective = routeDetails.first, routeObjective.hasPrefix("Objective:") {
            objectiveLine = routeObjective
        } else {
            objectiveLine = "Objective: rehearse the current Canberra contact lanes and move through the authored markers from the assigned start."
        }

        var lines = [
            objectiveLine,
            String(format: "Priority: keep the authored districts readable at %.1fx while validating skyline layering, streaming handoff, and route continuity.", scopeMagnification),
            riskLine,
            "Release: \(configuration.releaseDisplayName) / \(configuration.bundleIdentifier)",
            "Content: \(configuration.contentSourceSummary)",
            String(format: "Optic: %.1fx scope ready for live contact and skyline markers.", scopeMagnification),
            "Locator: press M at any time to raise the Canberra map.",
            "Deploy: press Space or Return, then use Esc at any time for the pause shell.",
        ]

        let planningLines = sceneDetails.filter { detail in
            detail.hasPrefix("Plan:")
                || detail.hasPrefix("Breakdown:")
                || detail.hasPrefix("Reference:")
        }
        lines.append(contentsOf: planningLines.prefix(3))
        let reviewLines = sceneDetails.filter { detail in
            detail.hasPrefix("Review Pack:")
                || detail.hasPrefix("Reference Pack:")
                || detail.hasPrefix("Capture Framing:")
                || detail.hasPrefix("Texture Audit:")
        }
        lines.append(contentsOf: reviewLines.prefix(3))
        let combatLines = sceneDetails.filter { detail in
            detail.hasPrefix("Combat Rehearsal:")
                || detail.hasPrefix("Exposure Guide:")
                || detail.hasPrefix("Recovery Rule:")
        }
        lines.append(contentsOf: combatLines.prefix(2))

        if sceneReady {
            lines.append("Route: \(routeSummary)")
            lines.append(briefingDetails.first ?? routeSummary)
            if let contactLine = routeDetails.first(where: { $0.hasPrefix("Contact:") || $0.hasPrefix("Compare:") || $0.hasPrefix("Capture:") }) {
                lines.append(contactLine)
            } else if briefingDetails.count > 1 {
                lines.append(briefingDetails[1])
            }
            lines.append("Slice: \(sceneSummary)")
        } else {
            lines.append("Slice: waiting for Canberra data and renderer state")
        }

        return lines
    }

    private func pausedPanelLines() -> [String] {
        let contactLine = routeDetails.first(where: { $0.hasPrefix("Contact:") })
        let coverLine = routeDetails.first(where: { $0.hasPrefix("Cover:") })
        let compareLine = routeDetails.first(where: { $0.hasPrefix("Compare:") })
        let captureLine = routeDetails.first(where: { $0.hasPrefix("Capture:") })
        return [
            briefingSummary,
            routeSummary,
            contactLine ?? compareLine ?? routeDetails.first(where: { $0.hasPrefix("Next:") }) ?? "Next: continue through the current rehearsal markers.",
            coverLine ?? captureLine ?? sceneDetails.first(where: { $0.hasPrefix("Recovery Rule:") || $0.hasPrefix("Capture Framing:") }) ?? "Capture: keep the next district marker and atlas cues in frame.",
            evasionDetails.first ?? "Threats: preview pressure and world updates are frozen while paused.",
            String(format: "Scope: %.1fx optic %@.", scopeMagnification, isScopeActive ? "was active before the pause shell" : "can be raised again when live"),
            "Resume keeps the current rehearsal live. Restart rolls a fresh rehearsal start.",
        ]
    }

    private func failedPanelLines() -> [String] {
        let snapshot = latestSnapshot
        let contactLine = routeDetails.first(where: { $0.hasPrefix("Contact:") })
        let coverLine = routeDetails.first(where: { $0.hasPrefix("Cover:") })
        return [
            String(
                format: "Threats: %.2f suspicion / %d failures / %d observers seeing",
                snapshot?.suspicionLevel ?? 0,
                snapshot?.failCount ?? 0,
                snapshot?.seeingObserverCount ?? 0
            ),
            routeSummary,
            contactLine ?? routeDetails.first(where: { $0.hasPrefix("Next:") }) ?? "Next: the latest checkpoint remains available for retry.",
            coverLine ?? sceneDetails.first(where: { $0.hasPrefix("Recovery Rule:") }) ?? "Recovery: use cover, then re-enter the rehearsal lane from the last checkpoint.",
            "Retry restarts from the most recent checkpoint. Restart rolls a fresh rehearsal start.",
            "Return to Briefing resets the run and leaves the demo at the title shell.",
        ]
    }

    private func completePanelLines() -> [String] {
        let snapshot = latestSnapshot
        return [
            routeSummary,
            String(
                format: "Run: %.1fs / %.0fm / %d restarts",
                snapshot?.elapsedSeconds ?? 0,
                snapshot?.routeDistanceMeters ?? 0,
                snapshot?.restartCount ?? 0
            ),
            sceneDetails.first(where: { $0.hasPrefix("Review Pack:") }) ?? "Review Pack: final review pack data unavailable.",
            sceneDetails.first(where: { $0.hasPrefix("Combat Rehearsal:") }) ?? "Combat Rehearsal: final rehearsal data unavailable.",
            "Outcome: the current Canberra line now reads as one contact rehearsal with live observer pressure and explicit recovery cues across the full route.",
            "Release: \(configuration.releaseDisplayName) / \(configuration.contentSourceSummary)",
            String(format: "Optic: %.1fx scoped review remained available across the full route.", scopeMagnification),
            "Script: title shell, live contact route, optional fail or retry loop, and completion summary all resolve in one session.",
            "New Run restarts the rehearsal immediately from a fresh contact-lane start. Briefing returns to the title shell.",
        ]
    }

    private func settingsPanelLines() -> [String] {
        [
            String(format: "Look scale: %.2fx of the authored cycle tuning", lookSensitivityScale),
            "Invert Y: \(invertLookY ? "enabled" : "disabled")",
            String(format: "Scope: %.1fx / %.1f deg / x%.1f draw", scopeMagnification, scopeFieldOfViewDegrees, scopeDrawDistanceMultiplier),
            "Map: \(isMapPresented ? "open" : "hidden") / \(currentMapSectorName)",
            String(format: "HUD opacity: %.0f%%", hudOpacity * 100),
            "Build: \(configuration.releaseDisplayName)",
            "Bundle: \(configuration.bundleIdentifier)",
            "Content: \(configuration.contentSourceSummary)",
            "These settings persist between launches.",
        ]
    }

    private func statusLineForCurrentFlowState() -> String {
        switch demoFlowState {
        case .title:
            return "Demo briefing ready"
        case .playing:
            return isScopeActive
                ? String(format: "%.1fx scope active - inspect distant landmarks", scopeMagnification)
                : "Demo live - move through the current Canberra contact rehearsal"
        case .paused:
            return "Demo paused"
        case .failed:
            return "Compromised - choose retry or restart"
        case .complete:
            return "Combat rehearsal complete"
        }
    }

    private func rebuildOverlay() {
        let snapshot = latestSnapshot
        let pressed = pressedCommands
            .map(\.label)
            .sorted()
            .joined(separator: ", ")
        let headerLines = [
            "Mode: \(configuration.bootMode)",
            "Demo: \(demoFlowState.label)\(isSettingsPresented ? " / settings" : "")",
            "Release: \(configuration.releaseDisplayName)",
            "Bundle: \(configuration.bundleIdentifier)",
            "Content: \(configuration.contentSourceSummary)",
            "Scene: \(sceneLabel)",
            "World: \(configuration.worldName)",
            "Assets: \(shortenedPath(configuration.assetRoot))",
            "World Data: \(shortenedPath(configuration.worldDataRoot))",
            "Manifest: \(shortenedPath(configuration.worldManifestPath))",
            "Locator: \(isMapPresented ? "Canberra map open" : "Canberra map hidden") / \(currentMapSectorName)",
            "Renderer: \(rendererName)",
            "Scene Summary: \(sceneSummary)",
            String(
                format: "Scope: %@ / %.1fx / %.1f deg / x%.1f draw",
                isScopeActive ? "active" : "ready",
                scopeMagnification,
                scopeFieldOfViewDegrees,
                scopeDrawDistanceMultiplier
            ),
            briefingSummary,
            routeSummary,
            evasionSummary,
            streamingSummary,
        ]
        let metricLines = [
            "Viewport: \(Int(viewportSize.width)) x \(Int(viewportSize.height))",
            frameTimingLine,
            "Pressed: \(pressed.isEmpty ? "None" : pressed)",
            String(format: "Intent: strafe %.1f forward %.1f sprint %@", snapshot?.strafeIntent ?? 0, snapshot?.forwardIntent ?? 0, (snapshot?.sprinting ?? false) ? "on" : "off"),
            String(
                format: "Move Speed: %.2f m/s (walk %.2f / sprint %.2f / look %.3f)",
                snapshot?.moveSpeed ?? 0,
                snapshot?.walkSpeed ?? 0,
                snapshot?.sprintSpeed ?? 0,
                snapshot?.lookSensitivity ?? 0
            ),
            String(format: "Optic: %@ / %.1fx", isScopeActive ? "raised" : "lowered", scopeMagnification),
            String(format: "Settings: look x%.2f / %@ / HUD %.0f%%", lookSensitivityScale, invertLookY ? "invert Y" : "standard Y", hudOpacity * 100),
            String(format: "Ground: %.2f m / %@ / %d active sectors", snapshot?.groundHeight ?? 0, (snapshot?.grounded ?? false) ? "grounded" : "fallback", snapshot?.activeSectorCount ?? 0),
            String(
                format: "Route Metrics: %d / %d checkpoints / %.0fm / %d restarts",
                snapshot?.completedCheckpointCount ?? 0,
                snapshot?.totalCheckpointCount ?? 0,
                snapshot?.routeDistanceMeters ?? 0,
                snapshot?.restartCount ?? 0
            ),
            String(format: "Threat: %.2f / %d watching / %d in range / %d fails", snapshot?.suspicionLevel ?? 0, snapshot?.seeingObserverCount ?? 0, snapshot?.activeObserverCount ?? 0, snapshot?.failCount ?? 0),
            String(format: "Look: yaw %.1f pitch %.1f", snapshot?.yawDegrees ?? 0, snapshot?.pitchDegrees ?? 0),
            String(format: "Camera: %.2f %.2f %.2f", snapshot?.cameraX ?? 0, snapshot?.cameraY ?? 0, snapshot?.cameraZ ?? 0),
            String(format: "Mouse Delta: %.1f %.1f", lastMouseDelta.width, lastMouseDelta.height),
            String(format: "Uptime: %.2fs", snapshot?.elapsedSeconds ?? 0),
        ]

        publishOverlayLines(
            headerLines + sceneDetails + briefingDetails + routeDetails + evasionDetails + streamingDetails + metricLines
        )
    }

    private func publishOverlayLines(_ newOverlayLines: [String]) {
        pendingOverlayLines = newOverlayLines

        guard !isOverlayPublishScheduled else {
            return
        }

        isOverlayPublishScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }

            self.isOverlayPublishScheduled = false
            guard let pendingOverlayLines = self.pendingOverlayLines else {
                return
            }

            self.pendingOverlayLines = nil
            if self.overlayLines != pendingOverlayLines {
                self.overlayLines = pendingOverlayLines
            }
        }
    }

    private func requestInputFocusIfNeeded() {
        guard menuPanel == nil else {
            return
        }

        inputFocusRequestID &+= 1
    }

    private func persistSettings() {
        let defaults = UserDefaults.standard
        defaults.set(hudOpacity, forKey: Self.hudOpacityDefaultsKey)
        defaults.set(invertLookY, forKey: Self.invertLookYDefaultsKey)
        defaults.set(lookSensitivityScale, forKey: Self.lookSensitivityScaleDefaultsKey)
    }

    private func shortenedPath(_ path: String) -> String {
        let components = URL(fileURLWithPath: path).pathComponents.filter { $0 != "/" }
        guard components.count > 3 else {
            return path
        }

        return components.suffix(3).joined(separator: "/")
    }

    private func preferredSectorName(
        for sectors: [SceneMapSector],
        playerX: Float,
        playerZ: Float
    ) -> String {
        let containingSectors = sectors.filter { sector in
            sector.contains(x: playerX, z: playerZ)
        }

        guard let sector = containingSectors.sorted(by: { lhs, rhs in
            let leftPriority = residencyPriority(lhs.residency)
            let rightPriority = residencyPriority(rhs.residency)
            if leftPriority != rightPriority {
                return leftPriority < rightPriority
            }
            if lhs.area != rhs.area {
                return lhs.area < rhs.area
            }
            return lhs.displayName < rhs.displayName
        }).first else {
            return "Outside basin bounds"
        }

        return sector.displayName
    }

    private func residencyPriority(_ residency: SectorResidency) -> Int {
        switch residency {
        case .local:
            return 0
        case .farField:
            return 1
        case .always:
            return 2
        }
    }

    private static func loadStoredSettings() -> StoredSessionSettings {
        let defaults = UserDefaults.standard
        let hudOpacity = defaults.object(forKey: hudOpacityDefaultsKey) as? Double ?? 0.88
        let invertLookY = defaults.object(forKey: invertLookYDefaultsKey) as? Bool ?? false
        let lookSensitivityScale = defaults.object(forKey: lookSensitivityScaleDefaultsKey) as? Double ?? 1.0

        return StoredSessionSettings(
            hudOpacity: max(min(hudOpacity, 1.0), 0.35),
            invertLookY: invertLookY,
            lookSensitivityScale: max(min(lookSensitivityScale, 1.8), 0.6)
        )
    }

    private static let hudOpacityDefaultsKey = "milsimPony.hudOpacity"
    private static let invertLookYDefaultsKey = "milsimPony.invertLookY"
    private static let lookSensitivityScaleDefaultsKey = "milsimPony.lookSensitivityScale"
}
