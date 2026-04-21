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
                overlayCard(
                    title: "Input Map",
                    subtitle: session.inputCardSubtitle,
                    lines: InputBindings.launchHints
                )
            }
            .padding(16)
            .opacity(session.hudCardOpacity)

            if session.isScopeActive && session.menuPanel == nil {
                scopeOverlay
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            if let panel = session.menuPanel {
                menuShell(for: panel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(28)
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
