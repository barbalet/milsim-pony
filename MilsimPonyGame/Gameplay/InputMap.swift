import Foundation

enum InputCommand: String, CaseIterable, Hashable {
    case forward
    case backward
    case strafeLeft
    case strafeRight
    case sprint
    case interact
    case pause

    var label: String {
        switch self {
        case .forward:
            return "Forward"
        case .backward:
            return "Backward"
        case .strafeLeft:
            return "Strafe Left"
        case .strafeRight:
            return "Strafe Right"
        case .sprint:
            return "Sprint"
        case .interact:
            return "Interact"
        case .pause:
            return "Pause"
        }
    }
}

enum InputBindings {
    private static let keyCodeMap: [UInt16: InputCommand] = [
        13: .forward,
        1: .backward,
        0: .strafeLeft,
        2: .strafeRight,
        56: .sprint,
        60: .sprint,
        49: .interact,
        53: .pause,
    ]

    static let launchHints: [String] = [
        "W A S D: movement intent hooks",
        "Shift: sprint toggle hook",
        "Mouse move: look delta hook",
        "Space: interact placeholder",
        "Esc: pause placeholder",
    ]

    static func command(for keyCode: UInt16) -> InputCommand? {
        keyCodeMap[keyCode]
    }
}
