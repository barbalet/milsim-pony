import SwiftUI

@main
struct MilsimPonyGameApp: App {
    @StateObject private var session = GameSession(configuration: .current)

    var body: some Scene {
        WindowGroup {
            GameRootView(session: session)
        }
        .commands {
            AuxiliaryWindowCommands(session: session)
        }

        Window("Mission Overlay", id: AuxiliaryWindowID.overlay.rawValue) {
            MissionOverlayWindow(session: session)
        }
        .defaultSize(width: 460, height: 760)

        Window("Control Deck", id: AuxiliaryWindowID.controls.rawValue) {
            ControlDeckWindow(session: session)
        }
        .defaultSize(width: 470, height: 330)

        Window("Menu Shell", id: AuxiliaryWindowID.menu.rawValue) {
            MenuPanelWindow(session: session)
        }
        .defaultSize(width: 620, height: 560)

        Window("Canberra Map", id: AuxiliaryWindowID.map.rawValue) {
            CanberraMapWindow(session: session)
        }
        .defaultSize(width: 1040, height: 840)
    }
}
