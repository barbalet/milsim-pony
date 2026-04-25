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
                .allowsHitTesting(false)

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
            presentationText: session.scopePresentationText,
            shotTimingText: session.scopeShotTimingText,
            shotFeedbackText: session.shotFeedbackText,
            reticleColor: Color(nsColor: session.scopeReticleColor),
            reticleOffset: session.scopeReticleOffset,
            recoilOffset: session.scopeRecoilOffset,
            muzzleFlashStrength: session.muzzleFlashStrength,
            reticleBloomScale: session.scopeReticleBloomScale,
            lensDirtOpacity: session.scopeLensDirtOpacity,
            edgeAberrationOpacity: session.scopeEdgeAberrationOpacity,
            parallaxCompensationPercent: session.scopeParallaxCompensationPercent,
            milDotSpacingText: session.scopeMilDotSpacingText
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
                recoverGameplayInputFocus()
            }
            .onChange(of: session.isMapPresented) { _, _ in
                syncMapWindow()
            }
            .onChange(of: session.menuPanel) { _, _ in
                syncMenuWindow()
            }
    }

    private func syncMenuWindow() {
        if session.menuPanel != nil {
            openWindow(id: AuxiliaryWindowID.menu.rawValue)
            recoverGameplayInputFocus()
        } else {
            dismissWindow(id: AuxiliaryWindowID.menu.rawValue)
            recoverGameplayInputFocus()
        }
    }

    private func syncMapWindow() {
        if session.isMapPresented {
            openWindow(id: AuxiliaryWindowID.map.rawValue)
            recoverGameplayInputFocus()
        } else {
            dismissWindow(id: AuxiliaryWindowID.map.rawValue)
            recoverGameplayInputFocus()
        }
    }

    private func recoverGameplayInputFocus() {
        session.enqueueStateChange { state in
            state.scheduleGameplayInputFocusRecovery()
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
            SDFText(text: title, size: 17, weight: .semibold)

            SDFText(text: subtitle, size: 12, color: .white.opacity(0.76))

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
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .multilineTextAlignment(.center)
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

private struct SDFText: View {
    let text: String
    var size: CGFloat
    var weight: Font.Weight = .medium
    var color: Color = .white
    var outlineColor: Color = .black.opacity(0.88)
    var shadowColor: Color = .black.opacity(0.74)
    var minimumScaleFactor: CGFloat = 0.58
    var lineLimit: Int? = 1

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: weight, design: .monospaced))
            .foregroundStyle(color)
            .lineLimit(lineLimit)
            .minimumScaleFactor(minimumScaleFactor)
            .shadow(color: outlineColor, radius: 0, x: -1, y: 0)
            .shadow(color: outlineColor, radius: 0, x: 1, y: 0)
            .shadow(color: outlineColor, radius: 0, x: 0, y: -1)
            .shadow(color: outlineColor, radius: 0, x: 0, y: 1)
            .shadow(color: shadowColor, radius: 2, x: 0, y: 1)
            .drawingGroup(opaque: false, colorMode: .linear)
    }
}

private struct HostingWindowReader: NSViewRepresentable {
    let onResolve: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async { [weak view] in
            onResolve(view?.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { [weak nsView] in
            onResolve(nsView?.window)
        }
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
                        SDFText(
                            text: line,
                            size: 12,
                            weight: .regular,
                            color: .white.opacity(0.9),
                            lineLimit: nil
                        )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
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
    @Environment(\.dismiss) private var dismiss
    @State private var hostingWindow: NSWindow?

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
        .background(
            HostingWindowReader { window in
                bindHostingWindow(window)
            }
        )
        .frame(minWidth: 520, minHeight: 420)
        .onAppear {
            reconcileWindowState()
        }
        .onChange(of: session.menuPanel != nil) { _, _ in
            reconcileWindowState()
        }
    }

    private func reconcileWindowState() {
        guard session.menuPanel == nil else {
            return
        }

        if let hostingWindow {
            hostingWindow.close()
        } else {
            dismiss()
        }
        session.enqueueStateChange { state in
            state.scheduleGameplayInputFocusRecovery()
        }
    }

    private func bindHostingWindow(_ window: NSWindow?) {
        guard hostingWindow !== window else {
            return
        }

        hostingWindow = window
        hostingWindow?.isRestorable = false
        reconcileWindowState()
    }
}

struct CanberraMapWindow: View {
    @ObservedObject var session: GameSession
    @Environment(\.dismiss) private var dismiss
    @State private var hostingWindow: NSWindow?

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
        .background(
            HostingWindowReader { window in
                bindHostingWindow(window)
            }
        )
        .frame(minWidth: 760, minHeight: 620)
        .onAppear {
            reconcileWindowState()
        }
        .onChange(of: session.isMapPresented) { _, _ in
            reconcileWindowState()
        }
        .onDisappear {
            guard session.isMapPresented else {
                return
            }

            session.enqueueStateChange { state in
                state.setMapPresented(false)
            }
        }
    }

    private func reconcileWindowState() {
        guard session.isMapPresented else {
            if let hostingWindow {
                hostingWindow.close()
            } else {
                dismiss()
            }
            session.enqueueStateChange { state in
                state.scheduleGameplayInputFocusRecovery()
            }
            return
        }
    }

