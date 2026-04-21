import SwiftUI

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

            VStack(alignment: .leading, spacing: 14) {
                overlayCard(
                    title: session.overlayTitle,
                    subtitle: session.statusLine,
                    lines: session.overlayLines
                )
                controlsWindow
            }
            .padding(16)
            .opacity(session.hudCardOpacity)
            .zIndex(1)

            if session.isScopeActive && session.menuPanel == nil {
                scopeOverlay
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .zIndex(2)
            }

            if let panel = session.menuPanel {
                menuShell(for: panel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(28)
                    .zIndex(3)
            }

            if session.isMapPresented, let mapSnapshot = session.overheadMapSnapshot {
                mapShell(snapshot: mapSnapshot)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(28)
                    .allowsHitTesting(false)
                    .zIndex(4)
            }
        }
        .frame(minWidth: 960, minHeight: 600)
        .background(Color.black)
    }

    private func menuShell(for panel: GameMenuPanel) -> some View {
        VStack(spacing: 18) {
            shellCard(
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
                    settingsControls
                }

                actionStack(for: panel)
            }
        }
    }

    private var scopeOverlay: some View {
        ScopeOverlay(
            statusText: session.scopeStatusText,
            instructionText: session.scopeInstructionText,
            reticleColor: Color(nsColor: session.scopeReticleColor)
        )
    }

    private var controlsWindow: some View {
        shellCard(
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
    }

    private func overheadMapOverlay(snapshot: OverheadMapSnapshot, layout: CanberraMapLayout) -> some View {
        shellCard(
            title: "Canberra Map",
            subtitle: snapshot.nextCheckpointLabel.map {
                "Sector: \(snapshot.currentSectorName) • next marker: \($0)"
            } ?? "Sector: \(snapshot.currentSectorName) • route complete",
            maxWidth: layout.cardWidth
        ) {
            OverheadMapCanvas(
                snapshot: snapshot,
                canvasHeight: layout.canvasHeight
            )
                .frame(maxWidth: .infinity)
        }
        .frame(width: layout.cardWidth, alignment: .leading)
    }

    private func mapShell(snapshot: OverheadMapSnapshot) -> some View {
        GeometryReader { geometry in
            let layout = CanberraMapLayout.fitting(in: geometry.size)

            VStack(spacing: 18) {
                overheadMapOverlay(snapshot: snapshot, layout: layout)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var settingsControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(String(format: "Look Sensitivity %.2fx", session.lookSensitivityScale))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.92))
                Slider(
                    value: Binding(
                        get: { session.lookSensitivityScale },
                        set: { session.setLookSensitivityScale($0) }
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
                        set: { session.setHUDOpacity($0) }
                    ),
                    in: 0.35...1.0,
                    step: 0.05
                )
                .tint(Color(red: 0.34, green: 0.74, blue: 0.96))
            }

            Toggle(
                isOn: Binding(
                    get: { session.invertLookY },
                    set: { session.setInvertLookY($0) }
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
                    set: { session.setMapPresented($0) }
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

    @ViewBuilder
    private func actionStack(for panel: GameMenuPanel) -> some View {
        VStack(spacing: 10) {
            switch panel {
            case .title:
                actionButton(session.canBeginMission ? "Start Demo" : "Loading Scene...") {
                    session.startDemo()
                }
                .disabled(!session.canBeginMission)

                actionButton("Settings") {
                    session.openSettings()
                }

            case .paused:
                actionButton("Resume") {
                    session.resumeDemo()
                }

                actionButton("Restart Run") {
                    session.restartMission()
                }

                actionButton("Settings") {
                    session.openSettings()
                }

                actionButton("Return To Briefing") {
                    session.returnToBriefing()
                }

            case .failed:
                actionButton("Retry Checkpoint") {
                    session.retryFromCheckpoint()
                }

                actionButton("Restart Run") {
                    session.restartMission()
                }

                actionButton("Return To Briefing") {
                    session.returnToBriefing()
                }

            case .complete:
                actionButton("New Run") {
                    session.restartMission()
                }

                actionButton("Settings") {
                    session.openSettings()
                }

                actionButton("Return To Briefing") {
                    session.returnToBriefing()
                }

            case .settings:
                actionButton("Back") {
                    session.closeSettings()
                }
            }
        }
        .padding(.top, 6)
    }

    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
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

    private func overlayCard(title: String, subtitle: String, lines: [String]) -> some View {
        shellCard(title: title, subtitle: subtitle, maxWidth: 420) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func shellCard<Content: View>(
        title: String,
        subtitle: String,
        maxWidth: CGFloat = 520,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.76))

            content()
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

                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(red: 0.07, green: 0.10, blue: 0.12))

                    Path { path in
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
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)

                    ForEach(snapshot.configuration.sectors) { sector in
                        let sectorRect = rect(for: sector, in: drawingRect)

                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(sectorFill(for: sector))
                            .frame(width: sectorRect.width, height: sectorRect.height)
                            .position(x: sectorRect.midX, y: sectorRect.midY)

                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(sectorStroke(for: sector), lineWidth: sector.displayName == snapshot.currentSectorName ? 1.6 : 1)
                            .frame(width: sectorRect.width, height: sectorRect.height)
                            .position(x: sectorRect.midX, y: sectorRect.midY)

                        if sectorRect.width > 70, sectorRect.height > 24 {
                            Text(sector.shortLabel)
                                .font(.system(size: min(9 * canvasScale, 20), weight: .semibold, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.72))
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                                .frame(width: max(sectorRect.width - (12 * canvasScale), 24))
                                .position(x: sectorRect.midX, y: sectorRect.midY)
                        }
                    }

                    ForEach(snapshot.configuration.roads) { road in
                        let startPoint = point(forX: road.startPoint.x, z: road.startPoint.z, in: drawingRect)
                        let endPoint = point(forX: road.endPoint.x, z: road.endPoint.z, in: drawingRect)
                        let midpoint = CGPoint(
                            x: (startPoint.x + endPoint.x) * 0.5,
                            y: (startPoint.y + endPoint.y) * 0.5
                        )

                        Path { path in
                            path.move(to: startPoint)
                            path.addLine(to: endPoint)
                        }
                        .stroke(
                            Color(red: 0.84, green: 0.86, blue: 0.90).opacity(0.84),
                            style: StrokeStyle(
                                lineWidth: roadLineWidth(for: road, in: drawingRect),
                                lineCap: .round
                            )
                        )

                        let labelWidth = hypot(endPoint.x - startPoint.x, endPoint.y - startPoint.y)
                        if labelWidth > 80 {
                            Text(road.shortLabel)
                                .font(.system(size: min(8 * canvasScale, 18), weight: .bold, design: .monospaced))
                                .foregroundStyle(Color(red: 0.95, green: 0.95, blue: 0.97).opacity(0.86))
                                .lineLimit(1)
                                .minimumScaleFactor(0.55)
                                .frame(width: max(labelWidth - (10 * canvasScale), 40))
                                .padding(.horizontal, max(5 * canvasScale, 5))
                                .padding(.vertical, max(2 * canvasScale, 2))
                                .background(Color.black.opacity(0.54), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                                .rotationEffect(.degrees(Double(-road.yawDegrees)))
                                .position(midpoint)
                        }
                    }

                    Path { path in
                        guard let first = snapshot.configuration.checkpoints.first else {
                            return
                        }

                        path.move(to: point(forX: first.point.x, z: first.point.z, in: drawingRect))
                        for checkpoint in snapshot.configuration.checkpoints.dropFirst() {
                            path.addLine(to: point(forX: checkpoint.point.x, z: checkpoint.point.z, in: drawingRect))
                        }
                    }
                    .stroke(
                        Color(red: 0.94, green: 0.84, blue: 0.40).opacity(0.72),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round, dash: [6, 4])
                    )

                    let spawnPoint = point(
                        forX: snapshot.configuration.spawnPoint.x,
                        z: snapshot.configuration.spawnPoint.z,
                        in: drawingRect
                    )

                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color.white.opacity(0.92))
                        .frame(width: 10 * markerScale, height: 10 * markerScale)
                        .position(spawnPoint)

                    ForEach(Array(snapshot.configuration.checkpoints.enumerated()), id: \.element.id) { index, checkpoint in
                        let checkpointPoint = point(
                            forX: checkpoint.point.x,
                            z: checkpoint.point.z,
                            in: drawingRect
                        )

                        Circle()
                            .fill(checkpointColor(for: checkpoint, index: index))
                            .frame(width: checkpointSize(for: index), height: checkpointSize(for: index))
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.28), lineWidth: 1)
                            )
                            .position(checkpointPoint)
                    }

                    let playerPoint = point(forX: snapshot.playerX, z: snapshot.playerZ, in: drawingRect)
                    let headingLength: Float = 20
                    let headingPoint = point(
                        forX: snapshot.playerX + (snapshot.headingX * headingLength),
                        z: snapshot.playerZ + (snapshot.headingZ * headingLength),
                        in: drawingRect
                    )

                    Path { path in
                        path.move(to: playerPoint)
                        path.addLine(to: headingPoint)
                    }
                    .stroke(Color(red: 0.34, green: 0.82, blue: 0.98), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

                    Circle()
                        .fill(Color(red: 0.34, green: 0.82, blue: 0.98))
                        .frame(width: 11 * markerScale, height: 11 * markerScale)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.78), lineWidth: 1)
                        )
                        .position(playerPoint)

                    Circle()
                        .fill(Color(red: 0.34, green: 0.82, blue: 0.98).opacity(0.82))
                        .frame(width: 7 * markerScale, height: 7 * markerScale)
                        .position(headingPoint)

                    Text("N")
                        .font(.system(size: min(10 * canvasScale, 20), weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.82))
                        .position(x: drawingRect.midX, y: drawingRect.minY + max(8 * canvasScale, 8))
                }
            }
            .frame(height: canvasHeight)

            HStack(spacing: 12) {
                legendItem(color: .white.opacity(0.92), label: "Spawn")
                legendItem(color: Color(red: 0.84, green: 0.86, blue: 0.90), label: "Roads")
                legendItem(color: Color(red: 0.94, green: 0.84, blue: 0.40), label: "Route")
                legendItem(color: Color(red: 0.34, green: 0.82, blue: 0.98), label: "You")
            }

            Text("Route: \(snapshot.completedCheckpointCount) / \(snapshot.totalCheckpointCount) checkpoints\(snapshot.nextCheckpointLabel.map { " • next \($0)" } ?? " • route complete")")
                .font(.system(size: min(10 * canvasScale, 15), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.72))
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

    private func sectorFill(for sector: SceneMapSector) -> Color {
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

    private func sectorStroke(for sector: SceneMapSector) -> Color {
        sector.displayName == snapshot.currentSectorName
            ? Color(red: 0.94, green: 0.86, blue: 0.44).opacity(0.92)
            : Color.white.opacity(0.12)
    }

    private func checkpointColor(for checkpoint: SceneMapCheckpoint, index: Int) -> Color {
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

    private func checkpointSize(for index: Int) -> CGFloat {
        (index == snapshot.completedCheckpointCount ? 11 : 9) * markerScale
    }

    private func roadLineWidth(for road: SceneMapRoad, in drawingRect: CGRect) -> CGFloat {
        let averageScale = (drawingRect.width / CGFloat(snapshot.configuration.width)
            + drawingRect.height / CGFloat(snapshot.configuration.depth)) * 0.5
        let rawWidth = CGFloat(road.width) * averageScale
        let maxWidth = max(3.4 * markerScale, 1.4)
        return min(max(rawWidth, 1.4), maxWidth)
    }

    private func rect(for sector: SceneMapSector, in drawingRect: CGRect) -> CGRect {
        let topLeft = point(forX: sector.minX, z: sector.minZ, in: drawingRect)
        let bottomRight = point(forX: sector.maxX, z: sector.maxZ, in: drawingRect)
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

    private func point(forX x: Float, z: Float, in drawingRect: CGRect) -> CGPoint {
        let normalizedX = CGFloat((x - snapshot.configuration.minX) / snapshot.configuration.width)
        let normalizedY = CGFloat((snapshot.configuration.maxZ - z) / snapshot.configuration.depth)

        return CGPoint(
            x: drawingRect.minX + (drawingRect.width * normalizedX),
            y: drawingRect.minY + (drawingRect.height * normalizedY)
        )
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
