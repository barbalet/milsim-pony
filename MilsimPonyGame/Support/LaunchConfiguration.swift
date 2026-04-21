import Foundation

struct LaunchConfiguration {
    let bootMode: String
    let worldName: String
    let assetRoot: String
    let assetSource: String
    let worldDataRoot: String
    let worldDataSource: String
    let worldManifestPath: String
    let worldManifestSource: String
    let marketingVersion: String
    let buildNumber: String
    let bundleIdentifier: String

    var releaseDisplayName: String {
        "v\(marketingVersion) (\(buildNumber))"
    }

    var contentSourceSummary: String {
        if assetSource == worldManifestSource {
            return assetSource
        }

        return "\(assetSource) assets / \(worldManifestSource) manifest"
    }

    static var current: LaunchConfiguration {
        let environment = ProcessInfo.processInfo.environment
        let fileManager = FileManager.default
        let currentDirectoryPath = fileManager.currentDirectoryPath
        let bundledResourceRoot = Bundle.main.resourceURL?.path
        let configuredAssetRoot = environment["MILSIM_PONY_ASSET_ROOT"] ?? WorldBootstrap.primaryAssetRoot
        let resolvedAssetRoot = resolvedPath(from: configuredAssetRoot)
        let assetSource = sourceDescription(
            for: resolvedAssetRoot,
            currentDirectoryPath: currentDirectoryPath,
            bundledResourceRoot: bundledResourceRoot,
            overrideRequested: environment["MILSIM_PONY_ASSET_ROOT"] != nil
        )
        let resolvedWorldDataRoot: String
        let worldDataSource: String

        if let configuredWorldDataRoot = environment["MILSIM_PONY_WORLD_DATA_ROOT"] {
            resolvedWorldDataRoot = resolvedPath(from: configuredWorldDataRoot)
            worldDataSource = sourceDescription(
                for: resolvedWorldDataRoot,
                currentDirectoryPath: currentDirectoryPath,
                bundledResourceRoot: bundledResourceRoot,
                overrideRequested: true
            )
        } else {
            resolvedWorldDataRoot = URL(fileURLWithPath: resolvedAssetRoot)
                .deletingLastPathComponent()
                .appendingPathComponent(WorldBootstrap.worldDataFolderName, isDirectory: true)
                .path
            worldDataSource = sourceDescription(
                for: resolvedWorldDataRoot,
                currentDirectoryPath: currentDirectoryPath,
                bundledResourceRoot: bundledResourceRoot,
                overrideRequested: false
            )
        }

        let resolvedWorldManifestPath: String
        let worldManifestSource: String
        if let configuredManifestPath = environment["MILSIM_PONY_WORLD_MANIFEST"] {
            resolvedWorldManifestPath = resolvedPath(from: configuredManifestPath)
            worldManifestSource = sourceDescription(
                for: resolvedWorldManifestPath,
                currentDirectoryPath: currentDirectoryPath,
                bundledResourceRoot: bundledResourceRoot,
                overrideRequested: true
            )
        } else {
            resolvedWorldManifestPath = URL(fileURLWithPath: resolvedWorldDataRoot)
                .appendingPathComponent(WorldBootstrap.worldManifestRelativePath)
                .path
            worldManifestSource = sourceDescription(
                for: resolvedWorldManifestPath,
                currentDirectoryPath: currentDirectoryPath,
                bundledResourceRoot: bundledResourceRoot,
                overrideRequested: false
            )
        }

        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.milsimpony.game"
        let marketingVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "0"
        let manifestWorldName = defaultWorldName(from: resolvedWorldManifestPath)

        return LaunchConfiguration(
            bootMode: environment["MILSIM_PONY_BOOT_MODE"] ?? "bootstrap",
            worldName: environment["MILSIM_PONY_START_WORLD"] ?? manifestWorldName ?? WorldBootstrap.startingDistrict,
            assetRoot: resolvedAssetRoot,
            assetSource: assetSource,
            worldDataRoot: resolvedWorldDataRoot,
            worldDataSource: worldDataSource,
            worldManifestPath: resolvedWorldManifestPath,
            worldManifestSource: worldManifestSource,
            marketingVersion: marketingVersion,
            buildNumber: buildNumber,
            bundleIdentifier: bundleIdentifier
        )
    }

    private static func resolvedPath(from configuredPath: String) -> String {
        let fileManager = FileManager.default
        let candidatePaths = [configuredPath, configuredPath.replacingOccurrences(of: "MilsimPonyGame/", with: "")]

        for candidatePath in candidatePaths where candidatePath.hasPrefix("/") && fileManager.fileExists(atPath: candidatePath) {
            return candidatePath
        }

        for candidatePath in candidatePaths {
            if
                let resourceURL = Bundle.main.resourceURL?.appendingPathComponent(candidatePath, isDirectory: true),
                fileManager.fileExists(atPath: resourceURL.path)
            {
                return resourceURL.path
            }
        }

        for candidatePath in candidatePaths {
            let currentDirectoryCandidate = URL(fileURLWithPath: fileManager.currentDirectoryPath)
                .appendingPathComponent(candidatePath, isDirectory: true)
            if fileManager.fileExists(atPath: currentDirectoryCandidate.path) {
                return currentDirectoryCandidate.path
            }
        }

        return configuredPath
    }

    private static func sourceDescription(
        for path: String,
        currentDirectoryPath: String,
        bundledResourceRoot: String?,
        overrideRequested: Bool
    ) -> String {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: path) else {
            return overrideRequested ? "unresolved override" : "unresolved"
        }

        if let bundledResourceRoot, path.hasPrefix(bundledResourceRoot) {
            return overrideRequested ? "bundled override" : "bundled"
        }

        if path.hasPrefix(currentDirectoryPath) {
            return overrideRequested ? "workspace override" : "workspace"
        }

        return overrideRequested ? "custom override" : "external"
    }

    private static func defaultWorldName(from manifestPath: String) -> String? {
        let manifestURL = URL(fileURLWithPath: manifestPath)

        guard let data = try? Data(contentsOf: manifestURL) else {
            return nil
        }

        return try? JSONDecoder().decode(WorldManifest.self, from: data).worldName
    }
}