    private func bindHostingWindow(_ window: NSWindow?) {
        guard hostingWindow !== window else {
            return
        }

        hostingWindow = window
        hostingWindow?.isRestorable = false
        reconcileWindowState()
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
                Text("Field Difficulty")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.92))

                Picker(
                    "Field Difficulty",
                    selection: Binding(
                        get: { session.difficultyPreset },
                        set: { value in
                            session.enqueueStateChange { state in
                                state.setDifficultyPreset(value)
                            }
                        }
                    )
                ) {
                    ForEach(RehearsalDifficultyPreset.allCases) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }
                .pickerStyle(.segmented)

                Text(session.difficultySummaryText)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.60))
                    .fixedSize(horizontal: false, vertical: true)
            }

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

            VStack(alignment: .leading, spacing: 6) {
                Text(String(format: "Audio Master %.0f%%", session.audioMasterGain * 100))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.92))
                Slider(
                    value: Binding(
                        get: { session.audioMasterGain },
                        set: { value in
                            session.enqueueStateChange { state in
                                state.setAudioMasterGain(value)
                            }
                        }
                    ),
                    in: 0.0...1.0,
                    step: 0.05
                )
                .tint(Color(red: 0.92, green: 0.58, blue: 0.38))
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

                WindowActionButton(title: session.savedSessionResumeButtonTitle) {
                    session.resumeSavedSession()
                }
                .disabled(!session.canResumeSavedSession)

                WindowActionButton(title: session.manualRestoreChoiceButtonTitle) {
                    session.previewManualRestoreChoice()
                }
                .disabled(!session.canPreviewManualRestoreChoice)

                WindowActionButton(title: session.manualRestoreExecutionButtonTitle) {
                    session.requestManualRestoreExecution()
                }
                .disabled(!session.canExecuteManualRestore)

                WindowActionButton(title: session.alternateRouteActivationButtonTitle) {
                    session.armAlternateRouteForNextFreshRun()
                }
                .disabled(!session.canArmAlternateRouteActivation)

                WindowActionButton(title: session.collisionAuthoringButtonTitle) {
                    session.selectNextCollisionVolumeForReview()
                }
                .disabled(!session.canInspectCollisionAuthoring)

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
                        keycaps: ["Click", "F"],
                        title: "Fire",
                        detail: "Break the current rifle shot and confirm scoped hits plus cadence feedback",
                        accent: Color(red: 0.94, green: 0.46, blue: 0.34)
                    )
                    ControlLegendRow(
                        keycaps: ["E"],
                        title: "Steady Aim",
                        detail: "Hold breath and tighten the scoped rifle while you are settled",
                        active: activeCommands.contains(.steadyAim),
                        accent: Color(red: 0.56, green: 0.88, blue: 0.78)
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

    private struct CollisionVisual: Identifiable {
        let id: String
        let footprintPath: Path
        let fillColor: Color
        let strokeColor: Color
        let lineWidth: CGFloat
        let isSelected: Bool
    }

    private struct ThreatVisual: Identifiable {
        let id: String
        let center: CGPoint
        let rangeRect: CGRect
        let coveragePath: Path
        let coverageFillColor: Color
        let coverageStrokeColor: Color
        let markerFillColor: Color
        let markerStrokeColor: Color
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
        let collisionVisuals: [CollisionVisual]
        let threatVisuals: [ThreatVisual]
        let alternateRoutePaths: [Path]
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

            func threatPalette(
                for observer: SceneMapThreatObserver,
                state: OverheadMapThreatState?
            ) -> (
                fill: Color,
                stroke: Color,
                markerFill: Color,
                markerStroke: Color,
                markerSize: CGFloat
            ) {
                let authoredColor = threatColor(for: observer)
                if state?.neutralized == true {
                    let neutralized = Color(red: 0.36, green: 0.86, blue: 0.58)
                    return (
                        fill: neutralized.opacity(0.07),
                        stroke: neutralized.opacity(0.34),
                        markerFill: neutralized,
                        markerStroke: .white.opacity(0.22),
                        markerSize: 8.2 * markerScale
                    )
                }
                if state?.seeingPlayer == true {
                    let seeing = Color(red: 1.0, green: 0.36, blue: 0.30)
                    return (
                        fill: seeing.opacity(0.14),
                        stroke: seeing.opacity(0.72),
                        markerFill: seeing,
                        markerStroke: .white.opacity(0.34),
                        markerSize: 10.6 * markerScale
                    )
                }
                if state?.isAlerted == true {
                    let alerted = Color(red: 0.98, green: 0.86, blue: 0.34)
                    return (
                        fill: alerted.opacity(0.09),
                        stroke: alerted.opacity(0.46),
                        markerFill: alerted,
                        markerStroke: .black.opacity(0.24),
                        markerSize: 9.8 * markerScale
                    )
                }
                if state?.isMasked == true {
                    let masked = Color(red: 0.98, green: 0.68, blue: 0.28)
                    return (
                        fill: masked.opacity(0.09),
                        stroke: masked.opacity(0.44),
                        markerFill: masked,
                        markerStroke: .black.opacity(0.22),
                        markerSize: 9.6 * markerScale
                    )
                }

                return (
                    fill: authoredColor.opacity(0.05),
                    stroke: authoredColor.opacity(0.20),
                    markerFill: authoredColor,
                    markerStroke: .black.opacity(0.28),
                    markerSize: 9.0 * markerScale
                )
            }

            func threatCoveragePath(for observer: SceneMapThreatObserver, center: CGPoint) -> Path {
                let halfFieldOfView = max(observer.fieldOfViewDegrees * 0.5, 4)
                if observer.fieldOfViewDegrees >= 340 {
                    return Path(ellipseIn: Self.centeredRect(
                        at: center,
                        size: CGSize(
                            width: max(CGFloat(observer.range * 2) * scaleX, 10),
                            height: max(CGFloat(observer.range * 2) * scaleY, 10)
                        )
                    ))
                }

                let sampleCount = max(Int(observer.fieldOfViewDegrees / 10), 4)
                return Path { path in
                    path.move(to: center)
                    for sampleIndex in 0...sampleCount {
                        let t = Float(sampleIndex) / Float(sampleCount)
                        let yawDegrees = observer.yawDegrees - halfFieldOfView + ((halfFieldOfView * 2) * t)
                        let yawRadians = yawDegrees * (.pi / 180.0)
                        let arcPoint = point(
                            forX: observer.point.x + (sinf(yawRadians) * observer.range),
                            z: observer.point.z + (-cosf(yawRadians) * observer.range)
                        )
                        path.addLine(to: arcPoint)
                    }
                    path.closeSubpath()
                }
            }

            func collisionFootprintPath(for volume: SceneMapCollisionVolume) -> Path {
                let yawRadians = volume.yawDegrees * (.pi / 180.0)
                let forwardX = sinf(yawRadians) * volume.halfDepth
                let forwardZ = cosf(yawRadians) * volume.halfDepth
                let rightX = cosf(yawRadians) * volume.halfWidth
                let rightZ = -sinf(yawRadians) * volume.halfWidth
                let centerX = volume.centerPoint.x
                let centerZ = volume.centerPoint.z
                let corners: [CGPoint] = [
                    point(forX: centerX - rightX - forwardX, z: centerZ - rightZ - forwardZ),
                    point(forX: centerX + rightX - forwardX, z: centerZ + rightZ - forwardZ),
                    point(forX: centerX + rightX + forwardX, z: centerZ + rightZ + forwardZ),
                    point(forX: centerX - rightX + forwardX, z: centerZ - rightZ + forwardZ)
                ]

                return Path { path in
                    guard let first = corners.first else {
                        return
                    }

                    path.move(to: first)
                    for corner in corners.dropFirst() {
                        path.addLine(to: corner)
                    }
                    path.closeSubpath()
                }
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

            collisionVisuals = configuration.collisionVolumes.map { volume in
                let isAuthored = volume.source == "authored"
                let isSelected = volume.id == snapshot.selectedCollisionVolumeID
                return CollisionVisual(
                    id: volume.id,
                    footprintPath: collisionFootprintPath(for: volume),
                    fillColor: isSelected
                        ? Color(red: 1.0, green: 0.88, blue: 0.34).opacity(0.25)
                        : isAuthored
                        ? Color(red: 0.98, green: 0.48, blue: 0.30).opacity(0.11)
                        : Color(red: 0.96, green: 0.72, blue: 0.32).opacity(0.09),
                    strokeColor: isSelected
                        ? Color(red: 1.0, green: 0.94, blue: 0.58).opacity(0.98)
                        : isAuthored
                        ? Color(red: 1.0, green: 0.58, blue: 0.38).opacity(0.62)
                        : Color(red: 0.96, green: 0.78, blue: 0.36).opacity(0.46),
                    lineWidth: isSelected ? 2.2 : (isAuthored ? 1.25 : 0.9),
                    isSelected: isSelected
                )
            }

            threatVisuals = configuration.threatObservers.enumerated().map { index, observer in
                let threatState = index < snapshot.threatStates.count ? snapshot.threatStates[index] : nil
                let observerPoint = point(
                    forX: threatState?.x ?? observer.point.x,
                    z: threatState?.z ?? observer.point.z
                )
                let rangeSize = CGSize(
                    width: max(CGFloat(observer.range * 2) * scaleX, 10),
                    height: max(CGFloat(observer.range * 2) * scaleY, 10)
                )
                let palette = threatPalette(for: observer, state: threatState)

                return ThreatVisual(
                    id: observer.id,
                    center: observerPoint,
                    rangeRect: Self.centeredRect(at: observerPoint, size: rangeSize),
                    coveragePath: threatCoveragePath(for: observer, center: observerPoint),
                    coverageFillColor: palette.fill,
                    coverageStrokeColor: palette.stroke,
                    markerFillColor: palette.markerFill,
                    markerStrokeColor: palette.markerStroke,
                    markerSize: palette.markerSize
                )
            }

            let checkpointPoints = configuration.checkpoints.map { checkpoint in
                point(forX: checkpoint.point.x, z: checkpoint.point.z)
            }
            routePath = Self.polylinePath(from: checkpointPoints)

            alternateRoutePaths = configuration.alternateRoutes.map { alternateRoute in
                let alternateRoutePoints = alternateRoute.checkpointPoints.map { checkpointPoint in
                    point(forX: checkpointPoint.x, z: checkpointPoint.z)
                }
                return Self.polylinePath(from: alternateRoutePoints)
            }

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

                        for collision in renderModel.collisionVisuals {
                            context.fill(collision.footprintPath, with: .color(collision.fillColor))
                            context.stroke(
                                collision.footprintPath,
                                with: .color(collision.strokeColor),
                                style: StrokeStyle(
                                    lineWidth: collision.lineWidth,
                                    lineJoin: .round,
                                    dash: collision.isSelected ? [] : [3, 3]
                                )
                            )
                        }

                        for threat in renderModel.threatVisuals {
                            let threatRangePath = Path(ellipseIn: threat.rangeRect)
                            context.fill(
                                threatRangePath,
                                with: .color(threat.coverageFillColor.opacity(0.30))
                            )
                            context.stroke(
                                threatRangePath,
                                with: .color(threat.coverageStrokeColor.opacity(0.50)),
                                style: StrokeStyle(lineWidth: 1.1, dash: [4, 4])
                            )
                            context.fill(
                                threat.coveragePath,
                                with: .color(threat.coverageFillColor)
                            )
                            context.stroke(
                                threat.coveragePath,
                                with: .color(threat.coverageStrokeColor),
                                style: StrokeStyle(lineWidth: 1.2, lineJoin: .round)
                            )
                        }

                        context.stroke(
                            renderModel.routePath,
                            with: .color(Color(red: 0.94, green: 0.84, blue: 0.40).opacity(0.72)),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round, dash: [6, 4])
                        )
                        for (index, alternateRoutePath) in renderModel.alternateRoutePaths.enumerated() {
                            let alternateColor = index.isMultiple(of: 2)
                                ? Color(red: 0.34, green: 0.78, blue: 0.96)
                                : Color(red: 0.74, green: 0.62, blue: 0.96)
                            context.stroke(
                                alternateRoutePath,
                                with: .color(alternateColor.opacity(0.62)),
                                style: StrokeStyle(lineWidth: 2.1, lineCap: .round, lineJoin: .round, dash: [2, 5])
                            )
                        }
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
                            context.fill(threatPath, with: .color(threat.markerFillColor))
                            context.stroke(
                                threatPath,
                                with: .color(threat.markerStrokeColor),
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
                            SDFText(
                                text: label,
                                size: min(9 * canvasScale, 20),
                                weight: .semibold,
                                color: .white.opacity(0.72),
                                minimumScaleFactor: 0.6
                            )
                                .frame(width: sector.labelWidth)
                                .position(sector.labelPosition)
                        }
                    }

                    ForEach(renderModel.roadVisuals) { road in
                        if let label = road.label {
                            SDFText(
                                text: label,
                                size: min(8 * canvasScale, 18),
                                weight: .bold,
                                color: Color(red: 0.95, green: 0.95, blue: 0.97).opacity(0.86),
                                minimumScaleFactor: 0.55
                            )
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

                    SDFText(
                        text: "N",
                        size: min(10 * canvasScale, 20),
                        weight: .bold,
                        color: .white.opacity(0.82)
                    )
                        .position(renderModel.northLabelPoint)
                }
            }
            .frame(height: canvasHeight)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 92), spacing: 12, alignment: .leading)],
                alignment: .leading,
                spacing: 10
            ) {
                legendItem(color: .white.opacity(0.92), label: "Spawn")
                legendItem(color: Color(red: 0.84, green: 0.86, blue: 0.90), label: "Roads")
                legendItem(color: Color(red: 1.0, green: 0.58, blue: 0.38), label: "Collision")
                legendItem(color: Color(red: 0.36, green: 0.86, blue: 0.58), label: "Cleared")
                legendItem(color: Color(red: 0.94, green: 0.84, blue: 0.40), label: "Route")
                legendItem(color: Color(red: 0.34, green: 0.78, blue: 0.96), label: "Alt Preview")
                legendItem(color: Color(red: 1.0, green: 0.36, blue: 0.30), label: "Seeing")
                legendItem(color: Color(red: 0.98, green: 0.86, blue: 0.34), label: "Alerted")
                legendItem(color: Color(red: 0.98, green: 0.68, blue: 0.28), label: "Masked")
                legendItem(color: Color(red: 0.36, green: 0.86, blue: 0.58), label: "Neutralized")
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

            Text(activeRouteLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.65))
                .fixedSize(horizontal: false, vertical: true)

            Text(mapAccuracyLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.645))
                .fixedSize(horizontal: false, vertical: true)

            Text(routeValidationLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.64))
                .fixedSize(horizontal: false, vertical: true)

            Text(routeSelectionLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.635))
                .fixedSize(horizontal: false, vertical: true)

            Text(routeActivationLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.632))
                .fixedSize(horizontal: false, vertical: true)

            Text(routeRollbackLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.631))
                .fixedSize(horizontal: false, vertical: true)

            Text(routeCommitLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.630))
                .fixedSize(horizontal: false, vertical: true)

            Text(routeDryRunLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.629))
                .fixedSize(horizontal: false, vertical: true)

            Text(routePromotionLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.628))
                .fixedSize(horizontal: false, vertical: true)

            Text(routeAuditLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.627))
                .fixedSize(horizontal: false, vertical: true)

            Text(routeBoundaryLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.626))
                .fixedSize(horizontal: false, vertical: true)

            Text(routeArmingLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.625))
                .fixedSize(horizontal: false, vertical: true)

            Text(routeConfirmationLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.624))
                .fixedSize(horizontal: false, vertical: true)

            Text(routeReleaseLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.623))
                .fixedSize(horizontal: false, vertical: true)

            Text(routePreflightLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.622))
                .fixedSize(horizontal: false, vertical: true)

            Text(routeHandoffLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.63))
                .fixedSize(horizontal: false, vertical: true)

            Text(collisionAuthoringLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.622))
                .fixedSize(horizontal: false, vertical: true)

            Text(collisionPreviewLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.622))
                .fixedSize(horizontal: false, vertical: true)

            Text(snapshot.selectedCollisionVolumeLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.66))
                .fixedSize(horizontal: false, vertical: true)

            Text(snapshot.collisionValidationLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.64))
                .fixedSize(horizontal: false, vertical: true)

            Text(snapshot.collisionExportLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)

            Text(environmentalMotionLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.622))
                .fixedSize(horizontal: false, vertical: true)

            Text(shadowProfileLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.622))
                .fixedSize(horizontal: false, vertical: true)

            Text(surfaceFidelityLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.622))
                .fixedSize(horizontal: false, vertical: true)

            Text(distantLODLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.622))
                .fixedSize(horizontal: false, vertical: true)

            Text(waterReflectionLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.622))
                .fixedSize(horizontal: false, vertical: true)

            Text(packagingAutomationLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.622))
                .fixedSize(horizontal: false, vertical: true)

            Text(testerDistributionLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.622))
                .fixedSize(horizontal: false, vertical: true)

            Text(lightingArchitectureLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.622))
                .fixedSize(horizontal: false, vertical: true)

            Text(timeOfDayLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.622))
                .fixedSize(horizontal: false, vertical: true)

            Text(antiAliasingLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.622))
                .fixedSize(horizontal: false, vertical: true)

            Text(physicalAtmosphereLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.622))
                .fixedSize(horizontal: false, vertical: true)

            Text(indirectRenderingLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.622))
                .fixedSize(horizontal: false, vertical: true)

            Text(sdfUILine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.622))
                .fixedSize(horizontal: false, vertical: true)

            Text(renderGraphLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.622))
                .fixedSize(horizontal: false, vertical: true)

            Text(blackMountainMaterialLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.622))
                .fixedSize(horizontal: false, vertical: true)

            Text(westBasinWaterLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.622))
                .fixedSize(horizontal: false, vertical: true)

            Text(sessionPersistenceLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.622))
                .fixedSize(horizontal: false, vertical: true)

            Text("Review Pack: \(snapshot.configuration.reviewPackTitle) • refs \(snapshot.configuration.referenceGallery) • \(snapshot.configuration.openRisks.count) risks")
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.64))
                .fixedSize(horizontal: false, vertical: true)

            Text("Combat Rehearsal: \(snapshot.configuration.combatRehearsalTitle) • \(snapshot.configuration.contactStops.count) lanes • \(snapshot.configuration.threatObservers.count) watchers")
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)

            Text(missionLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.61))
                .fixedSize(horizontal: false, vertical: true)

            Text(alternateRouteLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.60))
                .fixedSize(horizontal: false, vertical: true)

            Text(comparisonLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.60))
                .fixedSize(horizontal: false, vertical: true)

            Text(contactLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.60))
                .fixedSize(horizontal: false, vertical: true)

            Text(threatMapLine)
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.62))
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

    private var activeRouteLine: String {
        let staged = snapshot.configuration.selectedAlternateRouteLabel ?? "no alternate staged"
        return "Active Route: \(snapshot.configuration.activeRouteLabel) • staged \(staged) • \(snapshot.configuration.routeBindingStatus) • \(snapshot.configuration.routeLoaderStatus)"
    }

    private var mapAccuracyLine: String {
        let nextLabel = snapshot.nextCheckpointLabel ?? "route complete"
        return "Map Accuracy: \(snapshot.configuration.activeRouteLabel) • \(snapshot.configuration.checkpoints.count) markers • \(snapshot.configuration.threatObservers.count) threat rings • next \(nextLabel) • footer \(Int(snapshot.configuration.routePlannedDistanceMeters.rounded()))m"
    }

    private var routeValidationLine: String {
        "Route Validation: \(snapshot.configuration.routeValidationStatus) • \(snapshot.configuration.routeValidationRule)"
    }

    private var routeSelectionLine: String {
        "Route Selection: \(snapshot.configuration.routeSelectionStatus) • \(snapshot.configuration.routeSelectionRule)"
    }

    private var routeActivationLine: String {
        "Route Activation: \(snapshot.configuration.routeActivationStatus) • \(snapshot.configuration.routeActivationRule)"
    }

    private var routeRollbackLine: String {
        "Route Rollback: \(snapshot.configuration.routeRollbackStatus) • \(snapshot.configuration.routeRollbackRule)"
    }

    private var routeCommitLine: String {
        "Route Commit: \(snapshot.configuration.routeCommitStatus) • \(snapshot.configuration.routeCommitRule)"
    }

    private var routeDryRunLine: String {
        "Route Dry Run: \(snapshot.configuration.routeDryRunStatus) • \(snapshot.configuration.routeDryRunRule)"
    }

    private var routePromotionLine: String {
        "Route Promotion: \(snapshot.configuration.routePromotionStatus) • \(snapshot.configuration.routePromotionRule)"
    }

    private var routeAuditLine: String {
        "Route Audit: \(snapshot.configuration.routeAuditStatus) • \(snapshot.configuration.routeAuditRule)"
    }

    private var routeBoundaryLine: String {
        "Route Boundary: \(snapshot.configuration.routeBoundaryStatus) • \(snapshot.configuration.routeBoundaryRule)"
    }

    private var routeArmingLine: String {
        "Route Arming: \(snapshot.configuration.routeArmingStatus) • \(snapshot.configuration.routeArmingRule)"
    }

    private var routeConfirmationLine: String {
        "Route Confirmation: \(snapshot.configuration.routeConfirmationStatus) • \(snapshot.configuration.routeConfirmationRule)"
    }

    private var routeReleaseLine: String {
        "Route Release: \(snapshot.configuration.routeReleaseStatus) • \(snapshot.configuration.routeReleaseRule)"
    }

    private var routePreflightLine: String {
        "Route Preflight: \(snapshot.configuration.routePreflightStatus) • \(snapshot.configuration.routePreflightRule)"
    }

    private var routeHandoffLine: String {
        "Route Handoff: \(snapshot.configuration.routeHandoffStatus) • \(snapshot.configuration.routeHandoffRule)"
    }

    private var collisionAuthoringLine: String {
        "Collision Authoring: \(snapshot.configuration.collisionAuthoringStatus) • \(snapshot.configuration.collisionAuthoringRule)"
    }

    private var collisionPreviewLine: String {
        let authoredCount = snapshot.configuration.collisionVolumes.filter { $0.source == "authored" }.count
        let grayboxCount = snapshot.configuration.collisionVolumes.count - authoredCount
        return "Collision Preview: \(snapshot.configuration.collisionVolumes.count) blocker footprints • \(authoredCount) authored / \(grayboxCount) graybox • \(snapshot.configuration.collisionAuthoringAudit)"
    }

    private var environmentalMotionLine: String {
        "Environmental Motion: \(snapshot.configuration.environmentalMotionStatus) • \(snapshot.configuration.environmentalMotionWindSummary)"
    }

    private var shadowProfileLine: String {
        "Shadow Profile: \(snapshot.configuration.shadowProfileStatus) • \(snapshot.configuration.shadowProfileSummary)"
    }

    private var surfaceFidelityLine: String {
        "Surface Fidelity: \(snapshot.configuration.surfaceFidelityStatus) • \(snapshot.configuration.surfaceFidelitySummary)"
    }

    private var distantLODLine: String {
        "Distant LOD: \(snapshot.configuration.distantLODStatus) • \(snapshot.configuration.distantLODSummary)"
    }

    private var waterReflectionLine: String {
        "Water Reflection: \(snapshot.configuration.waterReflectionStatus) • \(snapshot.configuration.waterReflectionSummary)"
    }

    private var packagingAutomationLine: String {
        "Packaging: \(snapshot.configuration.packagingAutomationStatus) • \(snapshot.configuration.packagingAutomationSummary)"
    }

    private var testerDistributionLine: String {
        "Tester Delivery: \(snapshot.configuration.testerDistributionStatus) • \(snapshot.configuration.testerDistributionSummary)"
    }

    private var lightingArchitectureLine: String {
        "Lighting Plan: \(snapshot.configuration.lightingArchitectureStatus) • \(snapshot.configuration.lightingArchitectureSummary)"
    }

    private var timeOfDayLine: String {
        "Time Of Day: \(snapshot.configuration.timeOfDayStatus) • \(snapshot.configuration.timeOfDaySummary)"
    }

    private var antiAliasingLine: String {
        "Anti-Aliasing: \(snapshot.configuration.antiAliasingStatus) • \(snapshot.configuration.antiAliasingSummary)"
    }

    private var physicalAtmosphereLine: String {
        "Physical Atmosphere: \(snapshot.configuration.physicalAtmosphereStatus) • \(snapshot.configuration.physicalAtmosphereSummary)"
    }

    private var indirectRenderingLine: String {
        "Indirect Rendering: \(snapshot.configuration.indirectRenderingStatus) • \(snapshot.configuration.indirectRenderingSummary)"
    }

    private var sdfUILine: String {
        "SDF UI: \(snapshot.configuration.sdfUIStatus) • \(snapshot.configuration.sdfUISummary)"
    }

    private var renderGraphLine: String {
        "Render Graph: \(snapshot.configuration.renderGraphStatus) • \(snapshot.configuration.renderGraphSummary)"
    }

    private var blackMountainMaterialLine: String {
        let capture = snapshot.configuration.comparisonStops.first { stop in
            stop.district.localizedCaseInsensitiveContains("Black Mountain")
        }?.captureNote ?? "capture Telstra Tower, Black Mountain, and Bruce material reads"
        return "Black Mountain Materials: Telstra/Bruce source-backed • \(snapshot.configuration.textureLibrary) • \(capture)"
    }

    private var westBasinWaterLine: String {
        let capture = snapshot.configuration.comparisonStops.first { stop in
            stop.district.localizedCaseInsensitiveContains("West Basin")
        }?.captureNote ?? "capture West Basin shoreline, water motion, and vegetation response"
        return "West Basin Materials: shoreline/water/vegetation • \(snapshot.configuration.environmentalMotionWindSummary) • \(capture)"
    }

    private var sessionPersistenceLine: String {
        "Session Persistence: \(snapshot.configuration.sessionPersistenceStatus) • \(snapshot.configuration.sessionPersistenceSummary)"
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

    private var missionLine: String {
        if let phase = snapshot.nextMissionPhase {
            let code = phase.mapCode.map { " • code \($0)" } ?? ""
            return "Mission: \(phase.phase) • \(phase.objective) • trigger \(phase.trigger)\(code)"
        }

        return "Mission: \(snapshot.configuration.missionScriptTitle) complete • \(snapshot.configuration.missionPhases.count) hooks"
    }

    private var alternateRouteLine: String {
        guard let route = snapshot.configuration.alternateRoutes.first else {
            return "Alt Routes: no additional rehearsal routes authored"
        }

        let previewCount = route.checkpointPoints.count
        let routeCount = snapshot.configuration.alternateRoutes.count
        let additionalRouteSummary = snapshot.configuration.alternateRoutes.dropFirst().first.map { nextRoute in
            " • next \(nextRoute.name) • \(nextRoute.checkpointPoints.count) markers • \(Int(nextRoute.plannedDistanceMeters.rounded()))m"
        } ?? ""
        return "Alt Preview: \(routeCount) candidates • selected \(route.name) • \(route.routeType) • \(previewCount) markers • \(Int(route.plannedDistanceMeters.rounded()))m • \(route.sectorNames.count) sectors • \(route.startCheckpointLabel) -> \(route.goalCheckpointLabel) • \(route.selectionMode) • \(route.selectionStatus) • \(route.checkpointOwnershipStatus) • shared \(route.sharedCheckpointLabels.count) / owned \(route.exclusiveCheckpointLabels.count) • \(route.activationRule)\(additionalRouteSummary)"
    }

    private var threatMapLine: String {
        "Map Threats: \(snapshot.seeingObserverCount) seeing • \(snapshot.alertedThreatCount) alerted • \(snapshot.maskedThreatCount) masked • \(snapshot.offAxisThreatCount) off-axis • \(snapshot.neutralizedObserverCount) neutralized • \(snapshot.idleThreatCount) idle"
    }

    private var pressureLine: String {
        String(
            format: "Threat: %@ • %.2f / %.2f fail • %d alerted • %d seeing • %d in range • %d neutralized • %d fails",
            snapshot.difficultyLabel,
            snapshot.suspicionLevel,
            snapshot.effectiveFailThreshold,
            snapshot.alertedObserverCount,
            snapshot.seeingObserverCount,
            snapshot.activeObserverCount,
            snapshot.neutralizedObserverCount,
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
    let presentationText: String
    let shotTimingText: String
    let shotFeedbackText: String
    let reticleColor: Color
    let reticleOffset: CGSize
    let recoilOffset: CGSize
    let muzzleFlashStrength: CGFloat
    let reticleBloomScale: CGFloat
    let lensDirtOpacity: CGFloat
    let edgeAberrationOpacity: CGFloat
    let parallaxCompensationPercent: Int
    let milDotSpacingText: String

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
            let maxReticleTravel = diameter * 0.12
            let reticleCenterX = centerX + ((reticleOffset.width + recoilOffset.width) * maxReticleTravel)
            let reticleCenterY = centerY + ((reticleOffset.height + recoilOffset.height) * maxReticleTravel)
            let bloomDiameter = max(centerGap * (1.0 + (reticleBloomScale * 3.0)), 10)
            let labelY = min(apertureRect.maxY + 52, size.height - 38)
            let flashWidth = diameter * (0.18 + (muzzleFlashStrength * 0.16))
            let flashHeight = diameter * (0.08 + (muzzleFlashStrength * 0.08))
            let edgeOffset = max(diameter * 0.0035 * edgeAberrationOpacity, 0.6)

            ZStack {
                ScopeOcclusionShape(apertureRect: apertureRect)
                    .fill(Color.black.opacity(0.82), style: FillStyle(eoFill: true))

                Circle()
                    .stroke(Color.black.opacity(0.55), lineWidth: 14)
                    .frame(width: diameter, height: diameter)
                    .position(x: centerX, y: centerY)

                Circle()
                    .stroke(Color(red: 0.95, green: 0.16, blue: 0.16).opacity(0.20 * edgeAberrationOpacity), lineWidth: 2)
                    .frame(width: diameter * 0.995, height: diameter * 0.995)
                    .position(x: centerX - edgeOffset, y: centerY)

                Circle()
                    .stroke(Color(red: 0.10, green: 0.74, blue: 1.0).opacity(0.20 * edgeAberrationOpacity), lineWidth: 2)
                    .frame(width: diameter * 1.005, height: diameter * 1.005)
                    .position(x: centerX + edgeOffset, y: centerY)

                Circle()
                    .stroke(reticleColor.opacity(0.92), lineWidth: 2)
                    .frame(width: diameter, height: diameter)
                    .position(x: centerX, y: centerY)

                Circle()
                    .stroke(reticleColor.opacity(0.35), lineWidth: 1)
                    .frame(width: diameter * 0.64, height: diameter * 0.64)
                    .position(x: centerX, y: centerY)

                Circle()
                    .stroke(reticleColor.opacity(0.22), lineWidth: 1)
                    .frame(width: bloomDiameter, height: bloomDiameter)
                    .position(x: reticleCenterX, y: reticleCenterY)

                ForEach(Self.lensDust, id: \.id) { dust in
                    Circle()
                        .fill(Color.white.opacity(dust.opacity * lensDirtOpacity))
                        .frame(width: diameter * dust.size, height: diameter * dust.size)
                        .blur(radius: diameter * dust.blur)
                        .position(
                            x: centerX + (diameter * dust.x),
                            y: centerY + (diameter * dust.y)
                        )
                }

                if muzzleFlashStrength > 0.01 {
                    Ellipse()
                        .fill(Color(red: 1.0, green: 0.78, blue: 0.38).opacity(0.72 * muzzleFlashStrength))
                        .frame(width: flashWidth, height: flashHeight)
                        .blur(radius: 1.8)
                        .position(x: centerX, y: apertureRect.maxY - (diameter * 0.18))

                    Ellipse()
                        .stroke(Color.white.opacity(0.68 * muzzleFlashStrength), lineWidth: 1.4)
                        .frame(width: flashWidth * 0.58, height: flashHeight * 0.42)
                        .position(x: centerX, y: apertureRect.maxY - (diameter * 0.18))
                }

                reticleArm(length: armLength, thickness: armThickness)
                    .position(x: reticleCenterX - ((centerGap + armLength) * 0.5), y: reticleCenterY)

                reticleArm(length: armLength, thickness: armThickness)
                    .position(x: reticleCenterX + ((centerGap + armLength) * 0.5), y: reticleCenterY)

                reticleArm(length: armLength, thickness: armThickness)
                    .rotationEffect(.degrees(90))
                    .position(x: reticleCenterX, y: reticleCenterY - ((centerGap + armLength) * 0.5))

                reticleArm(length: armLength, thickness: armThickness)
                    .rotationEffect(.degrees(90))
                    .position(x: reticleCenterX, y: reticleCenterY + ((centerGap + armLength) * 0.5))

                Circle()
                    .fill(reticleColor.opacity(0.96))
                    .frame(width: 6, height: 6)
                    .position(x: reticleCenterX, y: reticleCenterY)

                ForEach([-3, -2, -1, 1, 2, 3], id: \.self) { tick in
                    let tickOffset = CGFloat(tick) * centerGap * 0.72
                    let tickSize: CGFloat = abs(tick) == 3 ? 3 : 4
                    Circle()
                        .fill(reticleColor.opacity(abs(tick) == 3 ? 0.56 : 0.82))
                        .frame(width: tickSize, height: tickSize)
                        .position(x: reticleCenterX + tickOffset, y: reticleCenterY)

                    Circle()
                        .fill(reticleColor.opacity(abs(tick) == 3 ? 0.56 : 0.82))
                        .frame(width: tickSize, height: tickSize)
                        .position(x: reticleCenterX, y: reticleCenterY + tickOffset)
                }

                HStack(spacing: 10) {
                    SDFText(text: milDotSpacingText, size: 9, color: reticleColor.opacity(0.78))
                    SDFText(text: "PAR \(parallaxCompensationPercent)%", size: 9, color: reticleColor.opacity(0.78))
                }
                .position(x: reticleCenterX, y: reticleCenterY + (centerGap * 3.65))

                VStack(spacing: 5) {
                    SDFText(text: statusText, size: 12, weight: .semibold, color: .white.opacity(0.96))

                    SDFText(text: instructionText, size: 11, color: reticleColor.opacity(0.94))

                    SDFText(text: presentationText, size: 10, color: .white.opacity(0.86))

                    SDFText(text: shotTimingText, size: 10, color: reticleColor.opacity(0.82))

                    SDFText(text: shotFeedbackText, size: 10, color: .white.opacity(0.82))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
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

    private struct LensDust: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: CGFloat
        let blur: CGFloat
    }

    private static let lensDust: [LensDust] = [
        LensDust(id: 0, x: -0.24, y: -0.19, size: 0.014, opacity: 0.20, blur: 0.0018),
        LensDust(id: 1, x: -0.11, y: 0.23, size: 0.020, opacity: 0.16, blur: 0.0024),
        LensDust(id: 2, x: 0.18, y: -0.28, size: 0.012, opacity: 0.22, blur: 0.0016),
        LensDust(id: 3, x: 0.30, y: 0.12, size: 0.026, opacity: 0.13, blur: 0.0030),
        LensDust(id: 4, x: -0.33, y: 0.05, size: 0.010, opacity: 0.24, blur: 0.0014),
        LensDust(id: 5, x: 0.04, y: -0.35, size: 0.018, opacity: 0.14, blur: 0.0028),
    ]
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
