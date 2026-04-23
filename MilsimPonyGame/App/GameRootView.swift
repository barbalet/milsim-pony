import SwiftUI
import simd

enum AuxiliaryWindowID: String {
    case overlay = "mission-overlay"
    case controls = "control-deck"
    case menu = "menu-shell"
    case map = "canberra-map"
}

struct GameRootView: View {
    @ObservedObject var session: GameSession

    var body: some View {
        ZStack(alignment: .topLeading) {
            MetalGameView(session: session)
                .background(Color.black)
                .ignoresSafeArea()

            Color.black
                .opacity(session.menuPanel == .title ? 0.14 : 0)
                .ignoresSafeArea()

            if session.isScopeActive && session.menuPanel == nil {
                scopeOverlay
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .zIndex(1)
            }

            AuxiliaryWindowBridge(session: session)
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
        }
        .frame(minWidth: 960, minHeight: 600)
        .background(Color.black)
    }

    private var scopeOverlay: some View {
        ScopeOverlay(
            statusText: session.scopeStatusText,
            instructionText: session.scopeInstructionText,
            reticleColor: Color(nsColor: session.scopeReticleColor)
        )
    }
}

private struct AuxiliaryWindowBridge: View {
    @ObservedObject var session: GameSession
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var didOpenPersistentWindows = false

    var body: some View {
        Color.clear
            .onAppear {
                guard !didOpenPersistentWindows else {
                    return
                }

                didOpenPersistentWindows = true
                openWindow(id: AuxiliaryWindowID.overlay.rawValue)
                openWindow(id: AuxiliaryWindowID.controls.rawValue)
                syncMenuWindow()
                syncMapWindow()
            }
            .onChange(of: session.isMapPresented) { _, _ in
                syncMapWindow()
            }
            .onChange(of: session.menuPanel != nil) { _, _ in
                syncMenuWindow()
            }
    }

    private func syncMenuWindow() {
        if session.menuPanel != nil {
            openWindow(id: AuxiliaryWindowID.menu.rawValue)
        } else {
            dismissWindow(id: AuxiliaryWindowID.menu.rawValue)
        }
    }

    private func syncMapWindow() {
        if session.isMapPresented {
            openWindow(id: AuxiliaryWindowID.map.rawValue)
        } else {
            dismissWindow(id: AuxiliaryWindowID.map.rawValue)
        }
    }
}

struct AuxiliaryWindowCommands: Commands {
    @ObservedObject var session: GameSession
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some Commands {
        CommandMenu("Panels") {
            Button("Show Mission Overlay") {
                openWindow(id: AuxiliaryWindowID.overlay.rawValue)
            }

            Button("Show Control Deck") {
                openWindow(id: AuxiliaryWindowID.controls.rawValue)
            }

            Button("Show Menu Shell") {
                openWindow(id: AuxiliaryWindowID.menu.rawValue)
            }
            .disabled(session.menuPanel == nil)

            Button(session.isMapPresented ? "Hide Canberra Map" : "Show Canberra Map") {
                if session.isMapPresented {
                    session.enqueueStateChange { state in
                        state.setMapPresented(false)
                    }
                    dismissWindow(id: AuxiliaryWindowID.map.rawValue)
                } else {
                    session.enqueueStateChange { state in
                        state.setMapPresented(true)
                    }
                    openWindow(id: AuxiliaryWindowID.map.rawValue)
                }
            }
            .disabled(!session.canShowMap && !session.isMapPresented)
        }
    }
}

private struct WindowShellCard<Content: View>: View {
    let title: String
    let subtitle: String
    var maxWidth: CGFloat = 520
    @ViewBuilder let content: Content

    init(
        title: String,
        subtitle: String,
        maxWidth: CGFloat = 520,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.maxWidth = maxWidth
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.76))

            content
        }
        .padding(16)
        .frame(maxWidth: maxWidth, alignment: .leading)
        .background(.black.opacity(0.68), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.28), radius: 20, y: 10)
    }
}

private struct WindowActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.09))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct MissionOverlayWindow: View {
    @ObservedObject var session: GameSession

    var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()

            ScrollView {
                WindowShellCard(
                    title: session.overlayTitle,
                    subtitle: session.statusLine,
                    maxWidth: 420
                ) {
                    ForEach(Array(session.overlayLines.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(16)
                .opacity(session.hudCardOpacity)
            }
        }
        .frame(minWidth: 440, minHeight: 520)
    }
}

struct ControlDeckWindow: View {
    @ObservedObject var session: GameSession

    var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()

            WindowShellCard(
                title: "Control Deck",
                subtitle: session.inputCardSubtitle,
                maxWidth: 420
            ) {
                ControlDeck(
                    activeCommands: session.activeCommands,
                    menuPanel: session.menuPanel,
                    demoFlowState: session.demoFlowState,
                    scopeActive: session.isScopeActive,
                    mapVisible: session.isMapPresented,
                    mapAvailable: session.canShowMap
                )
            }
            .padding(16)
            .opacity(session.hudCardOpacity)
        }
        .frame(minWidth: 430, minHeight: 280)
    }
}

struct MenuPanelWindow: View {
    @ObservedObject var session: GameSession

