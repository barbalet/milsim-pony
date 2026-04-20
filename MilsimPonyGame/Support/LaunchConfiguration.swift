import Foundation

struct LaunchConfiguration {
    let bootMode: String
    let worldName: String
    let assetRoot: String

    static var current: LaunchConfiguration {
        let environment = ProcessInfo.processInfo.environment
        let configuredAssetRoot = environment["MILSIM_PONY_ASSET_ROOT"] ?? WorldBootstrap.primaryAssetRoot

        return LaunchConfiguration(
            bootMode: environment["MILSIM_PONY_BOOT_MODE"] ?? "bootstrap",
            worldName: environment["MILSIM_PONY_START_WORLD"] ?? WorldBootstrap.startingDistrict,
            assetRoot: resolvedAssetRoot(from: configuredAssetRoot)
        )
    }

    private static func resolvedAssetRoot(from configuredPath: String) -> String {
        let fileManager = FileManager.default
        let candidatePaths = [configuredPath, configuredPath.replacingOccurrences(of: "MilsimPonyGame/", with: "")]

        for candidatePath in candidatePaths where candidatePath.hasPrefix("/") && fileManager.fileExists(atPath: candidatePath) {
            return candidatePath
        }

        for candidatePath in candidatePaths {
            let currentDirectoryCandidate = URL(fileURLWithPath: fileManager.currentDirectoryPath)
                .appendingPathComponent(candidatePath, isDirectory: true)
            if fileManager.fileExists(atPath: currentDirectoryCandidate.path) {
                return currentDirectoryCandidate.path
            }

            if
                let resourceURL = Bundle.main.resourceURL?.appendingPathComponent(candidatePath, isDirectory: true),
                fileManager.fileExists(atPath: resourceURL.path)
            {
                return resourceURL.path
            }
        }

        return configuredPath
    }
}
