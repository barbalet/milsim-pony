import SwiftUI

struct GameRootView: View {
    @ObservedObject var session: GameSession

    var body: some View {
        ZStack(alignment: .topLeading) {
            MetalGameView(session: session)
                .background(Color.black)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                overlayCard(
                    title: "Cycle 4 Escape Slice",
                    subtitle: session.statusLine,
                    lines: session.overlayLines
                )
                overlayCard(
                    title: "Input Map",
                    subtitle: "Checkpoint route and grounded traversal controls",
                    lines: InputBindings.launchHints
                )
            }
            .padding(16)
        }
        .frame(minWidth: 960, minHeight: 600)
        .background(Color.black)
    }

    private func overlayCard(title: String, subtitle: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.75))

            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .padding(14)
        .frame(maxWidth: 420, alignment: .leading)
        .background(.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}