    var body: some View {
        ZStack {
            Color.black.opacity(0.94).ignoresSafeArea()

            if let panel = session.menuPanel {
                ScrollView {
                    WindowShellCard(
                        title: session.menuTitle(for: panel),
                        subtitle: session.menuSubtitle(for: panel)
                    ) {
                        ForEach(Array(session.menuLines(for: panel).enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.system(size: 13, weight: .regular, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.9))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if panel == .settings {
                            SettingsControlsPane(session: session)
                        }

                        MenuActionStack(session: session, panel: panel)
                    }
                    .padding(18)
                }
            } else {
                WindowShellCard(
                    title: "Menu Shell",
                    subtitle: "No active shell state"
                ) {
                    Text("The live demo is active. Pause, fail, complete, or open settings to repopulate this window.")
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.82))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(18)
            }
        }
        .frame(minWidth: 520, minHeight: 420)
    }
}

struct CanberraMapWindow: View {
    @ObservedObject var session: GameSession

    var body: some View {
        ZStack {
            Color.black.opacity(0.94).ignoresSafeArea()

            if let snapshot = session.overheadMapSnapshot {
                GeometryReader { geometry in
                    let layout = CanberraMapLayout.fitting(in: geometry.size)

                    ScrollView([.vertical, .horizontal]) {
                        WindowShellCard(
                            title: "Canberra Map",
                            subtitle: mapSubtitle(for: snapshot),
                            maxWidth: layout.cardWidth
                        ) {
                            OverheadMapCanvas(
                                snapshot: snapshot,
                                canvasHeight: layout.canvasHeight
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .frame(width: layout.cardWidth, alignment: .leading)
                        .padding(18)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                WindowShellCard(
                    title: "Canberra Map",
                    subtitle: "Waiting for map data"
                ) {
                    Text("Map data will appear here once the scene publishes a valid Canberra layout.")
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.82))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(18)
            }
        }
        .frame(minWidth: 760, minHeight: 620)
        .onDisappear {
            guard session.isMapPresented else {
                return
            }

            session.enqueueStateChange { state in
                state.setMapPresented(false)
            }
        }
    }

    private func mapSubtitle(for snapshot: OverheadMapSnapshot) -> String {
        if let nextCheckpointLabel = snapshot.nextCheckpointLabel {
            if let nextCombatStop = snapshot.nextCombatStop {
                return "Sector: \(snapshot.currentSectorName) • next marker: \(nextCheckpointLabel) • contact \(nextCombatStop.district)"
            }

            if let nextComparisonStop = snapshot.nextComparisonStop {
                return "Sector: \(snapshot.currentSectorName) • next marker: \(nextCheckpointLabel) • compare \(nextComparisonStop.district)"
            }

            return "Sector: \(snapshot.currentSectorName) • next marker: \(nextCheckpointLabel)"
        }

        return "Sector: \(snapshot.currentSectorName) • route complete"
    }
}

private struct SettingsControlsPane: View {
    @ObservedObject var session: GameSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(String(format: "Look Sensitivity %.2fx", session.lookSensitivityScale))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.92))
                Slider(
                    value: Binding(
                        get: { session.lookSensitivityScale },
                        set: { value in
                            session.enqueueStateChange { state in
                                state.setLookSensitivityScale(value)
                            }
                        }
                    ),
                    in: 0.6...1.8,
                    step: 0.05
                )
                .tint(Color(red: 0.92, green: 0.82, blue: 0.36))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(String(format: "HUD Opacity %.0f%%", session.hudOpacity * 100))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.92))
                Slider(
                    value: Binding(
                        get: { session.hudOpacity },
                        set: { value in
                            session.enqueueStateChange { state in
                                state.setHUDOpacity(value)
                            }
                        }
                    ),
                    in: 0.35...1.0,
                    step: 0.05
                )
                .tint(Color(red: 0.34, green: 0.74, blue: 0.96))
            }

            Toggle(
                isOn: Binding(
                    get: { session.invertLookY },
                    set: { value in
                        session.enqueueStateChange { state in
                            state.setInvertLookY(value)
                        }
                    }
                )
            ) {
                Text("Invert Look Y")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.92))
            }
            .toggleStyle(.switch)
            .tint(Color(red: 0.36, green: 0.84, blue: 0.58))

            Toggle(
                isOn: Binding(
                    get: { session.isMapPresented },
                    set: { value in
                        session.enqueueStateChange { state in
                            state.setMapPresented(value)
                        }
                    }
                )
            ) {
                Text(session.canShowMap ? "Show Canberra Map" : "Canberra Map Loading")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.92))
            }
            .toggleStyle(.switch)
            .tint(Color(red: 0.36, green: 0.74, blue: 0.96))
            .disabled(!session.canShowMap)
            .opacity(session.canShowMap ? 1 : 0.55)
        }
        .padding(.top, 4)
    }
}

private extension GameSession {
    func enqueueStateChange(_ change: @escaping (GameSession) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }

            change(self)
        }
    }
}

private struct MenuActionStack: View {
    @ObservedObject var session: GameSession
    let panel: GameMenuPanel

