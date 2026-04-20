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
