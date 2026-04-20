import AppKit
import Combine
import Foundation

final class GameSession: ObservableObject {
    @Published private(set) var statusLine = "Bootstrapping game session"
    @Published private(set) var overlayLines: [String] = []

    private let configuration: LaunchConfiguration
    private var pressedCommands: Set<InputCommand> = []
    private var lastMouseDelta: CGSize = .zero
    private var latestSnapshot: GameFrameSnapshot?
    private var viewportSize: CGSize = .zero
    private var rendererName = "Waiting for Metal"
    private var sceneSummary = "Preparing scene"

    init(configuration: LaunchConfiguration) {
        self.configuration = configuration

        configuration.bootMode.withCString { bootMode in
            GameCoreBootstrap(bootMode)
        }

        print("[App] Booting \(configuration.worldName) in \(configuration.bootMode) mode")
        rebuildOverlay()
    }

    var assetRootPath: String {
        configuration.assetRoot
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
        statusLine = "Input focus captured"
        print("[Input] MTKView accepted first responder")
        rebuildOverlay()
    }

    func noteSceneReady(summary: String) {
        sceneSummary = summary
        statusLine = "Scene ready"
        rebuildOverlay()
    }

    func handleKey(_ keyCode: UInt16, isPressed: Bool) {
        guard let command = InputBindings.command(for: keyCode) else {
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
        case .interact where isPressed:
            statusLine = "Interact placeholder triggered"
        case .pause where isPressed:
            statusLine = "Pause placeholder triggered"
        default:
            statusLine = "\(command.label) \(isPressed ? "pressed" : "released")"
        }

        print("[Input] \(command.label) \(isPressed ? "pressed" : "released")")
        synchronizeMovementIntent()
        rebuildOverlay()
    }

    func handleMouseDelta(x: CGFloat, y: CGFloat) {
        guard x != 0 || y != 0 else {
            return
        }

        lastMouseDelta = CGSize(width: x, height: y)
        GameCoreAddLookDelta(Float(x), Float(y))
    }

    func updateViewport(size: CGSize) {
        viewportSize = size
        rebuildOverlay()
    }

    func accept(snapshot: GameFrameSnapshot, drawableSize: CGSize) {
        latestSnapshot = snapshot
        viewportSize = drawableSize
        rebuildOverlay()
    }

    func resetDebugState() {
        GameCoreResetDebugState()
        lastMouseDelta = .zero
        statusLine = "Debug state reset"
        rebuildOverlay()
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

    private func rebuildOverlay() {
        let snapshot = latestSnapshot
        let pressed = pressedCommands
            .map(\.label)
            .sorted()
            .joined(separator: ", ")

        overlayLines = [
            "Mode: \(configuration.bootMode)",
            "Scene: \(WorldBootstrap.sceneLabel)",
            "World: \(configuration.worldName)",
            "Assets: \(configuration.assetRoot)",
            "Renderer: \(rendererName)",
            "Scene Assets: \(sceneSummary)",
            "Viewport: \(Int(viewportSize.width)) x \(Int(viewportSize.height))",
            "Pressed: \(pressed.isEmpty ? "None" : pressed)",
            String(format: "Intent: strafe %.1f forward %.1f sprint %@", snapshot?.strafeIntent ?? 0, snapshot?.forwardIntent ?? 0, (snapshot?.sprinting ?? false) ? "on" : "off"),
            String(format: "Move Speed: %.2f m/s", snapshot?.moveSpeed ?? 0),
            String(format: "Look: yaw %.1f pitch %.1f", snapshot?.yawDegrees ?? 0, snapshot?.pitchDegrees ?? 0),
            String(format: "Camera: %.2f %.2f %.2f", snapshot?.cameraX ?? 0, snapshot?.cameraY ?? 0, snapshot?.cameraZ ?? 0),
            String(format: "Mouse Delta: %.1f %.1f", lastMouseDelta.width, lastMouseDelta.height),
            String(format: "Uptime: %.2fs", snapshot?.elapsedSeconds ?? 0),
        ]
    }
}