    var body: some View {
        VStack(spacing: 10) {
            switch panel {
            case .title:
                WindowActionButton(title: session.canBeginMission ? "Start Demo" : "Loading Scene...") {
                    session.startDemo()
                }
                .disabled(!session.canBeginMission)

                WindowActionButton(title: "Settings") {
                    session.openSettings()
                }

            case .paused:
                WindowActionButton(title: "Resume") {
                    session.resumeDemo()
                }

                WindowActionButton(title: "Restart Run") {
                    session.restartMission()
                }

                WindowActionButton(title: "Settings") {
                    session.openSettings()
                }

                WindowActionButton(title: "Return To Briefing") {
                    session.returnToBriefing()
                }

            case .failed:
                WindowActionButton(title: "Retry Checkpoint") {
                    session.retryFromCheckpoint()
                }

                WindowActionButton(title: "Restart Run") {
                    session.restartMission()
                }

                WindowActionButton(title: "Return To Briefing") {
                    session.returnToBriefing()
                }

            case .complete:
                WindowActionButton(title: "New Run") {
                    session.restartMission()
                }

                WindowActionButton(title: "Settings") {
                    session.openSettings()
                }

                WindowActionButton(title: "Return To Briefing") {
                    session.returnToBriefing()
                }

            case .settings:
                WindowActionButton(title: "Back") {
                    session.closeSettings()
                }
            }
        }
        .padding(.top, 6)
    }
}

private struct ControlDeck: View {
    let activeCommands: Set<InputCommand>
    let menuPanel: GameMenuPanel?
    let demoFlowState: DemoFlowState
    let scopeActive: Bool
    let mapVisible: Bool
    let mapAvailable: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(red: 0.92, green: 0.42, blue: 0.36))
                    .frame(width: 8, height: 8)

                Circle()
                    .fill(Color(red: 0.95, green: 0.78, blue: 0.30))
                    .frame(width: 8, height: 8)

                Circle()
                    .fill(Color(red: 0.36, green: 0.82, blue: 0.58))
                    .frame(width: 8, height: 8)

                Text("field-controls://canberra")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.78))

                Spacer()

                Text(statusBadge)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.82))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.09))
                    )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.05))

            HStack(alignment: .top, spacing: 12) {
                MovementCluster(activeCommands: activeCommands)

                VStack(alignment: .leading, spacing: 10) {
                    ControlLegendRow(
                        keycaps: ["Mouse"],
                        title: "Look",
                        detail: "Free-look across the basin lanes",
                        accent: Color(red: 0.72, green: 0.76, blue: 0.84)
                    )
                    ControlLegendRow(
                        keycaps: menuPanel == .title ? ["Space", "Return"] : ["Space"],
                        title: menuPanel == .title ? "Deploy / Confirm" : "4x Scope",
                        detail: menuPanel == .title ? "Start or confirm the current shell selection" : "Raise or lower the observation optic",
                        active: scopeActive,
                        accent: Color(red: 0.94, green: 0.86, blue: 0.44)
                    )
                    ControlLegendRow(
                        keycaps: ["M"],
                        title: mapVisible ? "Map Open" : "Canberra Map",
                        detail: mapAvailable ? "Toggle the Canberra map" : "Unlocks when scene data is ready",
                        active: mapVisible,
                        accent: Color(red: 0.34, green: 0.78, blue: 0.96),
                        dimmed: !mapAvailable
                    )
                    ControlLegendRow(
                        keycaps: ["R"],
                        title: "Restart Route",
                        detail: "Restart or retry from the latest checkpoint",
                        accent: Color(red: 0.94, green: 0.54, blue: 0.42)
                    )
                    ControlLegendRow(
                        keycaps: ["Esc"],
                        title: demoFlowState == .paused ? "Resume Shell" : "Pause Shell",
                        detail: "Pause or resume the live demo shell",
                        active: demoFlowState == .paused,
                        accent: Color(red: 0.90, green: 0.72, blue: 0.34)
                    )
                }
            }
            .padding(12)
        }
        .background(Color.black.opacity(0.44), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private var statusBadge: String {
        switch demoFlowState {
        case .title:
            return "BRIEF"
        case .playing:
            return mapVisible ? "LIVE+MAP" : "LIVE"
        case .paused:
            return "PAUSED"
        case .failed:
            return "RETRY"
        case .complete:
            return "CLEAR"
        }
    }
}

private struct MovementCluster: View {
    let activeCommands: Set<InputCommand>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Movement")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.76))

            VStack(spacing: 6) {
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    KeycapView(
                        label: "W",
                        active: activeCommands.contains(.forward),
                        accent: Color(red: 0.34, green: 0.74, blue: 0.96)
                    )
                    Spacer(minLength: 0)
                }

                HStack(spacing: 6) {
                    KeycapView(
                        label: "A",
                        active: activeCommands.contains(.strafeLeft),
                        accent: Color(red: 0.34, green: 0.74, blue: 0.96)
                    )
                    KeycapView(
                        label: "S",
                        active: activeCommands.contains(.backward),
                        accent: Color(red: 0.34, green: 0.74, blue: 0.96)
                    )
                    KeycapView(
                        label: "D",
                        active: activeCommands.contains(.strafeRight),
                        accent: Color(red: 0.34, green: 0.74, blue: 0.96)
                    )
                }

