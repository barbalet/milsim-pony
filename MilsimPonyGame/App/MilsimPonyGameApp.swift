import SwiftUI

@main
struct MilsimPonyGameApp: App {
    @StateObject private var session = GameSession(configuration: .current)

    var body: some Scene {
        WindowGroup {
            GameRootView(session: session)
        }
    }
}
