import Foundation

enum InputCommand: String, CaseIterable, Hashable {
    case forward
    case backward
    case strafeLeft
    case strafeRight
    case sprint
    case interact
    case restart
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
        case .restart:
            return "Restart Route"
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
        36: .interact,
        76: .interact,
        15: .restart,
        53: .pause,
    ]

    static let launchHints: [String] = [
        "W A S D: grounded movement",
        "Shift: sprint",
        "Mouse move: look",
        "Space / Return: deploy, confirm, or toggle 4x scope",
        "R: restart or retry from last checkpoint",
        "Esc: pause or resume the demo shell",
    ]

    static func command(for keyCode: UInt16) -> InputCommand? {
        keyCodeMap[keyCode]
    }
}