                KeycapView(
                    label: "Shift",
                    width: 120,
                    active: activeCommands.contains(.sprint),
                    accent: Color(red: 0.92, green: 0.66, blue: 0.34)
                )
            }

            Text("Ground movement, backstep, strafe, and sprint.")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.58))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(width: 144, alignment: .leading)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct ControlLegendRow: View {
    let keycaps: [String]
    let title: String
    let detail: String
    var active = false
    var accent = Color.white
    var dimmed = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            HStack(spacing: 6) {
                ForEach(keycaps, id: \.self) { keycap in
                    KeycapView(
                        label: keycap,
                        width: keycapWidth(for: keycap),
                        active: active,
                        accent: accent,
                        dimmed: dimmed
                    )
                }
            }
            .frame(minWidth: 94, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(dimmed ? .white.opacity(0.44) : .white.opacity(0.92))

                Text(detail)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(dimmed ? .white.opacity(0.36) : .white.opacity(0.60))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func keycapWidth(for keycap: String) -> CGFloat? {
        switch keycap {
        case "Mouse":
            return 62
        case "Space":
            return 58
        case "Return":
            return 60
        default:
            return keycap.count > 1 ? 52 : nil
        }
    }
}

private struct KeycapView: View {
    let label: String
    var width: CGFloat? = nil
    var active = false
    var accent = Color.white
    var dimmed = false

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(dimmed ? .white.opacity(0.42) : .white.opacity(active ? 0.98 : 0.90))
            .frame(width: width ?? 34, height: 34)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(active ? accent.opacity(0.28) : Color.white.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(active ? accent.opacity(0.72) : Color.white.opacity(0.14), lineWidth: 1)
            )
            .opacity(dimmed ? 0.58 : 1)
    }
}

private struct CanberraMapLayout {
    let cardWidth: CGFloat
    let canvasHeight: CGFloat

    static func fitting(in size: CGSize) -> CanberraMapLayout {
        let availableWidth = max(size.width - 56, 360)
        let availableHeight = max(size.height - 56, 360)
        let preferredCardWidth = min(max(availableWidth * 0.86, 720), 1080)
        let cardWidth = min(preferredCardWidth, availableWidth)
        let preferredCanvasHeight = cardWidth * 0.72
        let maxCanvasHeight = min(max(availableHeight - 154, 320), 780)
        let canvasHeight = max(min(preferredCanvasHeight, maxCanvasHeight), 320)

        return CanberraMapLayout(
            cardWidth: cardWidth,
            canvasHeight: canvasHeight
        )
    }
}

private struct OverheadMapCanvas: View {
    private struct SectorVisual: Identifiable {
        let id: String
        let rect: CGRect
        let fillColor: Color
        let strokeColor: Color
        let lineWidth: CGFloat
        let label: String?
        let labelPosition: CGPoint
        let labelWidth: CGFloat
    }

    private struct RoadVisual: Identifiable {
        let id: String
        let startPoint: CGPoint
        let endPoint: CGPoint
        let lineWidth: CGFloat
        let label: String?
        let labelPosition: CGPoint
        let labelWidth: CGFloat
        let rotation: Angle
    }

    private struct ThreatVisual: Identifiable {
        let id: String
        let center: CGPoint
        let rangeRect: CGRect
        let color: Color
        let markerSize: CGFloat
    }

    private struct CheckpointVisual: Identifiable {
        let id: String
        let center: CGPoint
        let diameter: CGFloat
        let fillColor: Color
        let contactRingColor: Color?
        let contactRingDiameter: CGFloat
    }

    private struct RenderModel {
        let gridPath: Path
        let sectorVisuals: [SectorVisual]
        let roadVisuals: [RoadVisual]
        let threatVisuals: [ThreatVisual]
        let routePath: Path
        let clearedRoutePath: Path
        let spawnRect: CGRect
        let checkpointVisuals: [CheckpointVisual]
        let playerHeadingPath: Path
        let playerRect: CGRect
        let headingRect: CGRect
        let northLabelPoint: CGPoint

