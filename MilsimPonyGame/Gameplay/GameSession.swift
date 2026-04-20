import AppKit
import Combine
import Foundation

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

final class GameSession: ObservableObject {
    @Published private(set) var statusLine = "Bootstrapping game session"
    @Published private(set) var overlayLines: [String] = []
    @Published private(set) var overlayTitle = "Canberra Bootstrap Slice"
    @Published private(set) var demoFlowState: DemoFlowState = .title
    @Published private(set) var isSettingsPresented = false
    @Published private(set) var hudOpacity: Double
    @Published private(set) var invertLookY: Bool
    @Published private(set) var lookSensitivityScale: Double

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
            return hudOpacity
        }
    }

    var inputCardSubtitle: String {
        let cycleLabel = overlayTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return menuPanel == nil
            ? "\(cycleLabel) traversal, stability hardening, and routed escape controls"
            : "Deploy, pause, retry, and tune persistent field settings"
    }

    var canBeginMission: Bool {
        sceneReady
    }

    func menuTitle(for panel: GameMenuPanel) -> String {
        switch panel {
        case .title:
            return "Operation Southbound"
        case .paused:
            return "Mission Paused"
        case .failed:
            return "Compromised"
        case .complete:
            return "Escape Confirmed"
        case .settings:
            return "Field Settings"
        }
    }

    func menuSubtitle(for panel: GameMenuPanel) -> String {
        switch panel {
        case .title:
            return sceneReady ? sceneLabel : "Loading Canberra slice"
        case .paused:
            return routeSummary
        case .failed:
            return "Observer pressure forced a checkpoint fallback"
        case .complete:
            return "The Deakin corridor is clear end to end"
        case .settings:
            return "Persistent controls and overlay tuning"
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
            ? "Mission briefing ready"
            : "Input focus captured"
        print("[Input] MTKView accepted first responder")
        rebuildOverlay()
    }

    func noteSceneReady(label: String, summary: String, details: [String]) {
        sceneLabel = label
        sceneSummary = summary
        sceneDetails = details
        sceneReady = true
        statusLine = "Mission briefing ready"
        rebuildOverlay()
    }

    func noteOverlayTitle(_ title: String) {
        overlayTitle = title
        rebuildOverlay()
    }

    func noteFrameTiming(milliseconds: Double, framesPerSecond: Double, drawableCount: Int) {
        frameTimingLine = String(
            format: "Frame: %.2f ms / %.1f fps / %d drawables",
            milliseconds,
            framesPerSecond,
            drawableCount
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
        statusLine = "Mission live - push south to the Deakin exit"
        rebuildOverlay()
    }

    func resumeDemo() {
        guard sceneReady else {
            return
        }

        isSettingsPresented = false
        demoFlowState = .playing
        clearGameplayInputState()
        statusLine = "Mission resumed"
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
        rebuildOverlay()
    }

    func restartMission() {
        guard sceneReady else {
            return
        }

        isSettingsPresented = false
        demoFlowState = .playing
        resetMissionRuntime()
        statusLine = "Mission restarted from State Circle South Verge"
        rebuildOverlay()
    }

    func returnToBriefing() {
        guard sceneReady else {
            return
        }

        isSettingsPresented = false
        demoFlowState = .title
        resetMissionRuntime()
        statusLine = "Mission briefing ready"
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

    func handleKey(_ keyCode: UInt16, isPressed: Bool) {
        guard let command = InputBindings.command(for: keyCode) else {
            return
        }

        if isPressed {
            switch command {
            case .pause:
                handlePauseToggle()
                print("[Input] \(command.label) pressed")
                rebuildOverlay()
                return
            case .interact where handleMenuPrimaryAction():
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
        case .interact where isPressed:
            statusLine = "Interact placeholder triggered"
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
                statusLine = "Escape corridor reached"
            } else if Int(snapshot.completedCheckpointCount) > completedCheckpointCount {
                statusLine = "Checkpoint \(snapshot.completedCheckpointCount) reached"
            }
        }

        completedCheckpointCount = Int(snapshot.completedCheckpointCount)
        routeWasComplete = snapshot.routeComplete
        routeWasFailed = snapshot.routeFailed
        latestSnapshot = snapshot
        viewportSize = drawableSize
        rebuildOverlay()
    }

    func resetDebugState() {
        GameCoreResetDebugState()
        clearGameplayInputState()
        demoFlowState = .title
        isSettingsPresented = false
        refreshSnapshotFromCore()
        statusLine = "Mission briefing ready"
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
            statusLine = "Mission paused"
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
        lastMouseDelta = .zero
        shouldIgnoreNextMouseDelta = true
        GameCoreSetMoveIntent(0, 0)
        GameCoreSetSprint(false)
    }

    private func refreshSnapshotFromCore() {
        let snapshot = GameCoreGetSnapshot()
        captureBaseTraversalIfNeeded(from: snapshot)
        latestSnapshot = snapshot
        completedCheckpointCount = Int(snapshot.completedCheckpointCount)
        routeWasComplete = snapshot.routeComplete
        routeWasFailed = snapshot.routeFailed
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
            baseLookSensitivity * Float(lookSensitivityScale)
        )
        refreshSnapshotFromCore()
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
        var lines = [
            "Mission: leave the Parliament precinct and clear the Deakin South Escape route.",
            "Script: State Circle Cutthrough, Cross Street Junction, Deakin Service Lane, then Extraction Canopy.",
            "Risk: crossing open observer lanes forces a checkpoint fallback instead of a clean run.",
            "Release: \(configuration.releaseDisplayName) / \(configuration.bundleIdentifier)",
            "Content: \(configuration.contentSourceSummary)",
            "Deploy: press Space or Return, then use Esc at any time for the pause shell.",
        ]

        if sceneReady {
            lines.append(briefingSummary)
            lines.append(briefingDetails.first ?? routeSummary)
            if briefingDetails.count > 1 {
                lines.append(briefingDetails[1])
            }
            lines.append("Slice: \(sceneSummary)")
        } else {
            lines.append("Slice: waiting for Canberra data and renderer state")
        }

        return lines
    }

    private func pausedPanelLines() -> [String] {
        [
            briefingSummary,
            routeDetails.first ?? "Route: continue south through the current checkpoint leg.",
            evasionDetails.first ?? "Threats: observer pressure is frozen while paused.",
            "Resume keeps the current run live. Restart returns to State Circle South Verge.",
        ]
    }

    private func failedPanelLines() -> [String] {
        let snapshot = latestSnapshot
        return [
            String(
                format: "Threats: %.2f suspicion / %d failures / %d observers seeing",
                snapshot?.suspicionLevel ?? 0,
                snapshot?.failCount ?? 0,
                snapshot?.seeingObserverCount ?? 0
            ),
            routeDetails.first ?? "Route: the latest checkpoint remains available for retry.",
            "Retry restarts from the most recent checkpoint. Restart begins from the initial spawn.",
            "Return to Briefing resets the run and leaves the demo at the title shell.",
        ]
    }

    private func completePanelLines() -> [String] {
        let snapshot = latestSnapshot
        return [
            String(
                format: "Run: %.1fs / %.0fm / %d restarts",
                snapshot?.elapsedSeconds ?? 0,
                snapshot?.routeDistanceMeters ?? 0,
                snapshot?.restartCount ?? 0
            ),
            "Outcome: the playable Canberra slice now runs from briefing to extraction without developer prompts.",
            "Release: \(configuration.releaseDisplayName) / \(configuration.contentSourceSummary)",
            "Script: title shell, live route, fail or retry loop, and extraction summary all resolve in one session.",
            "New Run restarts the mission immediately. Briefing returns to the title shell.",
        ]
    }

    private func settingsPanelLines() -> [String] {
        [
            String(format: "Look scale: %.2fx of the authored cycle tuning", lookSensitivityScale),
            "Invert Y: \(invertLookY ? "enabled" : "disabled")",
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
            return "Mission briefing ready"
        case .playing:
            return "Mission live - push south to the Deakin exit"
        case .paused:
            return "Mission paused"
        case .failed:
            return "Compromised - choose retry or restart"
        case .complete:
            return "Escape corridor reached"
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
            "Renderer: \(rendererName)",
            "Scene Summary: \(sceneSummary)",
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
            String(format: "Settings: look x%.2f / %@ / HUD %.0f%%", lookSensitivityScale, invertLookY ? "invert Y" : "standard Y", hudOpacity * 100),
            String(format: "Ground: %.2f m / %@ / %d active sectors", snapshot?.groundHeight ?? 0, (snapshot?.grounded ?? false) ? "grounded" : "fallback", snapshot?.activeSectorCount ?? 0),
            String(format: "Route Metrics: %.0fm / %d restarts", snapshot?.routeDistanceMeters ?? 0, snapshot?.restartCount ?? 0),
            String(format: "Threat: %.2f / %d watching / %d in range / %d fails", snapshot?.suspicionLevel ?? 0, snapshot?.seeingObserverCount ?? 0, snapshot?.activeObserverCount ?? 0, snapshot?.failCount ?? 0),
            String(format: "Look: yaw %.1f pitch %.1f", snapshot?.yawDegrees ?? 0, snapshot?.pitchDegrees ?? 0),
            String(format: "Camera: %.2f %.2f %.2f", snapshot?.cameraX ?? 0, snapshot?.cameraY ?? 0, snapshot?.cameraZ ?? 0),
            String(format: "Mouse Delta: %.1f %.1f", lastMouseDelta.width, lastMouseDelta.height),
            String(format: "Uptime: %.2fs", snapshot?.elapsedSeconds ?? 0),
        ]

        overlayLines = headerLines + sceneDetails + briefingDetails + routeDetails + evasionDetails + streamingDetails + metricLines
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
