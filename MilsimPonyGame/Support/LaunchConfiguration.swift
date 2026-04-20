import Foundation

struct LaunchConfiguration {
    let bootMode: String
    let worldName: String
    let assetRoot: String
    let worldDataRoot: String
    let worldManifestPath: String

    static var current: LaunchConfiguration {
        let environment = ProcessInfo.processInfo.environment
        let resolvedAssetRoot = resolvedPath(from: environment["MILSIM_PONY_ASSET_ROOT"] ?? WorldBootstrap.primaryAssetRoot)
        let resolvedWorldDataRoot: String

        if let configuredWorldDataRoot = environment["MILSIM_PONY_WORLD_DATA_ROOT"] {
            resolvedWorldDataRoot = resolvedPath(from: configuredWorldDataRoot)
        } else {
            resolvedWorldDataRoot = URL(fileURLWithPath: resolvedAssetRoot)
                .deletingLastPathComponent()
                .appendingPathComponent(WorldBootstrap.worldDataFolderName, isDirectory: true)
                .path
        }

        let resolvedWorldManifestPath: String
        if let configuredManifestPath = environment["MILSIM_PONY_WORLD_MANIFEST"] {
            resolvedWorldManifestPath = resolvedPath(from: configuredManifestPath)
        } else {
            resolvedWorldManifestPath = URL(fileURLWithPath: resolvedWorldDataRoot)
                .appendingPathComponent(WorldBootstrap.worldManifestRelativePath)
                .path
        }

        return LaunchConfiguration(
            bootMode: environment["MILSIM_PONY_BOOT_MODE"] ?? "bootstrap",
            worldName: environment["MILSIM_PONY_START_WORLD"] ?? WorldBootstrap.startingDistrict,
            assetRoot: resolvedAssetRoot,
            worldDataRoot: resolvedWorldDataRoot,
            worldManifestPath: resolvedWorldManifestPath
        )
    }

    private static func resolvedPath(from configuredPath: String) -> String {
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