        init(
            snapshot: OverheadMapSnapshot,
            drawingRect: CGRect,
            canvasScale: CGFloat,
            markerScale: CGFloat
        ) {
            let configuration = snapshot.configuration
            let scaleX = drawingRect.width / CGFloat(configuration.width)
            let scaleY = drawingRect.height / CGFloat(configuration.depth)
            let averageScale = (scaleX + scaleY) * 0.5
            let sectorLabelInset = 12 * canvasScale
            let roadLabelInset = 10 * canvasScale
            let contactCheckpointIDs = Set(configuration.contactStops.map(\.checkpointID))

            func point(forX x: Float, z: Float) -> CGPoint {
                let normalizedX = CGFloat((x - configuration.minX) / configuration.width)
                let normalizedY = CGFloat((configuration.maxZ - z) / configuration.depth)
                return CGPoint(
                    x: drawingRect.minX + (drawingRect.width * normalizedX),
                    y: drawingRect.minY + (drawingRect.height * normalizedY)
                )
            }

            func rect(for sector: SceneMapSector) -> CGRect {
                let topLeft = point(forX: sector.minX, z: sector.minZ)
                let bottomRight = point(forX: sector.maxX, z: sector.maxZ)
                let minX = min(topLeft.x, bottomRight.x)
                let maxX = max(topLeft.x, bottomRight.x)
                let minY = min(topLeft.y, bottomRight.y)
                let maxY = max(topLeft.y, bottomRight.y)

                return CGRect(
                    x: minX,
                    y: minY,
                    width: max(maxX - minX, 8),
                    height: max(maxY - minY, 8)
                )
            }

            func sectorFill(for sector: SceneMapSector) -> Color {
                let base: Color
                switch sector.residency {
                case .always:
                    base = Color(red: 0.38, green: 0.68, blue: 0.92)
                case .farField:
                    base = Color(red: 0.40, green: 0.58, blue: 0.80)
                case .local:
                    base = Color(red: 0.28, green: 0.40, blue: 0.56)
                }

                return sector.displayName == snapshot.currentSectorName
                    ? base.opacity(0.46)
                    : base.opacity(0.22)
            }

            func sectorStroke(for sector: SceneMapSector) -> Color {
                sector.displayName == snapshot.currentSectorName
                    ? Color(red: 0.94, green: 0.86, blue: 0.44).opacity(0.92)
                    : Color.white.opacity(0.12)
            }

            func threatColor(for observer: SceneMapThreatObserver) -> Color {
                Color(
                    .sRGB,
                    red: Double(observer.markerColor.x),
                    green: Double(observer.markerColor.y),
                    blue: Double(observer.markerColor.z),
                    opacity: Double(observer.markerColor.w)
                )
            }

            func checkpointColor(for checkpoint: SceneMapCheckpoint, index: Int) -> Color {
                if index < snapshot.completedCheckpointCount {
                    return Color(red: 0.36, green: 0.86, blue: 0.58)
                }

                if index == snapshot.completedCheckpointCount {
                    return Color(red: 0.96, green: 0.84, blue: 0.42)
                }

                if checkpoint.isGoal {
                    return Color(red: 0.42, green: 0.86, blue: 0.70)
                }

                return Color(red: 0.40, green: 0.76, blue: 0.96)
            }

            gridPath = Path { path in
                for index in 0...4 {
                    let fraction = CGFloat(index) / 4
                    let verticalX = drawingRect.minX + (drawingRect.width * fraction)
                    path.move(to: CGPoint(x: verticalX, y: drawingRect.minY))
                    path.addLine(to: CGPoint(x: verticalX, y: drawingRect.maxY))

                    let horizontalY = drawingRect.minY + (drawingRect.height * fraction)
                    path.move(to: CGPoint(x: drawingRect.minX, y: horizontalY))
                    path.addLine(to: CGPoint(x: drawingRect.maxX, y: horizontalY))
                }
            }

            sectorVisuals = configuration.sectors.map { sector in
                let sectorRect = rect(for: sector)
                let shouldShowLabel = sectorRect.width > 70 && sectorRect.height > 24
                return SectorVisual(
                    id: sector.id,
                    rect: sectorRect,
                    fillColor: sectorFill(for: sector),
                    strokeColor: sectorStroke(for: sector),
                    lineWidth: sector.displayName == snapshot.currentSectorName ? 1.6 : 1,
                    label: shouldShowLabel ? sector.shortLabel : nil,
                    labelPosition: CGPoint(x: sectorRect.midX, y: sectorRect.midY),
                    labelWidth: max(sectorRect.width - sectorLabelInset, 24)
                )
            }

            roadVisuals = configuration.roads.map { road in
                let startPoint = point(forX: road.startPoint.x, z: road.startPoint.z)
                let endPoint = point(forX: road.endPoint.x, z: road.endPoint.z)
                let midpoint = CGPoint(
                    x: (startPoint.x + endPoint.x) * 0.5,
                    y: (startPoint.y + endPoint.y) * 0.5
                )
                let labelWidth = hypot(endPoint.x - startPoint.x, endPoint.y - startPoint.y)
                let maxWidth = max(3.4 * markerScale, 1.4)
                let lineWidth = min(max(CGFloat(road.width) * averageScale, 1.4), maxWidth)

                return RoadVisual(
                    id: road.id,
                    startPoint: startPoint,
                    endPoint: endPoint,
                    lineWidth: lineWidth,
                    label: labelWidth > 80 ? road.shortLabel : nil,
                    labelPosition: midpoint,
                    labelWidth: max(labelWidth - roadLabelInset, 40),
                    rotation: .degrees(Double(-road.yawDegrees))
                )
            }

            threatVisuals = configuration.threatObservers.map { observer in
                let observerPoint = point(forX: observer.point.x, z: observer.point.z)
                let rangeSize = CGSize(
                    width: max(CGFloat(observer.range * 2) * scaleX, 10),
                    height: max(CGFloat(observer.range * 2) * scaleY, 10)
                )

                return ThreatVisual(
                    id: observer.id,
                    center: observerPoint,
                    rangeRect: Self.centeredRect(at: observerPoint, size: rangeSize),
                    color: threatColor(for: observer),
                    markerSize: 9 * markerScale
                )
            }

            let checkpointPoints = configuration.checkpoints.map { checkpoint in
                point(forX: checkpoint.point.x, z: checkpoint.point.z)
            }
            routePath = Self.polylinePath(from: checkpointPoints)

            let clearedCheckpointCount = min(snapshot.completedCheckpointCount, configuration.checkpoints.count)
            clearedRoutePath = clearedCheckpointCount > 1
                ? Self.polylinePath(from: Array(checkpointPoints.prefix(clearedCheckpointCount)))
                : Path()

            let spawnPoint = point(forX: configuration.spawnPoint.x, z: configuration.spawnPoint.z)
            let spawnSize = CGSize(width: 10 * markerScale, height: 10 * markerScale)
            spawnRect = Self.centeredRect(at: spawnPoint, size: spawnSize)

            checkpointVisuals = Array(zip(configuration.checkpoints, checkpointPoints).enumerated()).map { index, entry in
                let (checkpoint, checkpointPoint) = entry
                let diameter = (index == snapshot.completedCheckpointCount ? 11 : 9) * markerScale
                let isContactCheckpoint = contactCheckpointIDs.contains(checkpoint.id)

                return CheckpointVisual(
                    id: checkpoint.id,
                    center: checkpointPoint,
                    diameter: diameter,
                    fillColor: checkpointColor(for: checkpoint, index: index),
                    contactRingColor: isContactCheckpoint
                        ? Color(red: 0.94, green: 0.46, blue: 0.34).opacity(index == snapshot.completedCheckpointCount ? 0.94 : 0.68)
                        : nil,
                    contactRingDiameter: diameter * 1.5
                )
            }

            let playerPoint = point(forX: snapshot.playerX, z: snapshot.playerZ)
            let headingLength: Float = 20
            let headingPoint = point(
                forX: snapshot.playerX + (snapshot.headingX * headingLength),
                z: snapshot.playerZ + (snapshot.headingZ * headingLength)
            )

            playerHeadingPath = Path { path in
                path.move(to: playerPoint)
                path.addLine(to: headingPoint)
            }
            playerRect = Self.centeredRect(
                at: playerPoint,
                size: CGSize(width: 11 * markerScale, height: 11 * markerScale)
            )
            headingRect = Self.centeredRect(
                at: headingPoint,
                size: CGSize(width: 7 * markerScale, height: 7 * markerScale)
            )
            northLabelPoint = CGPoint(
                x: drawingRect.midX,
                y: drawingRect.minY + max(8 * canvasScale, 8)
            )
        }

