import Foundation

enum InputCommand: String, CaseIterable, Hashable {
    case forward
    case backward
    case strafeLeft
    case strafeRight
    case sprint
    case steadyAim
    case fire
    case interact
    case toggleMap
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
        case .steadyAim:
            return "Steady Aim"
        case .fire:
            return "Fire"
        case .interact:
            return "Interact"
        case .toggleMap:
            return "Canberra Map"
        case .restart:
            return "Restart Route"
        case .pause:
            return "Pause"
        }
    }

    var isContinuous: Bool {
        switch self {
        case .forward, .backward, .strafeLeft, .strafeRight, .sprint, .steadyAim:
            return true
        case .fire, .interact, .toggleMap, .restart, .pause:
            return false
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
        14: .steadyAim,
        3: .fire,
        49: .interact,
        36: .interact,
        76: .interact,
        46: .toggleMap,
        15: .restart,
        53: .pause,
    ]

    private static let characterMap: [String: InputCommand] = [
        "w": .forward,
        "s": .backward,
        "a": .strafeLeft,
        "d": .strafeRight,
        "f": .fire,
        "e": .steadyAim,
        "m": .toggleMap,
        "r": .restart,
        " ": .interact,
    ]

    static let launchHints: [String] = [
        "W A S D: grounded movement",
        "Shift: sprint",
        "E: steady scoped aim and hold breath",
        "Mouse move: look",
        "Click / F: fire the current rifle cue",
        "Space / Return: deploy, confirm, or toggle 4x scope",
        "M: toggle the Canberra map",
        "R: restart or retry from last checkpoint",
        "Esc: pause or resume the demo shell",
    ]

    static func command(for keyCode: UInt16, characters: String?) -> InputCommand? {
        if let normalizedCharacters = characters?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(),
           !normalizedCharacters.isEmpty,
           let characterCommand = characterMap[normalizedCharacters] {
            return characterCommand
        }

        return keyCodeMap[keyCode]
    }
}