        private static func centeredRect(at point: CGPoint, size: CGSize) -> CGRect {
            CGRect(
                x: point.x - (size.width * 0.5),
                y: point.y - (size.height * 0.5),
                width: size.width,
                height: size.height
            )
        }

        private static func polylinePath(from points: [CGPoint]) -> Path {
            Path { path in
                guard let first = points.first else {
                    return
                }

                path.move(to: first)
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
        }

        private static func diamondPath(center: CGPoint, size: CGFloat) -> Path {
            let halfSize = size * 0.5
            return Path { path in
                path.move(to: CGPoint(x: center.x, y: center.y - halfSize))
                path.addLine(to: CGPoint(x: center.x + halfSize, y: center.y))
                path.addLine(to: CGPoint(x: center.x, y: center.y + halfSize))
                path.addLine(to: CGPoint(x: center.x - halfSize, y: center.y))
                path.closeSubpath()
            }
        }
    }

    let snapshot: OverheadMapSnapshot
    let canvasHeight: CGFloat

    private var canvasScale: CGFloat {
        min(max(canvasHeight / 258, 1), 3)
    }

    private var markerScale: CGFloat {
        min(canvasScale, 1.7)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { geometry in
                let drawingInset = max(min(12 * canvasScale, 28), 12)
                let drawingRect = CGRect(
                    x: drawingInset,
                    y: drawingInset,
                    width: max(geometry.size.width - (drawingInset * 2), 1),
                    height: max(geometry.size.height - (drawingInset * 2), 1)
                )
                let renderModel = RenderModel(
                    snapshot: snapshot,
                    drawingRect: drawingRect,
                    canvasScale: canvasScale,
                    markerScale: markerScale
                )

                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(red: 0.07, green: 0.10, blue: 0.12))

                    // Draw the map chrome in one pass so the overlay stops rebuilding
                    // a large SwiftUI shape tree every telemetry refresh.
                    Canvas(opaque: false, colorMode: .nonLinear, rendersAsynchronously: true) { context, _ in
                        context.stroke(renderModel.gridPath, with: .color(.white.opacity(0.05)), lineWidth: 1)

                        for sector in renderModel.sectorVisuals {
                            let sectorPath = Path(
                                roundedRect: sector.rect,
                                cornerSize: CGSize(width: 10, height: 10),
                                style: .continuous
                            )
                            context.fill(sectorPath, with: .color(sector.fillColor))
                            context.stroke(
                                sectorPath,
                                with: .color(sector.strokeColor),
                                lineWidth: sector.lineWidth
                            )
                        }

                        for road in renderModel.roadVisuals {
                            let roadPath = Path { path in
                                path.move(to: road.startPoint)
                                path.addLine(to: road.endPoint)
                            }
                            context.stroke(
                                roadPath,
                                with: .color(Color(red: 0.84, green: 0.86, blue: 0.90).opacity(0.84)),
                                style: StrokeStyle(lineWidth: road.lineWidth, lineCap: .round)
                            )
                        }

                        for threat in renderModel.threatVisuals {
                            let threatRangePath = Path(ellipseIn: threat.rangeRect)
                            context.fill(
                                threatRangePath,
                                with: .color(threat.color.opacity(0.05))
                            )
                            context.stroke(
                                threatRangePath,
                                with: .color(threat.color.opacity(0.18)),
                                style: StrokeStyle(lineWidth: 1.1, dash: [4, 4])
                            )
                        }

                        context.stroke(
                            renderModel.routePath,
                            with: .color(Color(red: 0.94, green: 0.84, blue: 0.40).opacity(0.72)),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round, dash: [6, 4])
                        )
                        context.stroke(
                            renderModel.clearedRoutePath,
                            with: .color(Color(red: 0.36, green: 0.86, blue: 0.58).opacity(0.90)),
                            style: StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round)
                        )

                        let spawnPath = Path(
                            roundedRect: renderModel.spawnRect,
                            cornerSize: CGSize(width: 3, height: 3),
                            style: .continuous
                        )
                        context.fill(spawnPath, with: .color(.white.opacity(0.92)))

                        for checkpoint in renderModel.checkpointVisuals {
                            let checkpointRect = Self.centeredRect(
                                at: checkpoint.center,
                                size: CGSize(width: checkpoint.diameter, height: checkpoint.diameter)
                            )
                            let checkpointPath = Path(ellipseIn: checkpointRect)
                            context.fill(checkpointPath, with: .color(checkpoint.fillColor))
                            context.stroke(
                                checkpointPath,
                                with: .color(.black.opacity(0.28)),
                                lineWidth: 1
                            )

                            if let contactRingColor = checkpoint.contactRingColor {
                                let contactRingRect = Self.centeredRect(
                                    at: checkpoint.center,
                                    size: CGSize(
                                        width: checkpoint.contactRingDiameter,
                                        height: checkpoint.contactRingDiameter
                                    )
                                )
                                context.stroke(
                                    Path(ellipseIn: contactRingRect),
                                    with: .color(contactRingColor),
                                    lineWidth: 2
                                )
                            }
                        }

                        for threat in renderModel.threatVisuals {
                            let threatPath = Self.diamondPath(
                                center: threat.center,
                                size: threat.markerSize
                            )
                            context.fill(threatPath, with: .color(threat.color))
                            context.stroke(
                                threatPath,
                                with: .color(.black.opacity(0.28)),
                                lineWidth: 1
                            )
                        }

                        context.stroke(
                            renderModel.playerHeadingPath,
                            with: .color(Color(red: 0.34, green: 0.82, blue: 0.98)),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        context.fill(
                            Path(ellipseIn: renderModel.playerRect),
                            with: .color(Color(red: 0.34, green: 0.82, blue: 0.98))
                        )
                        context.stroke(
                            Path(ellipseIn: renderModel.playerRect),
                            with: .color(.white.opacity(0.78)),
                            lineWidth: 1
                        )
                        context.fill(
                            Path(ellipseIn: renderModel.headingRect),
                            with: .color(Color(red: 0.34, green: 0.82, blue: 0.98).opacity(0.82))
                        )
                    }

                    ForEach(renderModel.sectorVisuals) { sector in
                        if let label = sector.label {
                            Text(label)
                                .font(.system(size: min(9 * canvasScale, 20), weight: .semibold, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.72))
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                                .frame(width: sector.labelWidth)
                                .position(sector.labelPosition)
                        }
                    }

                    ForEach(renderModel.roadVisuals) { road in
                        if let label = road.label {
                            Text(label)
                                .font(.system(size: min(8 * canvasScale, 18), weight: .bold, design: .monospaced))
                                .foregroundStyle(Color(red: 0.95, green: 0.95, blue: 0.97).opacity(0.86))
                                .lineLimit(1)
                                .minimumScaleFactor(0.55)
                                .frame(width: road.labelWidth)
                                .padding(.horizontal, max(5 * canvasScale, 5))
                                .padding(.vertical, max(2 * canvasScale, 2))
                                .background(
                                    Color.black.opacity(0.54),
                                    in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                                )
                                .rotationEffect(road.rotation)
                                .position(road.labelPosition)
                        }
                    }

                    Text("N")
                        .font(.system(size: min(10 * canvasScale, 20), weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.82))
                        .position(renderModel.northLabelPoint)
                }
            }
            .frame(height: canvasHeight)

            HStack(spacing: 12) {
                legendItem(color: .white.opacity(0.92), label: "Spawn")
                legendItem(color: Color(red: 0.84, green: 0.86, blue: 0.90), label: "Roads")
                legendItem(color: Color(red: 0.36, green: 0.86, blue: 0.58), label: "Cleared")
                legendItem(color: Color(red: 0.94, green: 0.84, blue: 0.40), label: "Route")
                legendItem(color: Color(red: 0.94, green: 0.46, blue: 0.34), label: "Threat")
                legendItem(color: Color(red: 0.34, green: 0.82, blue: 0.98), label: "You")
            }

            Text(
                "Route: \(snapshot.completedCheckpointCount) / \(snapshot.totalCheckpointCount) checkpoints • \(Int(snapshot.configuration.routePlannedDistanceMeters.rounded()))m planned\(snapshot.nextCheckpointLabel.map { " • next \($0)" } ?? " • route complete")"
            )
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)

            Text(routeFootprintLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.66))
                .fixedSize(horizontal: false, vertical: true)

            Text("Review Pack: \(snapshot.configuration.reviewPackTitle) • refs \(snapshot.configuration.referenceGallery) • \(snapshot.configuration.openRisks.count) risks")
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.64))
                .fixedSize(horizontal: false, vertical: true)

            Text("Combat Rehearsal: \(snapshot.configuration.combatRehearsalTitle) • \(snapshot.configuration.contactStops.count) lanes • \(snapshot.configuration.threatObservers.count) watchers")
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)

            Text(comparisonLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.60))
                .fixedSize(horizontal: false, vertical: true)

            Text(contactLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.60))
                .fixedSize(horizontal: false, vertical: true)

            Text(pressureLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.60))
                .fixedSize(horizontal: false, vertical: true)

            Text("Atlas: \(snapshot.configuration.roads.count) named road strips across \(snapshot.configuration.sectors.count) Canberra sectors")
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)

            Text(String(format: "Position: %.0f east / %.0f south", snapshot.playerX, snapshot.playerZ))
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.58))
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: max(8 * markerScale, 8), height: max(8 * markerScale, 8))

            Text(label)
                .font(.system(size: min(10 * canvasScale, 15), weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.74))
        }
    }

    private var routeFootprintLine: String {
        let footprint = snapshot.configuration.routeSectorNames.count
        return "Footprint: \(footprint) sectors • \(snapshot.configuration.routeStartLabel) -> \(snapshot.configuration.routeGoalLabel)"
    }

    private var comparisonLine: String {
        if let nextComparisonStop = snapshot.nextComparisonStop {
            return "Compare: \(nextComparisonStop.district) • \(nextComparisonStop.sourceFocus) • lane \(nextComparisonStop.combatLane)"
        }

        return "Compare: review pack complete • texture library \(snapshot.configuration.textureLibrary)"
    }

    private var contactLine: String {
        if let nextCombatStop = snapshot.nextCombatStop {
            return "Contact: \(nextCombatStop.lane) • \(nextCombatStop.exposure) • \(nextCombatStop.expectedObservers) watchers • cover \(nextCombatStop.coverHint)"
        }

        return "Contact: rehearsal complete • \(snapshot.configuration.recoveryRule)"
    }

    private var pressureLine: String {
        String(
            format: "Threat: %.2f suspicion • %d seeing • %d in range • %d fails",
            snapshot.suspicionLevel,
            snapshot.seeingObserverCount,
            snapshot.activeObserverCount,
            snapshot.failCount
        )
    }

    private static func centeredRect(at point: CGPoint, size: CGSize) -> CGRect {
        CGRect(
            x: point.x - (size.width * 0.5),
            y: point.y - (size.height * 0.5),
            width: size.width,
            height: size.height
        )
    }

    private static func diamondPath(center: CGPoint, size: CGFloat) -> Path {
        let halfSize = size * 0.5
        return Path { path in
            path.move(to: CGPoint(x: center.x, y: center.y - halfSize))
            path.addLine(to: CGPoint(x: center.x + halfSize, y: center.y))
            path.addLine(to: CGPoint(x: center.x, y: center.y + halfSize))
            path.addLine(to: CGPoint(x: center.x - halfSize, y: center.y))
            path.closeSubpath()
        }
    }
}

private struct ScopeOverlay: View {
    let statusText: String
    let instructionText: String
    let reticleColor: Color

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let diameter = min(size.width, size.height) * 0.82
            let apertureRect = CGRect(
                x: (size.width - diameter) * 0.5,
                y: (size.height - diameter) * 0.5,
                width: diameter,
                height: diameter
            )
            let centerX = size.width * 0.5
            let centerY = size.height * 0.5
            let centerGap = diameter * 0.07
            let reticleInset = diameter * 0.05
            let armLength = max((diameter * 0.5) - reticleInset - (centerGap * 0.5), 24)
            let armThickness = max(diameter * 0.0028, 1.4)
            let labelY = min(apertureRect.maxY + 52, size.height - 38)

            ZStack {
                ScopeOcclusionShape(apertureRect: apertureRect)
                    .fill(Color.black.opacity(0.82), style: FillStyle(eoFill: true))

                Circle()
                    .stroke(Color.black.opacity(0.55), lineWidth: 14)
                    .frame(width: diameter, height: diameter)
                    .position(x: centerX, y: centerY)

                Circle()
                    .stroke(reticleColor.opacity(0.92), lineWidth: 2)
                    .frame(width: diameter, height: diameter)
                    .position(x: centerX, y: centerY)

                Circle()
                    .stroke(reticleColor.opacity(0.35), lineWidth: 1)
                    .frame(width: diameter * 0.64, height: diameter * 0.64)
                    .position(x: centerX, y: centerY)

                reticleArm(length: armLength, thickness: armThickness)
                    .position(x: centerX - ((centerGap + armLength) * 0.5), y: centerY)

                reticleArm(length: armLength, thickness: armThickness)
                    .position(x: centerX + ((centerGap + armLength) * 0.5), y: centerY)

                reticleArm(length: armLength, thickness: armThickness)
                    .rotationEffect(.degrees(90))
                    .position(x: centerX, y: centerY - ((centerGap + armLength) * 0.5))

                reticleArm(length: armLength, thickness: armThickness)
                    .rotationEffect(.degrees(90))
                    .position(x: centerX, y: centerY + ((centerGap + armLength) * 0.5))

                Circle()
                    .fill(reticleColor.opacity(0.96))
                    .frame(width: 6, height: 6)
                    .position(x: centerX, y: centerY)

                VStack(spacing: 6) {
                    Text(statusText)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.96))

                    Text(instructionText)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(reticleColor.opacity(0.94))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(reticleColor.opacity(0.28), lineWidth: 1)
                )
                .position(x: centerX, y: labelY)
            }
        }
    }

    private func reticleArm(length: CGFloat, thickness: CGFloat) -> some View {
        Rectangle()
            .fill(reticleColor.opacity(0.94))
            .frame(width: length, height: thickness)
    }
}

private struct ScopeOcclusionShape: Shape {
    let apertureRect: CGRect

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        path.addEllipse(in: apertureRect)
        return path
    }
}
