import AppKit
import AVFoundation
import Combine
import Foundation
import simd

enum DemoFlowState: String {
    case title
    case playing
    case paused
    case failed
    case complete

    var label: String {
        switch self {
        case .title:
            return "briefing"
        case .playing:
            return "live"
        case .paused:
            return "paused"
        case .failed:
            return "compromised"
        case .complete:
            return "complete"
        }
    }
}

enum GameMenuPanel: Equatable {
    case title
    case paused
    case failed
    case complete
    case settings
}

enum RehearsalDifficultyPreset: String, CaseIterable, Identifiable {
    case relaxed
    case baseline
    case pressure
    case brutal

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .relaxed:
            return "Relaxed"
        case .baseline:
            return "Baseline"
        case .pressure:
            return "Pressure"
        case .brutal:
            return "Brutal"
        }
    }

    var summary: String {
        switch self {
        case .relaxed:
            return "Higher fail margin, quicker recovery, and a slightly faster rifle cycle."
        case .baseline:
            return "Authored observer pressure and rifle cadence for the current rehearsal lane."
        case .pressure:
            return "Sharpened suspicion gain, slower recovery, and a tighter failure window."
        case .brutal:
            return "Aggressive observer pressure with a short fail margin and the slowest rifle cycle."
        }
    }

    var observerSuspicionScale: Float {
        switch self {
        case .relaxed:
            return 0.72
        case .baseline:
            return 1.0
        case .pressure:
            return 1.16
        case .brutal:
            return 1.34
        }
    }

    var suspicionDecayScale: Float {
        switch self {
        case .relaxed:
            return 1.32
        case .baseline:
            return 1.0
        case .pressure:
            return 0.86
        case .brutal:
            return 0.72
        }
    }

    var failThresholdScale: Float {
        switch self {
        case .relaxed:
            return 1.24
        case .baseline:
            return 1.0
        case .pressure:
            return 0.90
        case .brutal:
            return 0.78
        }
    }

    var weaponCycleScale: Float {
        switch self {
        case .relaxed:
            return 0.90
        case .baseline:
            return 1.0
        case .pressure:
            return 1.08
        case .brutal:
            return 1.18
        }
    }

    var coreTuning: GameDifficultyTuning {
        var tuning = GameDifficultyTuning()
        tuning.observerSuspicionScale = observerSuspicionScale
        tuning.suspicionDecayScale = suspicionDecayScale
        tuning.failThresholdScale = failThresholdScale
        tuning.weaponCycleScale = weaponCycleScale
        return tuning
    }
}

private struct StoredSessionSettings {
    let hudOpacity: Double
    let invertLookY: Bool
    let lookSensitivityScale: Double
    let difficultyPreset: RehearsalDifficultyPreset
}

private struct StoredReviewSessionState: Codable, Equatable {
    let schemaVersion: Int
    let sceneLabel: String
    let routeSummary: String
    let completedCheckpointCount: Int
    let totalCheckpointCount: Int
    let nextCheckpointLabel: String?
    let currentSectorName: String
    let difficultyPreset: String
    let flowState: String
    let mapPresented: Bool
    let scopeActive: Bool
    let routeComplete: Bool
    let routeFailed: Bool
    let reviewPackageLine: String
    let savedAt: TimeInterval

    init(
        schemaVersion: Int,
        sceneLabel: String,
        routeSummary: String,
        completedCheckpointCount: Int,
        totalCheckpointCount: Int,
        nextCheckpointLabel: String?,
        currentSectorName: String,
        difficultyPreset: String,
        flowState: String,
        mapPresented: Bool,
        scopeActive: Bool,
        routeComplete: Bool,
        routeFailed: Bool,
        reviewPackageLine: String,
        savedAt: TimeInterval
    ) {
        self.schemaVersion = schemaVersion
        self.sceneLabel = sceneLabel
        self.routeSummary = routeSummary
        self.completedCheckpointCount = completedCheckpointCount
        self.totalCheckpointCount = totalCheckpointCount
        self.nextCheckpointLabel = nextCheckpointLabel
        self.currentSectorName = currentSectorName
        self.difficultyPreset = difficultyPreset
        self.flowState = flowState
        self.mapPresented = mapPresented
        self.scopeActive = scopeActive
        self.routeComplete = routeComplete
        self.routeFailed = routeFailed
        self.reviewPackageLine = reviewPackageLine
        self.savedAt = savedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        sceneLabel = try container.decodeIfPresent(String.self, forKey: .sceneLabel) ?? "Unknown scene"
        routeSummary = try container.decodeIfPresent(String.self, forKey: .routeSummary) ?? "Route: unavailable"
        completedCheckpointCount = try container.decodeIfPresent(Int.self, forKey: .completedCheckpointCount) ?? 0
        totalCheckpointCount = try container.decodeIfPresent(Int.self, forKey: .totalCheckpointCount) ?? 0
        nextCheckpointLabel = try container.decodeIfPresent(String.self, forKey: .nextCheckpointLabel)
        currentSectorName = try container.decodeIfPresent(String.self, forKey: .currentSectorName) ?? "Unknown sector"
        difficultyPreset = try container.decodeIfPresent(String.self, forKey: .difficultyPreset) ?? "Baseline"
        flowState = try container.decodeIfPresent(String.self, forKey: .flowState) ?? "briefing"
        mapPresented = try container.decodeIfPresent(Bool.self, forKey: .mapPresented) ?? false
        scopeActive = try container.decodeIfPresent(Bool.self, forKey: .scopeActive) ?? false
        routeComplete = try container.decodeIfPresent(Bool.self, forKey: .routeComplete) ?? false
        routeFailed = try container.decodeIfPresent(Bool.self, forKey: .routeFailed) ?? false
        reviewPackageLine = try container.decodeIfPresent(String.self, forKey: .reviewPackageLine) ?? "review pack unavailable"
        savedAt = try container.decodeIfPresent(TimeInterval.self, forKey: .savedAt) ?? 0
    }

    var shellLine: String {
        let routeState = routeComplete ? "complete" : (routeFailed ? "compromised" : flowState)
        return "Last Session: \(completedCheckpointCount)/\(totalCheckpointCount) checkpoints / \(difficultyPreset) / \(currentSectorName) / \(routeState)"
    }

    var captureLine: String {
        let nextLabel = nextCheckpointLabel ?? "route complete"
        let mapState = mapPresented ? "map open" : "map hidden"
        let scopeState = scopeActive ? "scope raised" : "scope ready"
        return "Review Resume: next \(nextLabel) / \(reviewPackageLine) / \(mapState) / \(scopeState)"
    }

    var guardrailLine: String {
        if totalCheckpointCount <= 0 {
            return "Review Guardrail: stored route has no checkpoint count / fresh run required"
        }
        if completedCheckpointCount < 0 || completedCheckpointCount > totalCheckpointCount {
            return "Review Guardrail: stored checkpoint progress is out of range / fresh run required"
        }
        if !routeComplete && completedCheckpointCount < totalCheckpointCount && nextCheckpointLabel == nil {
            return "Review Guardrail: next checkpoint missing from stored review card / fresh run required"
        }

        return "Review Guardrail: stored review card valid / launch starts fresh until checkpoint restore exists"
    }

    var restorePreviewLine: String {
        if totalCheckpointCount <= 0
            || completedCheckpointCount < 0
            || completedCheckpointCount > totalCheckpointCount {
            return "Restore Preview: blocked by invalid stored checkpoint progress"
        }
        if routeComplete || completedCheckpointCount >= totalCheckpointCount {
            return "Restore Preview: route already complete / fresh briefing remains default"
        }
        guard let nextCheckpointLabel else {
            return "Restore Preview: blocked until next checkpoint context is captured"
        }

        return "Restore Preview: future resume target \(nextCheckpointLabel) / launch still starts fresh"
    }

    func restoreReadinessLine(currentSceneLabel: String, currentRouteSummary: String) -> String {
        if schemaVersion != 1 {
            return "Restore Readiness: blocked by stored schema v\(schemaVersion)"
        }
        if sceneLabel != currentSceneLabel {
            return "Restore Readiness: blocked by scene mismatch / stored \(sceneLabel)"
        }
        if routeSummary != currentRouteSummary {
            return "Restore Readiness: blocked by route summary mismatch"
        }
        if totalCheckpointCount <= 0
            || completedCheckpointCount < 0
            || completedCheckpointCount > totalCheckpointCount {
            return "Restore Readiness: blocked by invalid checkpoint progress"
        }
        if routeComplete || completedCheckpointCount >= totalCheckpointCount {
            return "Restore Readiness: complete run archived / fresh briefing remains default"
        }
        guard nextCheckpointLabel != nil else {
            return "Restore Readiness: blocked until next checkpoint target is captured"
        }

        return "Restore Readiness: eligible for future manual restore / launch still starts fresh"
    }

    func manualRestoreArmingLine(currentSceneLabel: String, currentRouteSummary: String) -> String {
        if schemaVersion != 1 {
            return "Manual Restore Arm: disabled / stored schema v\(schemaVersion) is unsupported"
        }
        if sceneLabel != currentSceneLabel {
            return "Manual Restore Arm: disabled / stored scene differs from current scene"
        }
        if routeSummary != currentRouteSummary {
            return "Manual Restore Arm: disabled / stored route differs from current route"
        }
        if totalCheckpointCount <= 0
            || completedCheckpointCount < 0
            || completedCheckpointCount > totalCheckpointCount {
            return "Manual Restore Arm: disabled / checkpoint progress failed validation"
        }
        if routeComplete || completedCheckpointCount >= totalCheckpointCount {
            return "Manual Restore Arm: disabled / stored run already complete"
        }
        guard let nextCheckpointLabel else {
            return "Manual Restore Arm: disabled / checkpoint target missing"
        }

        return "Manual Restore Arm: armed for future prompt at \(nextCheckpointLabel) / no auto-restore"
    }

    func manualRestorePromptLine(currentSceneLabel: String, currentRouteSummary: String) -> String {
        if schemaVersion != 1
            || sceneLabel != currentSceneLabel
            || routeSummary != currentRouteSummary {
            return "Manual Restore Prompt: hidden until stored run matches this scene and route"
        }
        if totalCheckpointCount <= 0
            || completedCheckpointCount < 0
            || completedCheckpointCount > totalCheckpointCount {
            return "Manual Restore Prompt: hidden until checkpoint progress validates"
        }
        if routeComplete || completedCheckpointCount >= totalCheckpointCount {
            return "Manual Restore Prompt: hidden for completed stored run"
        }
        guard let nextCheckpointLabel else {
            return "Manual Restore Prompt: hidden until a checkpoint target is captured"
        }

        return "Manual Restore Prompt: future choice Restore \(nextCheckpointLabel) or Start Fresh / start fresh locked"
    }

    func manualRestoreChoiceLine(currentSceneLabel: String, currentRouteSummary: String) -> String {
        if schemaVersion != 1
            || sceneLabel != currentSceneLabel
            || routeSummary != currentRouteSummary {
            return "Restore Choice: hidden / stored run identity not current"
        }
        if totalCheckpointCount <= 0
            || completedCheckpointCount < 0
            || completedCheckpointCount > totalCheckpointCount {
            return "Restore Choice: hidden / checkpoint progress invalid"
        }
        if routeComplete || completedCheckpointCount >= totalCheckpointCount {
            return "Restore Choice: hidden / completed run starts fresh"
        }
        guard let nextCheckpointLabel else {
            return "Restore Choice: hidden / checkpoint target missing"
        }

        return "Restore Choice: preview Restore \(nextCheckpointLabel) or Start Fresh / restore requires explicit execution"
    }

    func restoreChoiceTargetLabel(currentSceneLabel: String, currentRouteSummary: String) -> String? {
        let choiceLine = manualRestoreChoiceLine(
            currentSceneLabel: currentSceneLabel,
            currentRouteSummary: currentRouteSummary
        )
        guard choiceLine.hasPrefix("Restore Choice: preview Restore ") else {
            return nil
        }

        return nextCheckpointLabel
    }

    func manualRestoreSelectionLine(
        currentSceneLabel: String,
        currentRouteSummary: String,
        reviewedTargetLabel: String?
    ) -> String {
        guard let targetLabel = restoreChoiceTargetLabel(
            currentSceneLabel: currentSceneLabel,
            currentRouteSummary: currentRouteSummary
        ) else {
            return "Restore Selection: unavailable / Start Demo remains fresh"
        }

        guard reviewedTargetLabel == targetLabel else {
            return "Restore Selection: pending review for \(targetLabel) / Start Demo remains fresh default"
        }

        return "Restore Selection: reviewed \(targetLabel) / restore execution may be requested"
    }

    func restoreFreshStartGuardLine(
        currentSceneLabel: String,
        currentRouteSummary: String,
        reviewedTargetLabel: String?,
        freshStartTargetLabel: String?
    ) -> String {
        guard let targetLabel = restoreChoiceTargetLabel(
            currentSceneLabel: currentSceneLabel,
            currentRouteSummary: currentRouteSummary
        ) else {
            return "Restore Fresh Start: unavailable / Start Demo remains fresh"
        }

        if freshStartTargetLabel == targetLabel {
            return "Restore Fresh Start: confirmed over \(targetLabel) / no checkpoint restore"
        }

        if reviewedTargetLabel == targetLabel {
            return "Restore Fresh Start: awaiting Start Demo for reviewed \(targetLabel)"
        }

        return "Restore Fresh Start: pending restore-target review / Start Demo remains fresh"
    }

    func restoreExecutionGateLine(currentSceneLabel: String, currentRouteSummary: String) -> String {
        if schemaVersion != 1
            || sceneLabel != currentSceneLabel
            || routeSummary != currentRouteSummary {
            return "Restore Execution Gate: closed / stored run identity not current"
        }
        if totalCheckpointCount <= 0
            || completedCheckpointCount < 0
            || completedCheckpointCount > totalCheckpointCount {
            return "Restore Execution Gate: closed / checkpoint progress invalid"
        }
        if routeComplete || completedCheckpointCount >= totalCheckpointCount {
            return "Restore Execution Gate: closed / stored run already complete"
        }
        guard nextCheckpointLabel != nil else {
            return "Restore Execution Gate: closed / checkpoint target missing"
        }

        return "Restore Execution Gate: armed / awaiting explicit execution request"
    }

    func manualRestoreExecutionDesignLine(currentSceneLabel: String, currentRouteSummary: String) -> String {
        if schemaVersion != 1
            || sceneLabel != currentSceneLabel
            || routeSummary != currentRouteSummary {
            return "Restore Execution Design: blocked / identity preflight must pass before any restore action"
        }
        if totalCheckpointCount <= 0
            || completedCheckpointCount < 0
            || completedCheckpointCount > totalCheckpointCount {
            return "Restore Execution Design: blocked / checkpoint bounds preflight failed"
        }
        if routeComplete || completedCheckpointCount >= totalCheckpointCount {
            return "Restore Execution Design: blocked / completed runs start fresh"
        }
        guard let nextCheckpointLabel else {
            return "Restore Execution Design: blocked / target checkpoint missing"
        }

        return "Restore Execution Design: target \(nextCheckpointLabel) / requires identity, freshness, target, and explicit intent checks"
    }

    func manualRestoreSafetyCheckLine(currentSceneLabel: String, currentRouteSummary: String, maxAgeSeconds: Int) -> String {
        let identityOK = schemaVersion == 1
            && sceneLabel == currentSceneLabel
            && routeSummary == currentRouteSummary
        let progressOK = totalCheckpointCount > 0
            && completedCheckpointCount >= 0
            && completedCheckpointCount < totalCheckpointCount
            && !routeComplete
            && nextCheckpointLabel != nil
        let ageSeconds = Int(max(Date().timeIntervalSince1970 - savedAt, 0))
        let freshnessOK = savedAt > 0 && ageSeconds <= maxAgeSeconds

        return "Restore Safety Checks: identity \(identityOK ? "pass" : "fail") / target \(progressOK ? "pass" : "fail") / freshness \(freshnessOK ? "pass" : "fail") / intent token required"
    }

    func restoreAuditLine(currentSceneLabel: String, currentRouteSummary: String) -> String {
        let targetLabel = nextCheckpointLabel ?? "none"
        let ageSeconds = max(Int(Date().timeIntervalSince1970 - savedAt), 0)
        let identityState = sceneLabel == currentSceneLabel && routeSummary == currentRouteSummary
            ? "identity current"
            : "identity mismatch"

        return "Restore Audit: v\(schemaVersion) / \(completedCheckpointCount)-\(totalCheckpointCount) / target \(targetLabel) / \(identityState) / saved \(ageSeconds)s ago"
    }

    func restoreFreshnessLine(maxAgeSeconds: Int) -> String {
        guard savedAt > 0 else {
            return "Restore Freshness: stale / missing saved timestamp"
        }

        let ageSeconds = max(Int(Date().timeIntervalSince1970 - savedAt), 0)
        if ageSeconds > maxAgeSeconds {
            return "Restore Freshness: stale / saved \(ageSeconds)s ago exceeds \(maxAgeSeconds)s review window"
        }

        return "Restore Freshness: current / saved \(ageSeconds)s ago within \(maxAgeSeconds)s review window"
    }

    func restoreRetentionLine(maxAgeSeconds: Int) -> String {
        guard savedAt > 0 else {
            return "Restore Retention: future discard candidate / missing saved timestamp"
        }

        let ageSeconds = max(Int(Date().timeIntervalSince1970 - savedAt), 0)
        if ageSeconds > maxAgeSeconds {
            return "Restore Retention: future discard candidate / stale persisted review card"
        }

        return "Restore Retention: keep for future prompt review / no discard in this build"
    }

    func restoreCleanupPreviewLine(maxAgeSeconds: Int) -> String {
        guard savedAt > 0 else {
            return "Restore Cleanup Preview: would clear stale card later / no deletion in this build"
        }

        let ageSeconds = max(Int(Date().timeIntervalSince1970 - savedAt), 0)
        if ageSeconds > maxAgeSeconds {
            return "Restore Cleanup Preview: would clear stale card later / no deletion in this build"
        }

        return "Restore Cleanup Preview: no cleanup needed / review card retained"
    }

    func shouldClearForRestoreCleanup(maxAgeSeconds: Int) -> Bool {
        guard savedAt > 0 else {
            return true
        }

        let ageSeconds = max(Int(Date().timeIntervalSince1970 - savedAt), 0)
        return ageSeconds > maxAgeSeconds
    }

    func restoreCleanupExecutionLine(maxAgeSeconds: Int) -> String {
        guard savedAt > 0 else {
            return "Restore Cleanup: cleared stale review card / missing saved timestamp"
        }

        let ageSeconds = max(Int(Date().timeIntervalSince1970 - savedAt), 0)
        if ageSeconds > maxAgeSeconds {
            return "Restore Cleanup: cleared stale review card / saved \(ageSeconds)s ago"
        }

        return "Restore Cleanup: no cleanup needed / review card retained"
    }

    static func == (lhs: StoredReviewSessionState, rhs: StoredReviewSessionState) -> Bool {
        lhs.schemaVersion == rhs.schemaVersion
            && lhs.sceneLabel == rhs.sceneLabel
            && lhs.routeSummary == rhs.routeSummary
            && lhs.completedCheckpointCount == rhs.completedCheckpointCount
            && lhs.totalCheckpointCount == rhs.totalCheckpointCount
            && lhs.nextCheckpointLabel == rhs.nextCheckpointLabel
            && lhs.currentSectorName == rhs.currentSectorName
            && lhs.difficultyPreset == rhs.difficultyPreset
            && lhs.flowState == rhs.flowState
            && lhs.mapPresented == rhs.mapPresented
            && lhs.scopeActive == rhs.scopeActive
            && lhs.routeComplete == rhs.routeComplete
            && lhs.routeFailed == rhs.routeFailed
            && lhs.reviewPackageLine == rhs.reviewPackageLine
    }
}

private final class ShotFeedbackAudioEngine {
    static let shared = ShotFeedbackAudioEngine()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private let queue = DispatchQueue(label: "com.milsimpony.game.combat-audio")
    private let shotBuffer: AVAudioPCMBuffer
    private let boltBuffer: AVAudioPCMBuffer
    private let dryClickBuffer: AVAudioPCMBuffer
    private let hitConfirmBuffer: AVAudioPCMBuffer
    private let impactBuffer: AVAudioPCMBuffer
    private let alertAcquireBuffer: AVAudioPCMBuffer
    private let alertDangerBuffer: AVAudioPCMBuffer
    private let alertRelayBuffer: AVAudioPCMBuffer
    private let alertClearBuffer: AVAudioPCMBuffer
    private let footstepBuffer: AVAudioPCMBuffer
    private let scopeRaiseBuffer: AVAudioPCMBuffer
    private let scopeLowerBuffer: AVAudioPCMBuffer
    private let ambientBasinBuffer: AVAudioPCMBuffer

    private init() {
        shotBuffer = Self.makeBuffer(format: format, duration: 0.22) { time, noise in
            let attack = min(time / 0.004, 1.0)
            let boomEnvelope = attack * exp(-12.0 * time)
            let crackEnvelope = exp(-72.0 * time)
            let body = (sin(2.0 * .pi * 96.0 * time) * 0.72) + (sin(2.0 * .pi * 184.0 * time) * 0.18)
            let crack = noise * (0.30 + (sin(2.0 * .pi * 1_100.0 * time) * 0.12))
            return (body * boomEnvelope) + (crack * crackEnvelope)
        }
        boltBuffer = Self.makeBuffer(format: format, duration: 0.12) { time, noise in
            let attack = min(time / 0.002, 1.0)
            let envelope = attack * exp(-30.0 * time)
            let metal = (sin(2.0 * .pi * 760.0 * time) * 0.16) + (sin(2.0 * .pi * 1_240.0 * time) * 0.08)
            let clack = noise * 0.22 * exp(-50.0 * time)
            return (metal + clack) * envelope
        }
        dryClickBuffer = Self.makeBuffer(format: format, duration: 0.05) { time, noise in
            let envelope = exp(-110.0 * time)
            let tick = sin(2.0 * .pi * 1_850.0 * time) * 0.14
            return (noise * 0.56 * envelope) + (tick * envelope)
        }
        hitConfirmBuffer = Self.makeBuffer(format: format, duration: 0.08) { time, _ in
            let attack = min(time / 0.003, 1.0)
            let envelope = attack * exp(-34.0 * time)
            let tone = (sin(2.0 * .pi * 1_320.0 * time) * 0.26) + (sin(2.0 * .pi * 1_980.0 * time) * 0.10)
            return tone * envelope
        }
        impactBuffer = Self.makeBuffer(format: format, duration: 0.10) { time, noise in
            let attack = min(time / 0.003, 1.0)
            let envelope = attack * exp(-28.0 * time)
            let thud = sin(2.0 * .pi * 180.0 * time) * 0.16
            let grit = noise * 0.10 * exp(-65.0 * time)
            return (thud + grit) * envelope
        }
        alertAcquireBuffer = Self.makeBuffer(format: format, duration: 0.15) { time, _ in
            let first = sin(2.0 * .pi * 880.0 * time) * exp(-28.0 * time)
            let secondTime = max(time - 0.055, 0)
            let second = sin(2.0 * .pi * 1_120.0 * secondTime) * exp(-34.0 * secondTime)
            return (first * 0.18) + (second * 0.12)
        }
        alertDangerBuffer = Self.makeBuffer(format: format, duration: 0.20) { time, _ in
            let wobble = 1.0 + (sin(2.0 * .pi * 7.0 * time) * 0.08)
            let envelope = exp(-16.0 * time)
            let tone = (sin(2.0 * .pi * 620.0 * time * wobble) * 0.24) + (sin(2.0 * .pi * 410.0 * time) * 0.08)
            return tone * envelope
        }
        alertRelayBuffer = Self.makeBuffer(format: format, duration: 0.18) { time, _ in
            let first = sin(2.0 * .pi * 740.0 * time) * exp(-24.0 * time)
            let secondTime = max(time - 0.065, 0)
            let second = sin(2.0 * .pi * 980.0 * secondTime) * exp(-26.0 * secondTime)
            let thirdTime = max(time - 0.118, 0)
            let third = sin(2.0 * .pi * 820.0 * thirdTime) * exp(-34.0 * thirdTime)
            return (first * 0.12) + (second * 0.15) + (third * 0.08)
        }
        alertClearBuffer = Self.makeBuffer(format: format, duration: 0.16) { time, _ in
            let envelope = exp(-18.0 * time)
            let glide = 1.0 - min(time / 0.16, 1.0) * 0.32
            let tone = (sin(2.0 * .pi * 420.0 * time * glide) * 0.16) + (sin(2.0 * .pi * 315.0 * time) * 0.08)
            return tone * envelope
        }
        footstepBuffer = Self.makeBuffer(format: format, duration: 0.09) { time, noise in
            let attack = min(time / 0.006, 1.0)
            let envelope = attack * exp(-32.0 * time)
            let sole = sin(2.0 * .pi * 92.0 * time) * 0.12
            let gravel = noise * 0.18 * exp(-46.0 * time)
            return (sole + gravel) * envelope
        }
        scopeRaiseBuffer = Self.makeBuffer(format: format, duration: 0.12) { time, noise in
            let envelope = exp(-20.0 * time)
            let glass = sin(2.0 * .pi * 920.0 * time) * 0.10
            let cloth = noise * 0.07 * exp(-35.0 * time)
            return (glass + cloth) * envelope
        }
        scopeLowerBuffer = Self.makeBuffer(format: format, duration: 0.10) { time, noise in
            let envelope = exp(-24.0 * time)
            let glass = sin(2.0 * .pi * 640.0 * time) * 0.08
            let cloth = noise * 0.06 * exp(-38.0 * time)
            return (glass + cloth) * envelope
        }
        ambientBasinBuffer = Self.makeBuffer(format: format, duration: 1.85) { time, noise in
            let swell = 0.50 + (sin(2.0 * .pi * 0.21 * time) * 0.50)
            let wind = noise * 0.018 * (0.55 + (swell * 0.45))
            let distantLow = sin(2.0 * .pi * 68.0 * time) * 0.006
            let shore = sin(2.0 * .pi * 0.82 * time) * 0.012
            return wind + distantLow + shore
        }

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.8
        engine.prepare()
    }

    func playShotCue(cooldownSeconds: Double) {
        play(buffer: shotBuffer)
        let boltDelay = min(max(cooldownSeconds * 0.32, 0.07), 0.24)
        play(buffer: boltBuffer, after: boltDelay)
    }

    func playDryClickCue() {
        play(buffer: dryClickBuffer)
    }

    func playHitConfirmCue(after delay: Double = 0) {
        play(buffer: hitConfirmBuffer, after: delay)
    }

    func playImpactCue(after delay: Double = 0) {
        play(buffer: impactBuffer, after: delay)
    }

    func playAlertAcquireCue() {
        play(buffer: alertAcquireBuffer)
    }

    func playAlertDangerCue() {
        play(buffer: alertDangerBuffer)
    }

    func playAlertRelayCue() {
        play(buffer: alertRelayBuffer)
    }

    func playAlertClearCue() {
        play(buffer: alertClearBuffer)
    }

    func playFootstepCue() {
        play(buffer: footstepBuffer)
    }

    func playScopeToggleCue(raised: Bool) {
        play(buffer: raised ? scopeRaiseBuffer : scopeLowerBuffer)
    }

    func playAmbientBasinBed() {
        play(buffer: ambientBasinBuffer)
    }

    func recoverIfNeeded() {
        queue.async { [weak self] in
            guard let self else {
                return
            }

            do {
                try self.ensureEngineRunning()
                if !self.player.isPlaying {
                    self.player.play()
                }
            } catch {
                NSSound.beep()
            }
        }
    }

    private func play(buffer: AVAudioPCMBuffer, after delay: Double = 0) {
        queue.async { [weak self] in
            guard let self else {
                return
            }

            do {
                try self.ensureEngineRunning()
            } catch {
                NSSound.beep()
                return
            }

            let startPlayback = {
                self.player.scheduleBuffer(buffer, completionHandler: nil)
                if !self.player.isPlaying {
                    self.player.play()
                }
            }

            if delay > 0.001 {
                self.queue.asyncAfter(deadline: .now() + delay) { [weak self] in
                    guard let self else {
                        return
                    }

                    do {
                        try self.ensureEngineRunning()
                    } catch {
                        NSSound.beep()
                        return
                    }

                    startPlayback()
                }
                return
            }

            startPlayback()
        }
    }

    private func ensureEngineRunning() throws {
        if !engine.isRunning {
            engine.prepare()
            try engine.start()
        }
    }

    private static func makeBuffer(
        format: AVAudioFormat,
        duration: Double,
        generator: (_ time: Double, _ noise: Double) -> Double
    ) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(max((duration * format.sampleRate).rounded(.up), 1.0))
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        guard let channel = buffer.floatChannelData?[0] else {
            return buffer
        }

        var seed: UInt64 = 0x1234_5678_9ABC_DEF0
        for sampleIndex in 0..<Int(frameCount) {
            seed = (seed &* 1_664_525) &+ 1_013_904_223
            let normalizedNoise = (Double(seed & 0xFFFF) / 32_767.5) - 1.0
            let time = Double(sampleIndex) / format.sampleRate
            let sample = generator(time, normalizedNoise)
            channel[sampleIndex] = Float(max(min(sample, 0.98), -0.98))
        }

        return buffer
    }
}

struct OverheadMapSnapshot {
    let configuration: SceneMapConfiguration
    let playerX: Float
    let playerZ: Float
    let headingX: Float
    let headingZ: Float
    let currentSectorName: String
    let completedCheckpointCount: Int
    let totalCheckpointCount: Int
    let nextCheckpointLabel: String?
    let nextComparisonStop: SceneMapComparisonStop?
    let nextCombatStop: SceneMapCombatStop?
    let nextMissionPhase: SceneMapMissionPhase?
    let suspicionLevel: Float
    let activeObserverCount: Int
    let alertedObserverCount: Int
    let seeingObserverCount: Int
    let neutralizedObserverCount: Int
    let failCount: Int
    let effectiveFailThreshold: Float
    let difficultyLabel: String
    let threatStates: [OverheadMapThreatState]

    var alertedThreatCount: Int {
        threatStates.filter(\.isAlerted).count
    }

    var maskedThreatCount: Int {
        threatStates.filter(\.isMasked).count
    }

    var offAxisThreatCount: Int {
        threatStates.filter(\.isOffAxis).count
    }

    var idleThreatCount: Int {
        threatStates.filter(\.isIdle).count
    }
}

struct OverheadMapThreatState: Identifiable {
    let id: String
    let label: String
    let neutralized: Bool
    let alerted: Bool
    let supportingGroup: Bool
    let inRange: Bool
    let inViewCone: Bool
    let hasLineOfSight: Bool
    let seeingPlayer: Bool

    var isAlerted: Bool {
        !neutralized && alerted && !seeingPlayer && !isMasked
    }

    var isMasked: Bool {
        !neutralized && inRange && inViewCone && !hasLineOfSight
    }

    var isOffAxis: Bool {
        !neutralized && inRange && !inViewCone
    }

    var isIdle: Bool {
        !neutralized && !seeingPlayer && !isMasked && !isOffAxis && !isAlerted
    }
}

private struct ObserverLOSDebugState {
    let index: Int
    let label: String
    let distanceMeters: Float
    let rangeMeters: Float
    let fieldOfViewDegrees: Float
    let yawDegrees: Float
    let pitchDegrees: Float
    let viewDot: Float
    let coneThreshold: Float
    let suspicionPerSecond: Float
    let alertSecondsRemaining: Float
    let scanArcDegrees: Float
    let scanCycleSeconds: Float
    let scanPhaseSeconds: Float
    let neutralized: Bool
    let alerted: Bool
    let supportingGroup: Bool
    let scanHalted: Bool
    let inRange: Bool
    let inViewCone: Bool
    let hasLineOfSight: Bool
    let seeingPlayer: Bool

    var sortPriority: Int {
        if seeingPlayer {
            return 0
        }
        if supportingGroup {
            return 1
        }
        if alerted {
            return 2
        }
        if hasLineOfSight {
            return 3
        }
        if inViewCone {
            return 4
        }
        if inRange {
            return 5
        }
        if neutralized {
            return 7
        }
        return 6
    }

    var statusLabel: String {
        if neutralized {
            return "neutralized"
        }
        if seeingPlayer {
            return "SEEING"
        }
        if supportingGroup {
            return "support"
        }
        if alerted {
            return "alerted"
        }
        if hasLineOfSight {
            return "open lane"
        }
        if inViewCone {
            return "masked"
        }
        if inRange {
            return "off-axis"
        }
        return "out of range"
    }

    var scanStateLabel: String {
        if neutralized {
            return "neutralized"
        }
        if seeingPlayer {
            return "tracking"
        }
        if supportingGroup {
            return "relay scan"
        }
        if alerted {
            return "memory scan"
        }
        if inRange && inViewCone && !hasLineOfSight {
            return "blocked scan"
        }
        if inRange && !inViewCone {
            return "off-axis sweep"
        }
        if inRange {
            return "open sweep"
        }
        if scanArcDegrees > 0 {
            return "resume sweep"
        }
        return "idle sweep"
    }
}

final class GameSession: ObservableObject {
    @Published private(set) var statusLine = "Bootstrapping game session"
    @Published private(set) var overlayLines: [String] = []
    @Published private(set) var overlayTitle = "Cycle 30 Mission Script And Checkpoint Hooks"
    @Published private(set) var demoFlowState: DemoFlowState = .title
    @Published private(set) var isSettingsPresented = false
    @Published private(set) var isScopeActive = false
    @Published private(set) var isMapPresented = false
    @Published private(set) var hudOpacity: Double
    @Published private(set) var invertLookY: Bool
    @Published private(set) var lookSensitivityScale: Double
    @Published private(set) var difficultyPreset: RehearsalDifficultyPreset
    @Published private(set) var inputFocusRequestID = 0

    private let configuration: LaunchConfiguration
    private var pressedCommands: Set<InputCommand> = []
    private var lastMouseDelta: CGSize = .zero
    private var shouldIgnoreNextMouseDelta = true
    private var latestSnapshot: GameFrameSnapshot?
    private var latestBallisticPrediction: GameBallisticPrediction?
    private var latestProfilingSnapshot: GameProfilingSnapshot?
    private var viewportSize: CGSize = .zero
    private var rendererName = "Waiting for Metal"
    private var sceneLabel = WorldBootstrap.sceneLabel
    private var sceneSummary = "Preparing scene"
    private var sceneDetails: [String] = []
    private var briefingSummary = "Briefing: building route readout"
    private var briefingDetails: [String] = []
    private var routeSummary = "Route: waiting for route state"
    private var routeDetails: [String] = []
    private var evasionSummary = "Evasion: waiting for detection state"
    private var evasionDetails: [String] = []
    private var streamingSummary = "Chunks: waiting for stream state"
    private var streamingDetails: [String] = []
    private var frameTimingLine = "Frame: collecting samples"
    private var completedCheckpointCount = 0
    private var routeWasComplete = false
    private var routeWasFailed = false
    private var sceneReady = false
    private var baseWalkSpeed: Float?
    private var baseSprintSpeed: Float?
    private var baseLookSensitivity: Float?
    private var scopeLabel = "4x Scope"
    private var scopeMagnification: Float = 4.0
    private var scopeFieldOfViewDegrees: Float = 15.0
    private var scopeLookSensitivityMultiplier: Float = 0.26
    private var scopeDrawDistanceMultiplier: Float = 2.4
    private var scopeFarPlaneMultiplierValue: Float = 1.35
    private var scopeReticleColorComponents = SIMD4<Float>(0.92, 0.86, 0.42, 0.94)
    private var ballisticMuzzleVelocityMetersPerSecond: Float = 820.0
    private var ballisticGravityMetersPerSecondSquared: Float = 9.81
    private var ballisticMaxSimulationTimeSeconds: Float = 2.4
    private var ballisticSimulationStepSeconds: Float = 1.0 / 120.0
    private var ballisticLaunchHeightOffsetMeters: Float = 0.0
    private var detectionFailThreshold: Float = 1.0
    private var mapConfiguration: SceneMapConfiguration?
    private var cachedOverheadMapSnapshot: OverheadMapSnapshot?
    private var latestObserverDebugStates: [ObserverLOSDebugState] = []
    private var lastThreatSeeingCount = 0
    private var lastThreatAlertBand = 0
    private var lastThreatSupportingCount = 0
    private var lastThreatAudibleState = "quiet"
    private var lastThreatAudioElapsedSeconds: Double = -10
    private var lastFootstepAudioElapsedSeconds: Double = -10
    private var lastAmbientAudioElapsedSeconds: Double = -10
    private var lastRealtimeRecoveryElapsedSeconds: Double = -10
    private var lastMovementAudioState = "idle"
    private var lastWorldAudioState = "ambient waiting"
    private var lastScopeAudioState = "scope ready"
    private var sessionAudioState = "session audio waiting"
    private var alternateRouteActivationArmed = false
    private var alternateRouteActivationLine = "Alternate Live Binding: primary route armed"
    private var freshRunHandler: (() -> Void)?
    private var pendingOverlayLines: [String]?
    private var isOverlayPublishScheduled = false
    private var storedReviewSessionState: StoredReviewSessionState?
    private var restoreCleanupExecutionLine: String
    private var reviewedManualRestoreTargetLabel: String?
    private var freshStartConfirmedRestoreTargetLabel: String?
    private var restoreBoundaryResetLine: String
    private var restoreReviewExpiryLine: String

    init(configuration: LaunchConfiguration) {
        let storedSettings = Self.loadStoredSettings()
        var storedReviewSessionState = Self.loadStoredReviewSessionState()
        let restoreCleanupExecutionLine = Self.applyRestoreCleanup(to: &storedReviewSessionState)
        self.configuration = configuration
        self.hudOpacity = storedSettings.hudOpacity
        self.invertLookY = storedSettings.invertLookY
        self.lookSensitivityScale = storedSettings.lookSensitivityScale
        self.difficultyPreset = storedSettings.difficultyPreset
        self.storedReviewSessionState = storedReviewSessionState
        self.restoreCleanupExecutionLine = restoreCleanupExecutionLine
        self.reviewedManualRestoreTargetLabel = nil
        self.freshStartConfirmedRestoreTargetLabel = nil
        self.restoreBoundaryResetLine = "Restore Boundary Reset: pending / no restore review cleared this run"
        self.restoreReviewExpiryLine = "Restore Review Expiry: pending / no restore review tracked this run"

        configuration.bootMode.withCString { bootMode in
            GameCoreBootstrap(bootMode)
        }
        GameCoreConfigureDifficulty(difficultyPreset.coreTuning)

        print("[App] Booting \(configuration.worldName) in \(configuration.bootMode) mode")
        rebuildOverlay()
    }

    var assetRootPath: String {
        configuration.assetRoot
    }

    var worldDataRootPath: String {
        configuration.worldDataRoot
    }

    var worldManifestPath: String {
        configuration.worldManifestPath
    }

    var menuPanel: GameMenuPanel? {
        if isSettingsPresented {
            return .settings
        }

        switch demoFlowState {
        case .playing:
            return nil
        case .title:
            return .title
        case .paused:
            return .paused
        case .failed:
            return .failed
        case .complete:
            return .complete
        }
    }

    var shouldAdvanceSimulation: Bool {
        allowsLiveGameplayInput
    }

    var hudCardOpacity: Double {
        switch menuPanel {
        case .title?, .settings?:
            return max(hudOpacity * 0.55, 0.22)
        default:
            return isScopeActive ? max(hudOpacity * 0.62, 0.20) : hudOpacity
        }
    }

    var inputCardSubtitle: String {
        let cycleLabel = overlayTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return menuPanel == nil
            ? "\(cycleLabel) traversal, scoped firing, map lookup, and landmark validation controls"
            : "Deploy, pause, map, retry, and tune field settings"
    }

    var canBeginMission: Bool {
        sceneReady
    }

    var canPreviewManualRestoreChoice: Bool {
        manualRestoreChoiceTargetLabel != nil
    }

    var canExecuteManualRestore: Bool {
        guard let targetLabel = manualRestoreChoiceTargetLabel else {
            return false
        }

        return reviewedManualRestoreTargetLabel == targetLabel
            && manualRestoreExecutionProgress != nil
    }

    var canArmAlternateRouteActivation: Bool {
        guard demoFlowState == .title, let mapConfiguration else {
            return false
        }

        return mapConfiguration.selectedAlternateRouteID != nil
            && mapConfiguration.activeRouteID != mapConfiguration.selectedAlternateRouteID
            && !alternateRouteActivationArmed
    }

    var alternateRouteActivationButtonTitle: String {
        guard let label = mapConfiguration?.selectedAlternateRouteLabel else {
            return "Alternate Route Unavailable"
        }

        if alternateRouteActivationArmed {
            return "Alternate Armed: \(label)"
        }

        return "Arm Alternate Route: \(label)"
    }

    var manualRestoreChoiceButtonTitle: String {
        guard let targetLabel = manualRestoreChoiceTargetLabel else {
            return "Restore Preview Unavailable"
        }

        return "Review Restore Target: \(targetLabel)"
    }

    var manualRestoreExecutionButtonTitle: String {
        guard let targetLabel = manualRestoreChoiceTargetLabel else {
            return "Execute Restore Unavailable"
        }

        return "Execute Restore: \(targetLabel)"
    }

    var activeCommands: Set<InputCommand> {
        pressedCommands
    }

    var canShowMap: Bool {
        mapConfiguration != nil
    }

    private var allowsSceneTuningInput: Bool {
        allowsLiveGameplayInput
    }

    private var allowsLiveGameplayInput: Bool {
        guard sceneReady else {
            return false
        }

        return demoFlowState == .playing && menuPanel == nil
    }

    var difficultySummaryText: String {
        difficultyPreset.summary
    }

    private var effectiveDetectionFailThreshold: Float {
        max(detectionFailThreshold * difficultyPreset.failThresholdScale, 0.1)
    }

    private var scopedWeaponStability: Float {
        simd_clamp(latestSnapshot?.weaponStability ?? 0.0, 0.0, 1.0)
    }

    private var scopedWeaponSpreadDegrees: Float {
        max(latestSnapshot?.weaponSpreadDegrees ?? 0.0, 0.0)
    }

    private var holdBreathSecondsRemaining: Float {
        max(latestSnapshot?.holdBreathSecondsRemaining ?? 0.0, 0.0)
    }

    private var steadyAimActive: Bool {
        latestSnapshot?.steadyAimActive ?? false
    }

    var scopeStatusText: String {
        if isScopeActive {
            let cooldownSeconds = max(latestSnapshot?.weaponCooldownSeconds ?? 0, 0)
            let cycleStatus = cooldownSeconds > 0.01
                ? String(format: "cycling %.2fs", cooldownSeconds)
                : "fire ready"
            let stabilityPercent = Int((scopedWeaponStability * 100).rounded())
            let breathStatus = steadyAimActive
                ? String(format: "steady %.1fs", holdBreathSecondsRemaining)
                : String(format: "stable %d%%", stabilityPercent)
            if let targetLabel = predictedObserverLabel() {
                return String(
                    format: "%.1fx scope active / %@ / %@ / %@",
                    scopeMagnification,
                    targetLabel,
                    breathStatus,
                    cycleStatus
                )
            } else if let threatObserver = primarySeeingObserver {
                return String(
                    format: "%.1fx scope active / %@ sees you / %@ / %@",
                    scopeMagnification,
                    threatObserver.label,
                    breathStatus,
                    cycleStatus
                )
            } else if let alertedObserver = primaryAlertedObserver {
                return String(
                    format: "%.1fx scope active / %@ memory %.1fs / %@ / %@",
                    scopeMagnification,
                    alertedObserver.label,
                    alertedObserver.alertSecondsRemaining,
                    breathStatus,
                    cycleStatus
                )
            } else if
                let snapshot = latestSnapshot,
                snapshot.lastShotHitObserver,
                snapshot.lastShotElapsedSeconds >= 0,
                (snapshot.elapsedSeconds - snapshot.lastShotElapsedSeconds) <= 1.0,
                let confirmedLabel = observerLabel(for: snapshot.lastShotObserverIndex)
            {
                return String(
                    format: "%.1fx scope active / last %@ / %@ / %@",
                    scopeMagnification,
                    confirmedLabel,
                    breathStatus,
                    cycleStatus
                )
            } else {
                return String(
                    format: "%.1fx scope active / stable %d%% / %.2f deg spread / %@",
                    scopeMagnification,
                    stabilityPercent,
                    scopedWeaponSpreadDegrees,
                    cycleStatus
                )
            }
        }

        return String(format: "%.1fx scope ready / press Space", scopeMagnification)
    }

    var scopeInstructionText: String {
        if isScopeActive, let targetLabel = predictedObserverLabel() {
            if steadyAimActive {
                return "Click or press F to confirm \(targetLabel) / release E to recover breath / Space lowers scope"
            }
            return "Click or press F to confirm \(targetLabel) / hold E to steady / Space lowers scope"
        }

        if isScopeActive, let threatObserver = primarySeeingObserver {
            if steadyAimActive {
                return "Break line of sight from \(threatObserver.label) or fire / release E to recover breath / Space lowers scope"
            }
            return "Break line of sight from \(threatObserver.label) or fire / hold E to steady / Space lowers scope"
        }

        if isScopeActive, let alertedObserver = primaryAlertedObserver {
            return "Shared alert memory on \(alertedObserver.label) / hold cover or confirm target / Space lowers scope"
        }

        return isScopeActive
            ? (steadyAimActive
                ? "Click or press F to fire / release E to recover breath / Space lowers scope"
                : "Click or press F to fire / hold E to steady / Space lowers scope")
            : "Raise scope on the contact and skyline markers"
    }

    var scopePresentationText: String {
        guard isScopeActive else {
            return String(format: "Optic: %.1fx mil reticle ready", scopeMagnification)
        }

        let parallaxPercent = Int((simd_clamp(scopedWeaponSpreadDegrees / 1.6, 0.0, 1.0) * 100).rounded())
        let recoilText: String
        if
            let snapshot = latestSnapshot,
            snapshot.shotCount > 0,
            snapshot.lastShotElapsedSeconds >= 0
        {
            let shotAgeSeconds = max(snapshot.elapsedSeconds - snapshot.lastShotElapsedSeconds, 0)
            let recoveryDurationSeconds = max(Double(snapshot.weaponCycleSeconds) * 0.85, 0.25)
            let recoilPercent = Int((max(1.0 - (shotAgeSeconds / recoveryDurationSeconds), 0) * 100).rounded())
            recoilText = String(format: "recoil %d%%", recoilPercent)
        } else {
            recoilText = "recoil settled"
        }

        let holdoverMils: Float
        if let prediction = latestBallisticPrediction, prediction.valid, prediction.travelDistanceMeters > 1 {
            let rangeKilometers = max(prediction.travelDistanceMeters / 1000.0, 0.001)
            holdoverMils = prediction.dropMeters / rangeKilometers
        } else {
            holdoverMils = 0
        }

        return String(
            format: "Optic: mil %.1f hold / parallax %d%% / %@",
            holdoverMils,
            parallaxPercent,
            recoilText
        )
    }

    var scopeShotTimingText: String {
        guard
            isScopeActive,
            let snapshot = latestSnapshot,
            snapshot.shotCount > 0,
            snapshot.lastShotElapsedSeconds >= 0
        else {
            return "Shot Timing: crack-thump armed"
        }

        let shotAgeSeconds = max(snapshot.elapsedSeconds - snapshot.lastShotElapsedSeconds, 0)
        let crackLeadSeconds = min(max(Double(snapshot.lastShotFlightTimeSeconds) * 0.18, 0.03), 0.24)
        let thumpSeconds = max(Double(snapshot.lastShotFlightTimeSeconds), crackLeadSeconds)
        let thumpState = shotAgeSeconds < thumpSeconds
            ? String(format: "thump in %.2fs", thumpSeconds - shotAgeSeconds)
            : "thump resolved"
        let resultLabel: String
        if snapshot.lastShotHitObserver {
            resultLabel = observerLabel(for: snapshot.lastShotObserverIndex) ?? "observer hit"
        } else if snapshot.lastShotHitCollisionVolume {
            resultLabel = "blocker"
        } else if snapshot.lastShotHitGround {
            resultLabel = "ground"
        } else {
            resultLabel = "clear miss"
        }

        return String(
            format: "Shot Timing: crack %.2fs / %@ / %@ %.0fm",
            crackLeadSeconds,
            thumpState,
            resultLabel,
            snapshot.lastShotTravelDistanceMeters
        )
    }

    var scopeReticleColor: NSColor {
        var base = scopeReticleColorComponents
        if isScopeActive, predictedObserverLabel() != nil {
            let lockTint = SIMD4<Float>(0.62, 0.96, 0.76, 0.98)
            base += (lockTint - base) * 0.18
        } else if isScopeActive, primarySeeingObserver != nil {
            let alertTint = SIMD4<Float>(1.0, 0.58, 0.44, 0.98)
            base += (alertTint - base) * 0.22
        } else if isScopeActive, primaryAlertedObserver != nil {
            let relayTint = SIMD4<Float>(1.0, 0.76, 0.48, 0.98)
            base += (relayTint - base) * 0.14
        }

        let flashStrength: Float
        let flashColor: SIMD4<Float>
        if
            let snapshot = latestSnapshot,
            snapshot.shotCount > 0,
            snapshot.lastShotElapsedSeconds >= 0
        {
            let age = max(Float(snapshot.elapsedSeconds - snapshot.lastShotElapsedSeconds), 0)
            flashStrength = simd_clamp(1.0 - (age / 0.12), 0.0, 1.0)
            if snapshot.lastShotHitObserver {
                flashColor = SIMD4<Float>(0.52, 1.0, 0.72, 1.0)
            } else if snapshot.lastShotHitCollisionVolume || snapshot.lastShotHitGround {
                flashColor = SIMD4<Float>(1.0, 0.68, 0.48, 1.0)
            } else {
                flashColor = SIMD4<Float>(1.0, 0.82, 0.52, 1.0)
            }
        } else {
            flashStrength = 0
            flashColor = SIMD4<Float>(1.0, 0.82, 0.52, 1.0)
        }

        let color = base + ((flashColor - base) * flashStrength)
        return NSColor(
            calibratedRed: CGFloat(color.x),
            green: CGFloat(color.y),
            blue: CGFloat(color.z),
            alpha: CGFloat(color.w)
        )
    }

    var scopeFieldOfViewYRadians: Float {
        max(scopeFieldOfViewDegrees, 4.0) * (.pi / 180.0)
    }

    var scopeFarPlaneMultiplier: Float {
        max(scopeFarPlaneMultiplierValue, 1.0)
    }

    var scopeReticleOffset: CGSize {
        guard isScopeActive else {
            return .zero
        }

        let halfFieldOfView = max(scopeFieldOfViewDegrees * 0.5, 1.0)
        let yawOffset = (latestSnapshot?.aimYawOffsetDegrees ?? 0) / halfFieldOfView
        let pitchOffset = (latestSnapshot?.aimPitchOffsetDegrees ?? 0) / halfFieldOfView
        return CGSize(
            width: CGFloat(simd_clamp(yawOffset, -1.0, 1.0)),
            height: CGFloat(simd_clamp(-pitchOffset, -1.0, 1.0))
        )
    }

    var scopeReticleBloomScale: CGFloat {
        guard isScopeActive else {
            return 0
        }

        let bloom = simd_clamp(scopedWeaponSpreadDegrees / 2.2, 0.0, 1.0)
        return CGFloat(bloom)
    }

    private func observerLabel(for index: Int32) -> String? {
        guard
            let mapConfiguration,
            index >= 0,
            Int(index) < mapConfiguration.threatObservers.count
        else {
            return nil
        }

        return mapConfiguration.threatObservers[Int(index)].label
    }

    private func predictedObserverLabel() -> String? {
        guard
            let prediction = latestBallisticPrediction,
            prediction.valid,
            prediction.hitObserver
        else {
            return nil
        }

        return observerLabel(for: prediction.observerIndex)
    }

    private var primarySeeingObserver: ObserverLOSDebugState? {
        latestObserverDebugStates
            .filter(\.seeingPlayer)
            .sorted {
                if $0.sortPriority != $1.sortPriority {
                    return $0.sortPriority < $1.sortPriority
                }
                return $0.distanceMeters < $1.distanceMeters
            }
            .first
    }

    private var primaryAlertedObserver: ObserverLOSDebugState? {
        latestObserverDebugStates
            .filter { $0.alerted && !$0.neutralized && !$0.seeingPlayer }
            .sorted {
                if $0.sortPriority != $1.sortPriority {
                    return $0.sortPriority < $1.sortPriority
                }
                return $0.distanceMeters < $1.distanceMeters
            }
            .first
    }

    private func refreshObserverDebugStatesFromCore() {
        let totalObserverCount = Int(GameCoreGetObserverDebugStates(nil, 0))
        guard totalObserverCount > 0 else {
            latestObserverDebugStates = []
            return
        }

        var rawStates = Array(repeating: GameObserverDebugState(), count: totalObserverCount)
        let copiedCount = rawStates.withUnsafeMutableBufferPointer { buffer -> Int in
            Int(GameCoreGetObserverDebugStates(buffer.baseAddress, Int32(buffer.count)))
        }
        let resolvedCount = min(totalObserverCount, max(copiedCount, 0))

        latestObserverDebugStates = rawStates.prefix(resolvedCount).enumerated().map { index, state in
            ObserverLOSDebugState(
                index: index,
                label: observerLabel(for: Int32(index)) ?? "observer \(index + 1)",
                distanceMeters: state.distanceMeters,
                rangeMeters: state.rangeMeters,
                fieldOfViewDegrees: state.fieldOfViewDegrees,
                yawDegrees: state.yawDegrees,
                pitchDegrees: state.pitchDegrees,
                viewDot: state.viewDot,
                coneThreshold: state.coneThreshold,
                suspicionPerSecond: state.suspicionPerSecond,
                alertSecondsRemaining: state.alertSecondsRemaining,
                scanArcDegrees: state.scanArcDegrees,
                scanCycleSeconds: state.scanCycleSeconds,
                scanPhaseSeconds: state.scanPhaseSeconds,
                neutralized: state.neutralized,
                alerted: state.alerted,
                supportingGroup: state.supportingGroup,
                scanHalted: state.scanHalted,
                inRange: state.inRange,
                inViewCone: state.inViewCone,
                hasLineOfSight: state.hasLineOfSight,
                seeingPlayer: state.seeingPlayer
            )
        }
    }

    private func prominentObserverDebugStates(limit: Int = 3) -> [ObserverLOSDebugState] {
        latestObserverDebugStates
            .sorted {
                if $0.sortPriority != $1.sortPriority {
                    return $0.sortPriority < $1.sortPriority
                }
                return $0.distanceMeters < $1.distanceMeters
            }
            .prefix(limit)
            .map { $0 }
    }

    private func currentThreatAlertBand(for snapshot: GameFrameSnapshot) -> Int {
        let failThreshold = effectiveDetectionFailThreshold
        if snapshot.routeFailed {
            return 3
        }
        if snapshot.seeingObserverCount > 0 && snapshot.suspicionLevel >= (failThreshold * 0.72) {
            return 2
        }
        if snapshot.alertedObserverCount > 0 {
            return 1
        }
        if snapshot.seeingObserverCount > 0 || snapshot.suspicionLevel >= (failThreshold * 0.35) {
            return 1
        }
        return 0
    }

    private func resetThreatFeedbackState() {
        lastThreatSeeingCount = Int(latestSnapshot?.seeingObserverCount ?? 0)
        lastThreatSupportingCount = latestObserverDebugStates.filter(\.supportingGroup).count
        if let latestSnapshot {
            lastThreatAlertBand = currentThreatAlertBand(for: latestSnapshot)
            lastThreatAudibleState = threatAudibleState(for: latestSnapshot)
            lastThreatAudioElapsedSeconds = latestSnapshot.elapsedSeconds
        } else {
            lastThreatAlertBand = 0
            lastThreatAudibleState = "quiet"
            lastThreatAudioElapsedSeconds = -10
        }
    }

    private func applyThreatAudioFeedback(for snapshot: GameFrameSnapshot) {
        let seeingCount = Int(snapshot.seeingObserverCount)
        let alertBand = currentThreatAlertBand(for: snapshot)
        let supportingCount = latestObserverDebugStates.filter(\.supportingGroup).count
        let audibleState = threatAudibleState(for: snapshot)

        defer {
            lastThreatSeeingCount = seeingCount
            lastThreatAlertBand = alertBand
            lastThreatSupportingCount = supportingCount
            lastThreatAudibleState = audibleState
        }

        guard sceneReady, demoFlowState == .playing, menuPanel == nil else {
            return
        }

        let timeSinceLastCue = snapshot.elapsedSeconds - lastThreatAudioElapsedSeconds
        let noteCuePlayed = {
            self.lastThreatAudioElapsedSeconds = snapshot.elapsedSeconds
        }

        if seeingCount > 0, lastThreatSeeingCount == 0, timeSinceLastCue > 0.30 {
            ShotFeedbackAudioEngine.shared.playAlertAcquireCue()
            noteCuePlayed()
            return
        }

        if supportingCount > lastThreatSupportingCount, timeSinceLastCue > 0.35 {
            ShotFeedbackAudioEngine.shared.playAlertRelayCue()
            noteCuePlayed()
            return
        }

        if alertBand > lastThreatAlertBand, timeSinceLastCue > 0.45 {
            if alertBand >= 2 {
                ShotFeedbackAudioEngine.shared.playAlertDangerCue()
            } else {
                ShotFeedbackAudioEngine.shared.playAlertAcquireCue()
            }
            noteCuePlayed()
            return
        }

        if audibleState == "clear", lastThreatAudibleState != "clear", timeSinceLastCue > 0.70 {
            ShotFeedbackAudioEngine.shared.playAlertClearCue()
            noteCuePlayed()
        }
    }

    private func applyWorldMovementAudioFeedback(for snapshot: GameFrameSnapshot) {
        guard sceneReady, demoFlowState == .playing, menuPanel == nil else {
            lastMovementAudioState = "paused"
            lastWorldAudioState = "ambient paused"
            return
        }

        let ambientInterval = snapshot.alertedObserverCount > 0 || snapshot.seeingObserverCount > 0 ? 1.35 : 1.75
        if snapshot.elapsedSeconds - lastAmbientAudioElapsedSeconds > ambientInterval {
            ShotFeedbackAudioEngine.shared.playAmbientBasinBed()
            lastAmbientAudioElapsedSeconds = snapshot.elapsedSeconds
            lastWorldAudioState = threatAudibleState(for: snapshot) == "quiet"
                ? "basin bed"
                : "basin bed + \(threatAudibleState(for: snapshot))"
        }

        let moving = snapshot.grounded && snapshot.moveSpeed > 0.35
        guard moving else {
            lastMovementAudioState = snapshot.grounded ? "idle grounded" : "airborne muted"
            return
        }

        let speedRatio = snapshot.sprintSpeed > 0
            ? simd_clamp(snapshot.moveSpeed / snapshot.sprintSpeed, 0.0, 1.0)
            : 0.0
        let stepInterval = max(0.26, 0.58 - (Double(speedRatio) * 0.24))
        if snapshot.elapsedSeconds - lastFootstepAudioElapsedSeconds >= stepInterval {
            ShotFeedbackAudioEngine.shared.playFootstepCue()
            lastFootstepAudioElapsedSeconds = snapshot.elapsedSeconds
        }

        lastMovementAudioState = snapshot.sprinting
            ? String(format: "sprint steps %.2fs", stepInterval)
            : String(format: "walk steps %.2fs", stepInterval)
    }

    private func threatAudibleState(for snapshot: GameFrameSnapshot) -> String {
        if snapshot.routeFailed {
            return "compromised"
        }
        if snapshot.seeingObserverCount > 0 {
            return "exposed"
        }
        if latestObserverDebugStates.contains(where: { $0.supportingGroup && !$0.neutralized }) {
            return "relay"
        }
        if snapshot.alertedObserverCount > 0 {
            return "memory"
        }
        if snapshot.suspicionLevel > 0.03 {
            return "cooling"
        }
        return "clear"
    }

    var overheadMapSnapshot: OverheadMapSnapshot? {
        cachedOverheadMapSnapshot
    }

    private var currentMapSectorName: String {
        cachedOverheadMapSnapshot?.currentSectorName ?? "waiting for Canberra layout"
    }

    private func refreshOverheadMapSnapshot() {
        guard let mapConfiguration else {
            cachedOverheadMapSnapshot = nil
            return
        }

        let snapshot = latestSnapshot
        let playerX = snapshot?.cameraX ?? mapConfiguration.spawnPoint.x
        let playerZ = snapshot?.cameraZ ?? mapConfiguration.spawnPoint.z
        let yawDegrees = snapshot?.yawDegrees ?? mapConfiguration.spawnYawDegrees
        let yawRadians = yawDegrees * (.pi / 180.0)
        let completedCheckpointCount = min(
            Int(snapshot?.completedCheckpointCount ?? 0),
            mapConfiguration.checkpoints.count
        )
        let nextCheckpointLabel = completedCheckpointCount < mapConfiguration.checkpoints.count
            ? mapConfiguration.checkpoints[completedCheckpointCount].label
            : nil
        let nextComparisonStop = completedCheckpointCount < mapConfiguration.checkpoints.count
            ? mapConfiguration.comparisonStops.first { comparisonStop in
                comparisonStop.checkpointID == mapConfiguration.checkpoints[completedCheckpointCount].id
            }
            : nil
        let nextCombatStop = completedCheckpointCount < mapConfiguration.checkpoints.count
            ? mapConfiguration.contactStops.first { contactStop in
                contactStop.checkpointID == mapConfiguration.checkpoints[completedCheckpointCount].id
            }
            : nil
        let nextMissionPhase = completedCheckpointCount < mapConfiguration.checkpoints.count
            ? mapConfiguration.missionPhases.first { phase in
                phase.checkpointID == mapConfiguration.checkpoints[completedCheckpointCount].id
            }
            : nil
        let currentSectorName = preferredSectorName(
            for: mapConfiguration.sectors,
            playerX: playerX,
            playerZ: playerZ
        )
        let threatStates = mapConfiguration.threatObservers.enumerated().map { index, observer in
            let debugState = index < latestObserverDebugStates.count ? latestObserverDebugStates[index] : nil
            return OverheadMapThreatState(
                id: observer.id,
                label: observer.label,
                neutralized: debugState?.neutralized ?? false,
                alerted: debugState?.alerted ?? false,
                supportingGroup: debugState?.supportingGroup ?? false,
                inRange: debugState?.inRange ?? false,
                inViewCone: debugState?.inViewCone ?? false,
                hasLineOfSight: debugState?.hasLineOfSight ?? false,
                seeingPlayer: debugState?.seeingPlayer ?? false
            )
        }

        cachedOverheadMapSnapshot = OverheadMapSnapshot(
            configuration: mapConfiguration,
            playerX: playerX,
            playerZ: playerZ,
            headingX: sinf(yawRadians),
            headingZ: -cosf(yawRadians),
            currentSectorName: currentSectorName,
            completedCheckpointCount: completedCheckpointCount,
            totalCheckpointCount: mapConfiguration.checkpoints.count,
            nextCheckpointLabel: nextCheckpointLabel,
            nextComparisonStop: nextComparisonStop,
            nextCombatStop: nextCombatStop,
            nextMissionPhase: nextMissionPhase,
            suspicionLevel: snapshot?.suspicionLevel ?? 0,
            activeObserverCount: Int(snapshot?.activeObserverCount ?? 0),
            alertedObserverCount: Int(snapshot?.alertedObserverCount ?? 0),
            seeingObserverCount: Int(snapshot?.seeingObserverCount ?? 0),
            neutralizedObserverCount: Int(snapshot?.neutralizedObserverCount ?? 0),
            failCount: Int(snapshot?.failCount ?? 0),
            effectiveFailThreshold: effectiveDetectionFailThreshold,
            difficultyLabel: difficultyPreset.displayName,
            threatStates: threatStates
        )
    }

    func menuTitle(for panel: GameMenuPanel) -> String {
        switch panel {
        case .title:
            return sceneReady ? sceneLabel : WorldBootstrap.sceneLabel
        case .paused:
            return "Demo Paused"
        case .failed:
            return "Compromised"
        case .complete:
            return "Rehearsal Complete"
        case .settings:
            return "Field Settings"
        }
    }

    func menuSubtitle(for panel: GameMenuPanel) -> String {
        switch panel {
        case .title:
            return sceneReady ? overlayTitle : "Loading Canberra combat rehearsal"
        case .paused:
            return routeSummary
        case .failed:
            return "Observer pressure forced a checkpoint fallback"
        case .complete:
            return routeSummary
        case .settings:
            return "Controls, field difficulty, Canberra locator, and overlay tuning"
        }
    }

    func menuLines(for panel: GameMenuPanel) -> [String] {
        switch panel {
        case .title:
            return titlePanelLines()
        case .paused:
            return pausedPanelLines()
        case .failed:
            return failedPanelLines()
        case .complete:
            return completePanelLines()
        case .settings:
            return settingsPanelLines()
        }
    }

    func noteRendererReady(deviceName: String) {
        rendererName = deviceName
        statusLine = "Metal ready on \(deviceName)"
        rebuildOverlay()
    }

    func noteRendererUnavailable() {
        rendererName = "No compatible Metal device"
        statusLine = "Metal initialization failed"
        rebuildOverlay()
    }

    func noteViewActivation() {
        shouldIgnoreNextMouseDelta = true
        statusLine = sceneReady && demoFlowState == .title
            ? "Demo briefing ready"
            : "Input focus captured"
        print("[Input] MTKView accepted first responder")
        rebuildOverlay()
    }

    func noteSceneReady(label: String, summary: String, details: [String]) {
        sceneLabel = label
        sceneSummary = summary
        sceneDetails = details
        sceneReady = true
        statusLine = "Demo briefing ready"
        rebuildOverlay()
    }

    func noteOverlayTitle(_ title: String) {
        overlayTitle = title
        rebuildOverlay()
    }

    func noteSceneBootstrap(
        label: String,
        summary: String,
        details: [String],
        overlayTitle: String,
        scopeConfiguration: ScopeConfiguration,
        ballisticsSettings: SceneBallisticsSettings,
        detectionFailThreshold: Float,
        mapConfiguration: SceneMapConfiguration
    ) {
        sceneLabel = label
        sceneSummary = summary
        sceneDetails = details
        sceneReady = true
        if demoFlowState == .title {
            statusLine = "Demo briefing ready"
        }
        self.overlayTitle = overlayTitle
        scopeLabel = scopeConfiguration.label ?? "4x Scope"
        scopeMagnification = max(scopeConfiguration.magnification, 1.0)
        scopeFieldOfViewDegrees = max(scopeConfiguration.fieldOfViewDegrees, 4.0)
        scopeLookSensitivityMultiplier = max(scopeConfiguration.lookSensitivityMultiplier ?? 0.26, 0.08)
        scopeDrawDistanceMultiplier = max(scopeConfiguration.drawDistanceMultiplier ?? 2.4, 1.0)
        scopeFarPlaneMultiplierValue = max(scopeConfiguration.farPlaneMultiplier ?? 1.35, 1.0)
        scopeReticleColorComponents = scopeConfiguration.reticleColorVector
        ballisticMuzzleVelocityMetersPerSecond = max(ballisticsSettings.muzzleVelocityMetersPerSecond, 40.0)
        ballisticGravityMetersPerSecondSquared = max(ballisticsSettings.gravityMetersPerSecondSquared, 0.1)
        ballisticMaxSimulationTimeSeconds = max(ballisticsSettings.maxSimulationTimeSeconds, 0.25)
        ballisticSimulationStepSeconds = max(ballisticsSettings.simulationStepSeconds, 1.0 / 480.0)
        ballisticLaunchHeightOffsetMeters = ballisticsSettings.launchHeightOffsetMeters
        self.detectionFailThreshold = max(detectionFailThreshold, 0.1)
        self.mapConfiguration = mapConfiguration
        updateAlternateRouteActivationLine(from: mapConfiguration)
        applyDifficultyPresetToCore(announceChange: false)
        rebuildOverlay()
    }

    func noteScopeConfiguration(_ configuration: ScopeConfiguration) {
        scopeLabel = configuration.label ?? "4x Scope"
        scopeMagnification = max(configuration.magnification, 1.0)
        scopeFieldOfViewDegrees = max(configuration.fieldOfViewDegrees, 4.0)
        scopeLookSensitivityMultiplier = max(configuration.lookSensitivityMultiplier ?? 0.26, 0.08)
        scopeDrawDistanceMultiplier = max(configuration.drawDistanceMultiplier ?? 2.4, 1.0)
        scopeFarPlaneMultiplierValue = max(configuration.farPlaneMultiplier ?? 1.35, 1.0)
        scopeReticleColorComponents = configuration.reticleColorVector
        rebuildOverlay()
    }

    func noteMapConfiguration(_ configuration: SceneMapConfiguration) {
        mapConfiguration = configuration
        updateAlternateRouteActivationLine(from: configuration)
        refreshOverheadMapSnapshot()
        rebuildOverlay()
    }

    private func updateAlternateRouteActivationLine(from configuration: SceneMapConfiguration) {
        if configuration.activeRouteID == configuration.selectedAlternateRouteID,
           let routeLabel = configuration.selectedAlternateRouteLabel {
            alternateRouteActivationLine = "Alternate Live Binding: active \(routeLabel) / checkpoints rebound"
            return
        }

        if alternateRouteActivationArmed, let routeLabel = configuration.selectedAlternateRouteLabel {
            alternateRouteActivationLine = "Alternate Live Binding: armed \(routeLabel) / waits for fresh-run boundary"
            return
        }

        alternateRouteActivationLine = "Alternate Live Binding: primary route active / alternate staged"
    }

    func setFreshRunHandler(_ handler: @escaping () -> Void) {
        freshRunHandler = handler
    }

    func noteFrameTiming(milliseconds: Double, framesPerSecond: Double, drawableCount: Int) {
        updateFrameTimingLine(
            milliseconds: milliseconds,
            framesPerSecond: framesPerSecond,
            drawableCount: drawableCount
        )
        rebuildOverlay()
    }

    func noteStreamingState(summary: String, details: [String]) {
        streamingSummary = summary
        streamingDetails = details
        rebuildOverlay()
    }

    func noteRouteState(summary: String, details: [String]) {
        routeSummary = summary
        routeDetails = details
        rebuildOverlay()
    }

    func noteBriefingState(summary: String, details: [String]) {
        briefingSummary = summary
        briefingDetails = details
        rebuildOverlay()
    }

    func noteEvasionState(summary: String, details: [String]) {
        evasionSummary = summary
        evasionDetails = details
        rebuildOverlay()
    }

    func startDemo() {
        guard sceneReady else {
            statusLine = "Scene data still loading"
            rebuildOverlay()
            return
        }

        isSettingsPresented = false
        if alternateRouteActivationArmed {
            freshRunHandler?()
        }
        demoFlowState = .playing
        let restoreTarget = manualRestoreChoiceTargetLabel
        if reviewedManualRestoreTargetLabel == restoreTarget {
            freshStartConfirmedRestoreTargetLabel = restoreTarget
        } else {
            freshStartConfirmedRestoreTargetLabel = nil
        }
        resetMissionRuntime()
        if let restoreTarget, freshStartConfirmedRestoreTargetLabel == restoreTarget {
            statusLine = "Fresh run started after reviewing \(restoreTarget) - restore remains disabled"
            sessionAudioState = "fresh start cue after restore review"
        } else {
            statusLine = "Demo live - move through the current Canberra contact lane and verify scoped hits"
            sessionAudioState = "fresh run basin bed armed"
        }
        scheduleGameplayInputFocusRecovery()
        rebuildOverlay()
    }

    func armAlternateRouteForNextFreshRun() {
        guard sceneReady else {
            statusLine = "Scene data still loading"
            rebuildOverlay()
            return
        }

        guard let routeLabel = mapConfiguration?.selectedAlternateRouteLabel else {
            statusLine = "No staged alternate route is available"
            rebuildOverlay()
            return
        }

        alternateRouteActivationArmed = true
        alternateRouteActivationLine = "Alternate Live Binding: armed \(routeLabel) / waits for fresh-run boundary"
        statusLine = "Alternate route armed for next Start Demo: \(routeLabel)"
        rebuildOverlay()
    }

    func consumeAlternateRouteActivationRequest() -> Bool {
        defer {
            alternateRouteActivationArmed = false
        }

        return alternateRouteActivationArmed
    }

    func previewManualRestoreChoice() {
        guard sceneReady else {
            statusLine = "Scene data still loading"
            rebuildOverlay()
            return
        }

        guard let targetLabel = manualRestoreChoiceTargetLabel else {
            statusLine = "No restorable review target is available"
            rebuildOverlay()
            return
        }

        reviewedManualRestoreTargetLabel = targetLabel
        restoreReviewExpiryLine = "Restore Review Expiry: tracking \(targetLabel) until target or boundary changes"
        statusLine = "Restore target reviewed: \(targetLabel) - Start Demo still begins fresh"
        rebuildOverlay()
    }

    func requestManualRestoreExecution() {
        guard sceneReady else {
            statusLine = "Scene data still loading"
            rebuildOverlay()
            return
        }

        guard let targetLabel = manualRestoreChoiceTargetLabel else {
            statusLine = "Manual restore blocked - no restorable checkpoint target"
            rebuildOverlay()
            return
        }

        guard reviewedManualRestoreTargetLabel == targetLabel else {
            reviewedManualRestoreTargetLabel = targetLabel
            restoreReviewExpiryLine = "Restore Review Expiry: tracking \(targetLabel) until explicit execution request"
            statusLine = "Restore target reviewed: \(targetLabel) - press Execute Restore again to run guarded restore"
            rebuildOverlay()
            return
        }

        guard let restoreProgress = manualRestoreExecutionProgress else {
            statusLine = "Manual restore blocked - identity, freshness, target, or intent check failed"
            rebuildOverlay()
            return
        }

        guard GameCoreRestoreToCheckpointProgress(Int32(restoreProgress)) else {
            statusLine = "Manual restore blocked by core checkpoint validation"
            rebuildOverlay()
            return
        }

        isSettingsPresented = false
        demoFlowState = .playing
        freshStartConfirmedRestoreTargetLabel = nil
        restoreBoundaryResetLine = "Restore Boundary Reset: restore executed for \(targetLabel) / review token consumed"
        restoreReviewExpiryLine = "Restore Review Expiry: consumed \(targetLabel) at guarded restore execution"
        clearGameplayInputState()
        refreshSnapshotFromCore()
        resetThreatFeedbackState()
        ShotFeedbackAudioEngine.shared.playScopeToggleCue(raised: false)
        ShotFeedbackAudioEngine.shared.playAmbientBasinBed()
        sessionAudioState = "manual restore cue + basin bed"
        statusLine = "Manual restore executed to \(targetLabel)"
        reviewedManualRestoreTargetLabel = nil
        rebuildOverlay()
    }

    func resumeDemo() {
        guard sceneReady else {
            return
        }

        isSettingsPresented = false
        demoFlowState = .playing
        clearGameplayInputState()
        statusLine = "Demo resumed"
        sessionAudioState = "resume keeps live mix"
        scheduleGameplayInputFocusRecovery()
        rebuildOverlay()
    }

    func retryFromCheckpoint() {
        guard sceneReady else {
            return
        }

        if latestSnapshot?.routeFailed ?? false {
            GameCoreClearFailure()
        }
        GameCoreRestartRoute()
        isSettingsPresented = false
        demoFlowState = .playing
        clearGameplayInputState()
        refreshSnapshotFromCore()
        resetThreatFeedbackState()
        statusLine = "Retry from latest checkpoint"
        sessionAudioState = "checkpoint retry mix reset"
        scheduleGameplayInputFocusRecovery()
        rebuildOverlay()
    }

    func restartMission() {
        guard sceneReady else {
            return
        }

        freshRunHandler?()
        isSettingsPresented = false
        demoFlowState = .playing
        clearManualRestoreReviewState(
            reason: "restart boundary",
            fallback: "Restore Boundary Reset: restart boundary clean / no restore review carried"
        )
        resetMissionRuntime()
        statusLine = "Demo restarted from a fresh rehearsal start"
        sessionAudioState = "restart fresh basin bed armed"
        scheduleGameplayInputFocusRecovery()
        rebuildOverlay()
    }

    func returnToBriefing() {
        guard sceneReady else {
            return
        }

        freshRunHandler?()
        isSettingsPresented = false
        demoFlowState = .title
        clearManualRestoreReviewState(
            reason: "briefing boundary",
            fallback: "Restore Boundary Reset: briefing boundary clean / no restore review carried"
        )
        resetMissionRuntime()
        statusLine = "Demo briefing ready"
        sessionAudioState = "briefing mix reset"
        rebuildOverlay()
    }

    func openSettings() {
        guard sceneReady else {
            return
        }

        isSettingsPresented = true
        clearGameplayInputState()
        statusLine = "Settings open"
        rebuildOverlay()
    }

    func closeSettings() {
        isSettingsPresented = false
        statusLine = statusLineForCurrentFlowState()
        scheduleGameplayInputFocusRecovery()
        rebuildOverlay()
    }

    func setHUDOpacity(_ value: Double) {
        hudOpacity = max(min(value, 1.0), 0.35)
        persistSettings()
        rebuildOverlay()
    }

    func setInvertLookY(_ value: Bool) {
        invertLookY = value
        persistSettings()
        rebuildOverlay()
    }

    func setLookSensitivityScale(_ value: Double) {
        lookSensitivityScale = max(min(value, 1.8), 0.6)
        persistSettings()
        applyLookSettings()
        rebuildOverlay()
    }

    func setDifficultyPreset(_ value: RehearsalDifficultyPreset) {
        guard difficultyPreset != value else {
            return
        }

        difficultyPreset = value
        persistSettings()
        applyDifficultyPresetToCore(announceChange: true)
        rebuildOverlay()
    }

    func setMapPresented(_ value: Bool) {
        guard mapConfiguration != nil else {
            isMapPresented = false
            if value {
                statusLine = sceneReady
                    ? "Canberra map unavailable in this scene"
                    : "Canberra map unlocks when Canberra finishes loading"
                rebuildOverlay()
            }
            return
        }

        guard isMapPresented != value else {
            return
        }

        isMapPresented = value
        statusLine = value ? "Canberra map opened" : statusLineForCurrentFlowState()
        if !value {
            scheduleGameplayInputFocusRecovery()
        }
        rebuildOverlay()
    }

    func handlePrimaryFireRequest() {
        if handleFireCommand() {
            rebuildOverlay()
        }
    }

    func handleKey(_ keyCode: UInt16, characters: String?, isPressed: Bool, isRepeat: Bool) {
        guard let command = InputBindings.command(for: keyCode, characters: characters) else {
            return
        }

        if isPressed, isRepeat, !command.isContinuous {
            return
        }

        if isPressed {
            switch command {
            case .pause:
                handlePauseToggle()
                print("[Input] \(command.label) pressed")
                rebuildOverlay()
                return
            case .toggleMap:
                setMapPresented(!isMapPresented)
                print("[Input] \(command.label) pressed")
                rebuildOverlay()
                return
            case .fire where handleFireCommand():
                print("[Input] \(command.label) pressed")
                rebuildOverlay()
                return
            case .interact where handleMenuPrimaryAction():
                print("[Input] \(command.label) pressed")
                rebuildOverlay()
                return
            case .interact where toggleScopeIfPossible():
                print("[Input] \(command.label) pressed")
                rebuildOverlay()
                return
            case .restart where handleMenuRestartAction():
                print("[Input] \(command.label) pressed")
                rebuildOverlay()
                return
            case _ where command.isContinuous && menuPanel == .title:
                startDemo()
            default:
                break
            }
        }

        guard allowsLiveGameplayInput else {
            if !isPressed, command.isContinuous, pressedCommands.remove(command) != nil {
                synchronizeMovementIntent()
                rebuildOverlay()
            }
            return
        }

        let changed: Bool
        if isPressed {
            changed = pressedCommands.insert(command).inserted
        } else {
            changed = pressedCommands.remove(command) != nil
        }

        guard changed else {
            return
        }

        switch command {
        case .restart where isPressed:
            if latestSnapshot?.routeFailed ?? false {
                GameCoreClearFailure()
            }
            GameCoreRestartRoute()
            lastMouseDelta = .zero
            shouldIgnoreNextMouseDelta = true
            refreshSnapshotFromCore()
            resetThreatFeedbackState()
            statusLine = (latestSnapshot?.routeFailed ?? false)
                ? "Retry triggered from checkpoint"
                : "Route restart triggered"
        default:
            statusLine = "\(command.label) \(isPressed ? "pressed" : "released")"
        }

        print("[Input] \(command.label) \(isPressed ? "pressed" : "released")")
        synchronizeMovementIntent()
        rebuildOverlay()
    }

    func handleMouseDelta(x: CGFloat, y: CGFloat) {
        guard allowsSceneTuningInput else {
            return
        }

        guard x != 0 || y != 0 else {
            return
        }

        if shouldIgnoreNextMouseDelta {
            shouldIgnoreNextMouseDelta = false
            lastMouseDelta = .zero
            rebuildOverlay()
            return
        }

        let adjustedY = invertLookY ? -y : y
        lastMouseDelta = CGSize(width: x, height: adjustedY)
        GameCoreAddLookDelta(Float(x), Float(adjustedY))
    }

    func refreshContinuousInputForSimulation() {
        guard allowsSceneTuningInput else {
            return
        }

        synchronizeMovementIntent()
    }

    func updateViewport(size: CGSize) {
        viewportSize = size
        rebuildOverlay()
    }

    func accept(snapshot: GameFrameSnapshot, drawableSize: CGSize) {
        captureBaseTraversalIfNeeded(from: snapshot)

        if demoFlowState == .playing {
            if snapshot.routeFailed && !routeWasFailed {
                demoFlowState = .failed
                clearGameplayInputState()
                statusLine = "Compromised - choose retry or restart"
            } else if snapshot.routeComplete && !routeWasComplete {
                demoFlowState = .complete
                clearGameplayInputState()
                statusLine = "Survey route complete"
            } else if Int(snapshot.completedCheckpointCount) > completedCheckpointCount {
                statusLine = "Checkpoint \(snapshot.completedCheckpointCount) reached"
            }
        }

        completedCheckpointCount = Int(snapshot.completedCheckpointCount)
        routeWasComplete = snapshot.routeComplete
        routeWasFailed = snapshot.routeFailed
        latestSnapshot = snapshot
        refreshObserverDebugStatesFromCore()
        maintainRealtimeSessionHealth(for: snapshot)
        applyThreatAudioFeedback(for: snapshot)
        applyWorldMovementAudioFeedback(for: snapshot)
        viewportSize = drawableSize
        refreshOverheadMapSnapshot()
        persistReviewSessionState(from: snapshot)
        rebuildOverlay()
    }

    func applyRendererUpdate(
        snapshot: GameFrameSnapshot,
        ballisticPrediction: GameBallisticPrediction,
        profiling: GameProfilingSnapshot,
        drawableSize: CGSize,
        briefing: (summary: String, details: [String]),
        route: (summary: String, details: [String]),
        evasion: (summary: String, details: [String]),
        streaming: (summary: String, details: [String]),
        frameTiming: (milliseconds: Double, framesPerSecond: Double, drawableCount: Int)?
    ) {
        captureBaseTraversalIfNeeded(from: snapshot)

        if demoFlowState == .playing {
            if snapshot.routeFailed && !routeWasFailed {
                demoFlowState = .failed
                clearGameplayInputState()
                statusLine = "Compromised - choose retry or restart"
            } else if snapshot.routeComplete && !routeWasComplete {
                demoFlowState = .complete
                clearGameplayInputState()
                statusLine = "Survey route complete"
            } else if Int(snapshot.completedCheckpointCount) > completedCheckpointCount {
                statusLine = "Checkpoint \(snapshot.completedCheckpointCount) reached"
            }
        }

        completedCheckpointCount = Int(snapshot.completedCheckpointCount)
        routeWasComplete = snapshot.routeComplete
        routeWasFailed = snapshot.routeFailed
        latestSnapshot = snapshot
        latestBallisticPrediction = ballisticPrediction
        latestProfilingSnapshot = profiling
        refreshObserverDebugStatesFromCore()
        maintainRealtimeSessionHealth(for: snapshot)
        applyThreatAudioFeedback(for: snapshot)
        applyWorldMovementAudioFeedback(for: snapshot)
        viewportSize = drawableSize
        briefingSummary = briefing.summary
        briefingDetails = briefing.details
        routeSummary = route.summary
        routeDetails = route.details
        evasionSummary = evasion.summary
        evasionDetails = evasion.details
        streamingSummary = streaming.summary
        streamingDetails = streaming.details

        if let frameTiming {
            updateFrameTimingLine(
                milliseconds: frameTiming.milliseconds,
                framesPerSecond: frameTiming.framesPerSecond,
                drawableCount: frameTiming.drawableCount
            )
        }

        refreshOverheadMapSnapshot()
        persistReviewSessionState(from: snapshot)
        rebuildOverlay()
    }

    private func maintainRealtimeSessionHealth(for snapshot: GameFrameSnapshot) {
        guard sceneReady, demoFlowState == .playing, menuPanel == nil else {
            return
        }

        guard snapshot.elapsedSeconds - lastRealtimeRecoveryElapsedSeconds >= 1.0 else {
            return
        }

        lastRealtimeRecoveryElapsedSeconds = snapshot.elapsedSeconds
        ShotFeedbackAudioEngine.shared.recoverIfNeeded()
        sessionAudioState = "live recovery heartbeat armed"
    }

    func applyRendererFrameTimingUpdate(milliseconds: Double, framesPerSecond: Double, drawableCount: Int) {
        updateFrameTimingLine(
            milliseconds: milliseconds,
            framesPerSecond: framesPerSecond,
            drawableCount: drawableCount
        )
        rebuildOverlay()
    }

    func resetDebugState() {
        GameCoreResetDebugState()
        clearGameplayInputState()
        demoFlowState = .title
        isSettingsPresented = false
        refreshSnapshotFromCore()
        resetThreatFeedbackState()
        statusLine = "Demo briefing ready"
        rebuildOverlay()
    }

    private func handleFireCommand() -> Bool {
        guard sceneReady, menuPanel == nil, demoFlowState == .playing else {
            return false
        }

        let feedback = GameCoreRequestFire()
        refreshSnapshotFromCore()

        if feedback.fired {
            ShotFeedbackAudioEngine.shared.playShotCue(cooldownSeconds: Double(feedback.cooldownSeconds))
            if feedback.hitObserver {
                let confirmDelay = min(max(Double(feedback.prediction.flightTimeSeconds) * 0.22, 0.02), 0.26)
                ShotFeedbackAudioEngine.shared.playHitConfirmCue(after: confirmDelay)
            } else if feedback.prediction.hitCollisionVolume || feedback.prediction.hitGround {
                let impactDelay = min(max(Double(feedback.prediction.flightTimeSeconds) * 0.18, 0.03), 0.24)
                ShotFeedbackAudioEngine.shared.playImpactCue(after: impactDelay)
            }
            statusLine = shotStatusLine(for: feedback)
        } else if feedback.rejected {
            ShotFeedbackAudioEngine.shared.playDryClickCue()
            statusLine = String(
                format: "Trigger busy - %.2fs remaining on the rifle cycle",
                max(feedback.cooldownSeconds, 0)
            )
        } else {
            return false
        }

        return true
    }

    private func shotStatusLine(for feedback: GameShotFeedback) -> String {
        let distance = feedback.prediction.travelDistanceMeters
        let stabilityPercent = Int((scopedWeaponStability * 100).rounded())
        if feedback.hitObserver {
            let targetLabel = observerLabel(for: feedback.observerIndex) ?? "observer contact"
            let remainingObservers = max((latestSnapshot?.totalObserverCount ?? 0) - feedback.neutralizedObserverCount, 0)
            return String(
                format: "Shot %d confirmed %@ at %.0fm - %d contacts still live - %d%% stable",
                feedback.shotCount,
                targetLabel,
                distance,
                remainingObservers,
                stabilityPercent
            )
        }

        if feedback.prediction.hitCollisionVolume {
            return String(
                format: "Shot %d broke on a blocker at %.0fm - %d%% stable",
                feedback.shotCount,
                distance,
                stabilityPercent
            )
        }

        if feedback.prediction.hitGround {
            return String(
                format: "Shot %d impacted ground at %.0fm - %d%% stable",
                feedback.shotCount,
                distance,
                stabilityPercent
            )
        }

        return String(
            format: "Shot %d held clear to %.0fm - %d%% stable",
            feedback.shotCount,
            distance,
            stabilityPercent
        )
    }

    private func handlePauseToggle() {
        if isSettingsPresented {
            closeSettings()
            return
        }

        guard sceneReady else {
            return
        }

        switch demoFlowState {
        case .playing:
            demoFlowState = .paused
            clearGameplayInputState()
            statusLine = "Demo paused"
        case .paused:
            resumeDemo()
        case .title, .failed, .complete:
            break
        }
    }

    private func handleMenuPrimaryAction() -> Bool {
        guard let panel = menuPanel else {
            return false
        }

        switch panel {
        case .title:
            startDemo()
        case .paused:
            resumeDemo()
        case .failed:
            retryFromCheckpoint()
        case .complete:
            restartMission()
        case .settings:
            closeSettings()
        }

        return true
    }

    private func handleMenuRestartAction() -> Bool {
        guard let panel = menuPanel else {
            return false
        }

        switch panel {
        case .title:
            startDemo()
        case .paused, .failed, .complete:
            restartMission()
        case .settings:
            return false
        }

        return true
    }

    private func resetMissionRuntime() {
        GameCoreResetDebugState()
        clearGameplayInputState()
        refreshSnapshotFromCore()
        resetThreatFeedbackState()
    }

    private func clearGameplayInputState() {
        pressedCommands.removeAll()
        isScopeActive = false
        lastMouseDelta = .zero
        shouldIgnoreNextMouseDelta = true
        GameCoreSetMoveIntent(0, 0)
        GameCoreSetSprint(false)
        GameCoreSetWeaponSteady(false)
        GameCoreSetWeaponScoped(false)
        applyLookSettings()
    }

    private func refreshSnapshotFromCore() {
        let snapshot = GameCoreGetSnapshot()
        captureBaseTraversalIfNeeded(from: snapshot)
        latestSnapshot = snapshot
        latestBallisticPrediction = GameCoreGetBallisticPrediction()
        latestProfilingSnapshot = GameCoreGetProfilingSnapshot()
        refreshObserverDebugStatesFromCore()
        applyThreatAudioFeedback(for: snapshot)
        completedCheckpointCount = Int(snapshot.completedCheckpointCount)
        routeWasComplete = snapshot.routeComplete
        routeWasFailed = snapshot.routeFailed
        refreshOverheadMapSnapshot()
    }

    private func applyDifficultyPresetToCore(announceChange: Bool) {
        GameCoreConfigureDifficulty(difficultyPreset.coreTuning)
        refreshSnapshotFromCore()
        resetThreatFeedbackState()

        if announceChange {
            statusLine = "\(difficultyPreset.displayName) field tuning engaged"
        }
    }

    private func updateFrameTimingLine(milliseconds: Double, framesPerSecond: Double, drawableCount: Int) {
        frameTimingLine = String(
            format: "Frame: %.2f ms / %.1f fps / %d drawables",
            milliseconds,
            framesPerSecond,
            drawableCount
        )
    }

    private func captureBaseTraversalIfNeeded(from snapshot: GameFrameSnapshot) {
        guard baseWalkSpeed == nil || baseSprintSpeed == nil || baseLookSensitivity == nil else {
            return
        }

        baseWalkSpeed = snapshot.walkSpeed
        baseSprintSpeed = snapshot.sprintSpeed
        baseLookSensitivity = snapshot.lookSensitivity

        if abs(lookSensitivityScale - 1.0) > 0.001 {
            applyLookSettings()
        }
    }

    private func applyLookSettings() {
        guard
            let walkSpeed = baseWalkSpeed,
            let sprintSpeed = baseSprintSpeed,
            let baseLookSensitivity = baseLookSensitivity
        else {
            return
        }

        GameCoreConfigureTraversal(
            walkSpeed,
            sprintSpeed,
            baseLookSensitivity * Float(lookSensitivityScale) * (isScopeActive ? scopeLookSensitivityMultiplier : 1.0)
        )
        refreshSnapshotFromCore()
    }

    private func toggleScopeIfPossible() -> Bool {
        guard sceneReady, demoFlowState == .playing, menuPanel == nil else {
            return false
        }

        isScopeActive.toggle()
        GameCoreSetWeaponScoped(isScopeActive)
        ShotFeedbackAudioEngine.shared.playScopeToggleCue(raised: isScopeActive)
        lastScopeAudioState = isScopeActive ? "scope raised cue" : "scope lowered cue"
        if isScopeActive {
            GameCoreSetWeaponSteady(pressedCommands.contains(.steadyAim))
        } else {
            GameCoreSetWeaponSteady(false)
        }
        applyLookSettings()
        statusLine = isScopeActive
            ? String(format: "%.1fx scope active", scopeMagnification)
            : String(format: "%.1fx scope lowered", scopeMagnification)
        return true
    }

    private func synchronizeMovementIntent() {
        let strafe = axisValue(negative: .strafeLeft, positive: .strafeRight)
        let forward = axisValue(negative: .backward, positive: .forward)

        GameCoreSetMoveIntent(strafe, forward)
        GameCoreSetSprint(pressedCommands.contains(.sprint))
        GameCoreSetWeaponSteady(pressedCommands.contains(.steadyAim))
    }

    private func axisValue(negative: InputCommand, positive: InputCommand) -> Float {
        var value: Float = 0
        if pressedCommands.contains(negative) {
            value -= 1
        }
        if pressedCommands.contains(positive) {
            value += 1
        }
        return value
    }

    private func titlePanelLines() -> [String] {
        let riskLine: String
        if evasionSummary == "Evasion: unavailable" {
            riskLine = "Threats: no live opposition in this preview; focus on Canberra scale, streaming, and sightlines."
        } else {
            riskLine = "Threats: active observers can still trigger a checkpoint fallback if the route enters an exposed lane."
        }
        let objectiveLine: String
        if let routeObjective = routeDetails.first, routeObjective.hasPrefix("Objective:") {
            objectiveLine = routeObjective
        } else {
            objectiveLine = "Objective: rehearse the current Canberra contact lanes and move through the authored markers from the assigned start."
        }

        var lines = [
            objectiveLine,
            String(format: "Priority: keep the authored districts readable at %.1fx while validating skyline layering, streaming handoff, and route continuity.", scopeMagnification),
            riskLine,
            "Release: \(configuration.releaseDisplayName) / \(configuration.bundleIdentifier)",
            "Content: \(configuration.contentSourceSummary)",
            String(format: "Optic: %.1fx scope ready for live contact and skyline markers.", scopeMagnification),
            "Locator: press M at any time to raise the Canberra map.",
            "Deploy: press Space or Return, then use Esc at any time for the pause shell.",
        ]

        let planningLines = sceneDetails.filter { detail in
            detail.hasPrefix("Plan:")
                || detail.hasPrefix("Breakdown:")
                || detail.hasPrefix("Reference:")
        }
        lines.append(contentsOf: planningLines.prefix(3))
        if let storedReviewSessionLine {
            lines.append(storedReviewSessionLine)
        }
        if let storedReviewResumeLine {
            lines.append(storedReviewResumeLine)
        }
        if let storedReviewGuardrailLine {
            lines.append(storedReviewGuardrailLine)
        }
        if let storedReviewRestorePreviewLine {
            lines.append(storedReviewRestorePreviewLine)
        }
        if let storedReviewRestoreReadinessLine {
            lines.append(storedReviewRestoreReadinessLine)
        }
        if let storedReviewManualRestoreArmingLine {
            lines.append(storedReviewManualRestoreArmingLine)
        }
        if let storedReviewManualRestorePromptLine {
            lines.append(storedReviewManualRestorePromptLine)
        }
        if let storedReviewManualRestoreChoiceLine {
            lines.append(storedReviewManualRestoreChoiceLine)
        }
        if let storedReviewManualRestoreSelectionLine {
            lines.append(storedReviewManualRestoreSelectionLine)
        }
        if let storedReviewRestoreFreshStartGuardLine {
            lines.append(storedReviewRestoreFreshStartGuardLine)
        }
        lines.append(restoreBoundaryResetLine)
        lines.append(restoreReviewExpiryLine)
        lines.append(restoreReviewScopeLine)
        lines.append(restoreReviewExecutionIntentLine)
        if let storedReviewRestoreExecutionGateLine {
            lines.append(storedReviewRestoreExecutionGateLine)
        }
        if let storedReviewRestoreAuditLine {
            lines.append(storedReviewRestoreAuditLine)
        }
        if let storedReviewRestoreFreshnessLine {
            lines.append(storedReviewRestoreFreshnessLine)
        }
        if let storedReviewRestoreRetentionLine {
            lines.append(storedReviewRestoreRetentionLine)
        }
        if let storedReviewRestoreCleanupPreviewLine {
            lines.append(storedReviewRestoreCleanupPreviewLine)
        }
        lines.append(restoreCleanupExecutionLine)
        let reviewLines = sceneDetails.filter { detail in
            detail.hasPrefix("Review Pack:")
                || detail.hasPrefix("Reference Pack:")
                || detail.hasPrefix("Capture Framing:")
                || detail.hasPrefix("Texture Audit:")
        }
        lines.append(contentsOf: reviewLines.prefix(3))
        let combatLines = sceneDetails.filter { detail in
            detail.hasPrefix("Combat Rehearsal:")
                || detail.hasPrefix("Exposure Guide:")
                || detail.hasPrefix("Recovery Rule:")
        }
        lines.append(contentsOf: combatLines.prefix(2))

        if sceneReady {
            lines.append("Route: \(routeSummary)")
            lines.append(briefingDetails.first ?? routeSummary)
            if let activeRouteLine = routeDetails.first(where: { $0.hasPrefix("Active Route:") }) {
                lines.append(activeRouteLine)
            }
            if let validationLine = routeDetails.first(where: { $0.hasPrefix("Route Validation:") }) {
                lines.append(validationLine)
            }
            if let selectionLine = routeDetails.first(where: { $0.hasPrefix("Route Selection:") }) {
                lines.append(selectionLine)
            }
            if let activationLine = routeDetails.first(where: { $0.hasPrefix("Route Activation:") }) {
                lines.append(activationLine)
            }
            if let rollbackLine = routeDetails.first(where: { $0.hasPrefix("Route Rollback:") }) {
                lines.append(rollbackLine)
            }
            if let commitLine = routeDetails.first(where: { $0.hasPrefix("Route Commit:") }) {
                lines.append(commitLine)
            }
            if let dryRunLine = routeDetails.first(where: { $0.hasPrefix("Route Dry Run:") }) {
                lines.append(dryRunLine)
            }
            if let promotionLine = routeDetails.first(where: { $0.hasPrefix("Route Promotion:") }) {
                lines.append(promotionLine)
            }
            if let auditLine = routeDetails.first(where: { $0.hasPrefix("Route Audit:") }) {
                lines.append(auditLine)
            }
            if let boundaryLine = routeDetails.first(where: { $0.hasPrefix("Route Boundary:") }) {
                lines.append(boundaryLine)
            }
            if let armingLine = routeDetails.first(where: { $0.hasPrefix("Route Arming:") }) {
                lines.append(armingLine)
            }
            if let confirmationLine = routeDetails.first(where: { $0.hasPrefix("Route Confirmation:") }) {
                lines.append(confirmationLine)
            }
            if let releaseLine = routeDetails.first(where: { $0.hasPrefix("Route Release:") }) {
                lines.append(releaseLine)
            }
            if let preflightLine = routeDetails.first(where: { $0.hasPrefix("Route Preflight:") }) {
                lines.append(preflightLine)
            }
            if let handoffLine = routeDetails.first(where: { $0.hasPrefix("Route Handoff:") }) {
                lines.append(handoffLine)
            }
            if let collisionAuthoringLine = routeDetails.first(where: { $0.hasPrefix("Collision Authoring:") }) {
                lines.append(collisionAuthoringLine)
            }
            if let environmentalMotionLine = routeDetails.first(where: { $0.hasPrefix("Environmental Motion:") }) {
                lines.append(environmentalMotionLine)
            }
            if let surfaceFidelityLine = routeDetails.first(where: { $0.hasPrefix("Surface Fidelity:") }) {
                lines.append(surfaceFidelityLine)
            }
            if let sessionPersistenceLine = routeDetails.first(where: { $0.hasPrefix("Session Persistence:") }) {
                lines.append(sessionPersistenceLine)
            }
            if let selectionLine = routeDetails.first(where: { $0.hasPrefix("Selection:") }) {
                lines.append(selectionLine)
            }
            if let ownershipLine = routeDetails.first(where: { $0.hasPrefix("Ownership:") }) {
                lines.append(ownershipLine)
            }
            if let stagedRouteLine = routeDetails.first(where: { $0.hasPrefix("Staged Route:") }) {
                lines.append(stagedRouteLine)
            }
            if let bindingGateLine = routeDetails.first(where: { $0.hasPrefix("Binding Gate:") }) {
                lines.append(bindingGateLine)
            }
            if let contactLine = routeDetails.first(where: { $0.hasPrefix("Contact:") || $0.hasPrefix("Compare:") || $0.hasPrefix("Capture:") }) {
                lines.append(contactLine)
            } else if briefingDetails.count > 1 {
                lines.append(briefingDetails[1])
            }
            lines.append("Slice: \(sceneSummary)")
        } else {
            lines.append("Slice: waiting for Canberra data and renderer state")
        }

        return lines
    }

    private func pausedPanelLines() -> [String] {
        let contactLine = routeDetails.first(where: { $0.hasPrefix("Contact:") })
        let coverLine = routeDetails.first(where: { $0.hasPrefix("Cover:") })
        let compareLine = routeDetails.first(where: { $0.hasPrefix("Compare:") })
        let captureLine = routeDetails.first(where: { $0.hasPrefix("Capture:") })
        let persistenceLine = routeDetails.first(where: { $0.hasPrefix("Session Persistence:") })
        return [
            briefingSummary,
            routeSummary,
            contactLine ?? compareLine ?? routeDetails.first(where: { $0.hasPrefix("Next:") }) ?? "Next: continue through the current rehearsal markers.",
            coverLine ?? captureLine ?? sceneDetails.first(where: { $0.hasPrefix("Recovery Rule:") || $0.hasPrefix("Capture Framing:") }) ?? "Capture: keep the next district marker and atlas cues in frame.",
            persistenceLine ?? "Session Persistence: pending / resume keeps the current live shell only.",
            evasionDetails.first ?? "Threats: preview pressure and world updates are frozen while paused.",
            String(format: "Scope: %.1fx optic %@.", scopeMagnification, isScopeActive ? "was active before the pause shell" : "can be raised again when live"),
            "Resume keeps the current rehearsal live. Restart rolls a fresh rehearsal start.",
        ]
    }

    private func failedPanelLines() -> [String] {
        let snapshot = latestSnapshot
        let contactLine = routeDetails.first(where: { $0.hasPrefix("Contact:") })
        let coverLine = routeDetails.first(where: { $0.hasPrefix("Cover:") })
        return [
            String(
                format: "Threats: %.2f suspicion / %d failures / %d observers seeing",
                snapshot?.suspicionLevel ?? 0,
                snapshot?.failCount ?? 0,
                snapshot?.seeingObserverCount ?? 0
            ),
            routeSummary,
            contactLine ?? routeDetails.first(where: { $0.hasPrefix("Next:") }) ?? "Next: the latest checkpoint remains available for retry.",
            coverLine ?? sceneDetails.first(where: { $0.hasPrefix("Recovery Rule:") }) ?? "Recovery: use cover, then re-enter the rehearsal lane from the last checkpoint.",
            "Retry restarts from the most recent checkpoint. Restart rolls a fresh rehearsal start.",
            "Return to Briefing resets the run and leaves the demo at the title shell.",
        ]
    }

    private func completePanelLines() -> [String] {
        let snapshot = latestSnapshot
        return [
            routeSummary,
            String(
                format: "Run: %.1fs / %.0fm / %d restarts",
                snapshot?.elapsedSeconds ?? 0,
                snapshot?.routeDistanceMeters ?? 0,
                snapshot?.restartCount ?? 0
            ),
            sceneDetails.first(where: { $0.hasPrefix("Review Pack:") }) ?? "Review Pack: final review pack data unavailable.",
            sceneDetails.first(where: { $0.hasPrefix("Combat Rehearsal:") }) ?? "Combat Rehearsal: final rehearsal data unavailable.",
            routeDetails.first(where: { $0.hasPrefix("Session Persistence:") }) ?? "Session Persistence: pending / completion review state not yet persisted.",
            "Outcome: the current Canberra line now reads as one contact rehearsal with live observer pressure and explicit recovery cues across the full route.",
            "Release: \(configuration.releaseDisplayName) / \(configuration.contentSourceSummary)",
            String(format: "Optic: %.1fx scoped review remained available across the full route.", scopeMagnification),
            "Script: title shell, live contact route, optional fail or retry loop, and completion summary all resolve in one session.",
            "New Run restarts the rehearsal immediately from a fresh contact-lane start. Briefing returns to the title shell.",
        ]
    }

    private func settingsPanelLines() -> [String] {
        [
            String(
                format: "Difficulty: %@ / fail %.2f / observer x%.2f / decay x%.2f / cycle x%.2f",
                difficultyPreset.displayName,
                effectiveDetectionFailThreshold,
                difficultyPreset.observerSuspicionScale,
                difficultyPreset.suspicionDecayScale,
                difficultyPreset.weaponCycleScale
            ),
            String(format: "Look scale: %.2fx of the authored cycle tuning", lookSensitivityScale),
            "Invert Y: \(invertLookY ? "enabled" : "disabled")",
            String(format: "Scope: %.1fx / %.1f deg / x%.1f draw", scopeMagnification, scopeFieldOfViewDegrees, scopeDrawDistanceMultiplier),
            "Map: \(isMapPresented ? "open" : "hidden") / \(currentMapSectorName)",
            String(format: "HUD opacity: %.0f%%", hudOpacity * 100),
            "Build: \(configuration.releaseDisplayName)",
            "Bundle: \(configuration.bundleIdentifier)",
            "Content: \(configuration.contentSourceSummary)",
            difficultyPreset.summary,
            "These settings persist between launches.",
        ]
    }

    private func statusLineForCurrentFlowState() -> String {
        switch demoFlowState {
        case .title:
            return "Demo briefing ready"
        case .playing:
            return isScopeActive
                ? String(format: "%.1fx scope active - confirm distant contacts", scopeMagnification)
                : "Demo live - move through the current Canberra contact lane and verify scoped hits"
        case .paused:
            return "Demo paused"
        case .failed:
            return "Compromised - choose retry or restart"
        case .complete:
            return "Combat rehearsal complete"
        }
    }

    private func ballisticsProfileLine() -> String {
        let sampleRate = max(1.0 / max(ballisticSimulationStepSeconds, 1.0 / 480.0), 1.0)
        return String(
            format: "Ballistics Profile: %.0f m/s / %.2f m/s2 / %.2fs / %.0f Hz / %+0.2fm launch",
            ballisticMuzzleVelocityMetersPerSecond,
            ballisticGravityMetersPerSecondSquared,
            ballisticMaxSimulationTimeSeconds,
            sampleRate,
            ballisticLaunchHeightOffsetMeters
        )
    }

    private func ballisticsPredictionLine() -> String {
        guard let prediction = latestBallisticPrediction, prediction.valid else {
            return "Ballistics: prediction unavailable"
        }

        if prediction.hitObserver {
            let targetLabel = observerLabel(for: prediction.observerIndex) ?? "observer contact"
            return String(
                format: "Ballistics: %@ %.0fm / %.2fs / %.2fm drop / %d steps",
                targetLabel,
                prediction.travelDistanceMeters,
                prediction.flightTimeSeconds,
                prediction.dropMeters,
                prediction.simulationStepCount
            )
        }

        if prediction.hitCollisionVolume {
            return String(
                format: "Ballistics: blocker %.0fm / %.2fs / %.2fm drop / %d steps",
                prediction.travelDistanceMeters,
                prediction.flightTimeSeconds,
                prediction.dropMeters,
                prediction.simulationStepCount
            )
        }

        if prediction.hitGround {
            return String(
                format: "Ballistics: ground %.0fm / %.2fs / %.2fm drop / %d steps",
                prediction.travelDistanceMeters,
                prediction.flightTimeSeconds,
                prediction.dropMeters,
                prediction.simulationStepCount
            )
        }

        return String(
            format: "Ballistics: clear to %.0fm / %.2fs / %.2fm drop / %d steps",
            prediction.travelDistanceMeters,
            prediction.flightTimeSeconds,
            prediction.dropMeters,
            prediction.simulationStepCount
        )
    }

    private func weaponStatusLine() -> String {
        guard let snapshot = latestSnapshot else {
            return "Weapon: waiting for live rifle telemetry"
        }

        let cycleStatus = snapshot.weaponCooldownSeconds > 0.01
            ? String(format: "bolting %.2fs", snapshot.weaponCooldownSeconds)
            : "ready"

        guard snapshot.shotCount > 0, snapshot.lastShotElapsedSeconds >= 0 else {
            return String(
                format: "Weapon: %@ / %.2fs bolt cycle / no shots fired",
                cycleStatus,
                snapshot.weaponCycleSeconds
            )
        }

        let lastResult: String
        if snapshot.lastShotHitObserver {
            let targetLabel = observerLabel(for: snapshot.lastShotObserverIndex) ?? "observer"
            return String(
                format: "Weapon: %@ / %d shots / last hit %@ %.0fm",
                cycleStatus,
                snapshot.shotCount,
                targetLabel,
                snapshot.lastShotObserverDistanceMeters
            )
        } else if snapshot.lastShotHitCollisionVolume {
            lastResult = "blocker"
        } else if snapshot.lastShotHitGround {
            lastResult = "ground"
        } else {
            lastResult = "clear"
        }

        return String(
            format: "Weapon: %@ / %d shots / last %@ %.0fm in %.2fs",
            cycleStatus,
            snapshot.shotCount,
            lastResult,
            snapshot.lastShotTravelDistanceMeters,
            snapshot.lastShotFlightTimeSeconds
        )
    }

    private func muzzleFeedbackLine() -> String {
        guard let snapshot = latestSnapshot else {
            return "Muzzle Feedback: waiting for live rifle telemetry"
        }

        guard snapshot.shotCount > 0, snapshot.lastShotElapsedSeconds >= 0 else {
            return "Muzzle Feedback: flash idle placeholder / recoil settled / no shot trace"
        }

        let shotAgeSeconds = max(snapshot.elapsedSeconds - snapshot.lastShotElapsedSeconds, 0)
        let flashPercent = Int((max(1.0 - (shotAgeSeconds / 0.18), 0) * 100).rounded())
        let recoveryDurationSeconds = max(Double(snapshot.weaponCycleSeconds) * 0.85, 0.25)
        let recoilPercent = Int((max(1.0 - (shotAgeSeconds / recoveryDurationSeconds), 0) * 100).rounded())
        let recoilState = snapshot.weaponCooldownSeconds > 0.01
            ? String(format: "recovering %.2fs", snapshot.weaponCooldownSeconds)
            : "settled"
        let resultLabel: String
        if snapshot.lastShotHitObserver {
            resultLabel = observerLabel(for: snapshot.lastShotObserverIndex) ?? "observer hit"
        } else if snapshot.lastShotHitCollisionVolume {
            resultLabel = "blocker strike"
        } else if snapshot.lastShotHitGround {
            resultLabel = "ground strike"
        } else {
            resultLabel = "clear miss"
        }

        return String(
            format: "Muzzle Feedback: flash %d%% placeholder / recoil %d%% %@ / last %@ %.0fm",
            flashPercent,
            recoilPercent,
            recoilState,
            resultLabel,
            snapshot.lastShotTravelDistanceMeters
        )
    }

    private func threatStatusLine() -> String {
        guard let snapshot = latestSnapshot else {
            return "Threat: waiting for live observer state"
        }

        let liveObserverCount = max(snapshot.totalObserverCount - snapshot.neutralizedObserverCount, 0)
        if let threatObserver = primarySeeingObserver {
            return String(
                format: "Threat: %@ sees you at %.0fm / %.2f suspicion / %d live",
                threatObserver.label,
                threatObserver.distanceMeters,
                snapshot.suspicionLevel,
                liveObserverCount
            )
        }

        if let alertedObserver = primaryAlertedObserver {
            return String(
                format: "Threat: %@ alerted / %.1fs memory / %d live / %d watching",
                alertedObserver.label,
                alertedObserver.alertSecondsRemaining,
                liveObserverCount,
                snapshot.alertedObserverCount
            )
        }

        if snapshot.lastShotHitObserver, let targetLabel = observerLabel(for: snapshot.lastShotObserverIndex) {
            return String(
                format: "Threat: %d live / %d neutralized / last %@",
                liveObserverCount,
                snapshot.neutralizedObserverCount,
                targetLabel
            )
        }

        return String(
            format: "Threat: %d live / %d neutralized / %d alerted / %d seeing / %d in range",
            liveObserverCount,
            snapshot.neutralizedObserverCount,
            snapshot.alertedObserverCount,
            snapshot.seeingObserverCount,
            snapshot.activeObserverCount
        )
    }

    private func observerFeedbackLine() -> String {
        guard let snapshot = latestSnapshot else {
            return "Observer Feedback: waiting for audio-state telemetry"
        }

        let relayCount = latestObserverDebugStates.filter { $0.supportingGroup && !$0.neutralized }.count
        let maskedCount = latestObserverDebugStates.filter {
            !$0.neutralized && $0.inRange && $0.inViewCone && !$0.hasLineOfSight
        }.count

        return String(
            format: "Observer Feedback: %@ audio / %d relay / %d masked / %.2f suspicion",
            threatAudibleState(for: snapshot),
            relayCount,
            maskedCount,
            snapshot.suspicionLevel
        )
    }

    private func worldMovementAudioLine() -> String {
        guard let snapshot = latestSnapshot else {
            return "World Audio: waiting for movement and basin mix"
        }

        return String(
            format: "World Audio: %@ / %@ / %@ / threat %@ / speed %.2f",
            lastMovementAudioState,
            lastScopeAudioState,
            lastWorldAudioState,
            threatAudibleState(for: snapshot),
            snapshot.moveSpeed
        )
    }

    private func scopeCalibrationLine() -> String {
        guard let snapshot = latestSnapshot else {
            return "Scope Calibration: waiting for live optic telemetry"
        }

        let prediction = latestBallisticPrediction
        let rangeMeters = prediction?.valid == true
            ? max(prediction?.travelDistanceMeters ?? 0, 0)
            : max(snapshot.lastShotTravelDistanceMeters, 0)
        let dropMeters = prediction?.valid == true
            ? max(prediction?.dropMeters ?? 0, 0)
            : max(snapshot.lastShotDropMeters, 0)
        let holdoverMils = rangeMeters > 1
            ? dropMeters / max(rangeMeters / 1000.0, 0.001)
            : 0
        let parallaxPercent = Int((simd_clamp(scopedWeaponSpreadDegrees / 1.6, 0.0, 1.0) * 100).rounded())
        let edgeStabilityPercent = Int((simd_clamp(scopedWeaponStability - (scopedWeaponSpreadDegrees * 0.08), 0.0, 1.0) * 100).rounded())
        let breathCue = steadyAimActive
            ? String(format: "breath held %.1fs", holdBreathSecondsRemaining)
            : "breath drifting"

        return String(
            format: "Scope Calibration: %.0fm range / %.2fm drop / %.1f mil hold / parallax %d%% / edge %d%% / %@",
            rangeMeters,
            dropMeters,
            holdoverMils,
            parallaxPercent,
            edgeStabilityPercent,
            breathCue
        )
    }

    private func vegetationConcealmentLine() -> String {
        guard let snapshot = latestSnapshot else {
            return "Vegetation Concealment: waiting for movement and observer telemetry"
        }

        let sectorName = currentMapSectorName
        let sectorHasVegetation = sectorName.localizedCaseInsensitiveContains("Yarralumla")
            || sectorName.localizedCaseInsensitiveContains("West Basin")
            || sectorName.localizedCaseInsensitiveContains("Black Mountain")
            || sectorName.localizedCaseInsensitiveContains("Woden Valley")
        let sceneVegetationActive = mapConfiguration?.environmentalMotionStatus.localizedCaseInsensitiveContains("vegetation") == true
            || mapConfiguration?.surfaceFidelityStatus.localizedCaseInsensitiveContains("vegetation") == true
        let maskedCount = latestObserverDebugStates.filter {
            !$0.neutralized && $0.inRange && $0.inViewCone && !$0.hasLineOfSight
        }.count
        let concealmentState: String
        if sectorHasVegetation && snapshot.seeingObserverCount > 0 {
            concealmentState = "screen broken"
        } else if sectorHasVegetation || maskedCount > 0 {
            concealmentState = "screening"
        } else if sceneVegetationActive {
            concealmentState = "available at vegetated stops"
        } else {
            concealmentState = "not active"
        }

        let traversalState: String
        if snapshot.sprinting && snapshot.moveSpeed > 0.35 {
            traversalState = "fast rustle"
        } else if snapshot.moveSpeed > 0.35 {
            traversalState = "soft rustle"
        } else {
            traversalState = "settled"
        }
        let exposureState = snapshot.seeingObserverCount > 0
            ? "\(snapshot.seeingObserverCount) seeing"
            : "\(maskedCount) masked"

        return String(
            format: "Vegetation Concealment: %@ / traversal %@ / %@ / sector %@",
            concealmentState,
            traversalState,
            exposureState,
            sectorName
        )
    }

    private func patrolPairFoundationLine() -> String {
        guard let mapConfiguration else {
            return "Patrol Pairs: waiting for authored observer groups"
        }

        let groupedObservers = Dictionary(grouping: mapConfiguration.threatObservers.enumerated().filter { _, observer in
            guard let groupID = observer.groupID?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                return false
            }
            return !groupID.isEmpty
        }) { _, observer in
            observer.groupID ?? ""
        }
        let patrolPairs = groupedObservers
            .filter { _, observers in observers.count >= 2 }
            .sorted { lhs, rhs in lhs.key < rhs.key }

        guard !patrolPairs.isEmpty else {
            return "Patrol Pairs: no paired observer groups authored"
        }

        let focusPair = patrolPairs.first { _, observers in
            observers.contains { index, _ in
                index < latestObserverDebugStates.count
                    && !latestObserverDebugStates[index].neutralized
                    && (latestObserverDebugStates[index].seeingPlayer || latestObserverDebugStates[index].alerted)
            }
        } ?? patrolPairs[0]

        let groupID = focusPair.key
        let observers = focusPair.value.sorted { lhs, rhs in lhs.offset < rhs.offset }
        let activeCount = observers.filter { index, _ in
            index >= latestObserverDebugStates.count || !latestObserverDebugStates[index].neutralized
        }.count
        let routeID = observers.compactMap { $0.element.patrolRouteID }.first ?? "static-route"
        let roles = observers
            .compactMap { $0.element.patrolRole }
            .joined(separator: "+")
        let authoredSpacing = observers.compactMap { $0.element.formationSpacingMeters }
        let spacingMeters: Float
        if !authoredSpacing.isEmpty {
            spacingMeters = authoredSpacing.reduce(0, +) / Float(authoredSpacing.count)
        } else if observers.count >= 2 {
            let first = observers[0].element.point
            let second = observers[1].element.point
            let deltaX = second.x - first.x
            let deltaZ = second.z - first.z
            spacingMeters = sqrtf((deltaX * deltaX) + (deltaZ * deltaZ))
        } else {
            spacingMeters = 0
        }
        let displayGroup = groupID
            .replacingOccurrences(of: "_", with: " ")
            .capitalized

        return String(
            format: "Patrol Pairs: %d authored / %@ %d/%d active / route %@ / roles %@ / %.0fm spacing",
            patrolPairs.count,
            displayGroup,
            activeCount,
            observers.count,
            routeID,
            roles.isEmpty ? "unassigned" : roles,
            spacingMeters
        )
    }

    private func losDebugOverlayLine() -> String {
        guard !latestObserverDebugStates.isEmpty else {
            return "LOS Debug: waiting for observer samples"
        }

        let activeStates = latestObserverDebugStates.filter { !$0.neutralized }
        let trackingCount = activeStates.filter(\.seeingPlayer).count
        let relayCount = activeStates.filter(\.supportingGroup).count
        let blockedCount = activeStates.filter { $0.inRange && $0.inViewCone && !$0.hasLineOfSight }.count
        let offAxisCount = activeStates.filter { $0.inRange && !$0.inViewCone }.count
        let openSampleCount = activeStates.filter { $0.hasLineOfSight }.count

        return String(
            format: "LOS Debug: %d tracking / %d relay / %d blocked samples / %d off-axis / %d open",
            trackingCount,
            relayCount,
            blockedCount,
            offAxisCount,
            openSampleCount
        )
    }

    private func scanStateOverlayLine() -> String {
        guard let focusState = prominentObserverDebugStates(limit: 1).first else {
            return "Scan State: waiting for focus observer"
        }

        let viewDot = focusState.viewDot >= -0.999 ? focusState.viewDot : -1.0
        return String(
            format: "Scan State: %@ / %@ / arc %.0fdeg / fov %.0fdeg / yaw %.0f pitch %.0f / dot %.2f thresh %.2f",
            focusState.label,
            focusState.scanStateLabel,
            focusState.scanArcDegrees,
            focusState.fieldOfViewDegrees,
            focusState.yawDegrees,
            focusState.pitchDegrees,
            viewDot,
            focusState.coneThreshold
        )
    }

    private func scanHaltResumeLine() -> String {
        guard !latestObserverDebugStates.isEmpty else {
            return "Scan Halt Resume: waiting for patrol observers"
        }

        let patrolStates = latestObserverDebugStates.filter { $0.scanArcDegrees > 0 && !$0.neutralized }
        guard !patrolStates.isEmpty else {
            return "Scan Halt Resume: no patrol scan arcs active"
        }

        let haltedCount = patrolStates.filter(\.scanHalted).count
        let relayHandoffCount = patrolStates.filter { $0.scanHalted && $0.supportingGroup }.count
        let resumeCount = patrolStates.count - haltedCount
        let focusState = patrolStates
            .sorted {
                if $0.scanHalted != $1.scanHalted {
                    return $0.scanHalted && !$1.scanHalted
                }
                return $0.distanceMeters < $1.distanceMeters
            }
            .first
        let focusSummary: String
        if let focusState {
            let phasePercent = focusState.scanCycleSeconds > 0
                ? Int(((focusState.scanPhaseSeconds / focusState.scanCycleSeconds) * 100).rounded())
                : 0
            focusSummary = String(
                format: "%@ %@ phase %d%%",
                focusState.label,
                focusState.scanHalted ? "halted" : "resuming",
                phasePercent
            )
        } else {
            focusSummary = "no focus"
        }

        return String(
            format: "Scan Halt Resume: %d halted / %d resume / %d relay handoff / %@",
            haltedCount,
            resumeCount,
            relayHandoffCount,
            focusSummary
        )
    }

    private func difficultyTelemetryLine() -> String {
        String(
            format: "Difficulty: %@ / fail %.2f / obs x%.2f / decay x%.2f / cycle x%.2f",
            difficultyPreset.displayName,
            effectiveDetectionFailThreshold,
            difficultyPreset.observerSuspicionScale,
            difficultyPreset.suspicionDecayScale,
            difficultyPreset.weaponCycleScale
        )
    }

    private func lineOfSightDebugLines(limit: Int = 3) -> [String] {
        let candidates = prominentObserverDebugStates(limit: limit)
        guard !candidates.isEmpty else {
            return ["LOS: no observer telemetry"]
        }

        return candidates.enumerated().map { offset, state in
            if state.seeingPlayer {
                return String(
                    format: "LOS %d: %@ / %.0fm / %@ / arc %.0fdeg / +%.2f sus/s",
                    offset + 1,
                    state.label,
                    state.distanceMeters,
                    state.scanStateLabel,
                    state.fieldOfViewDegrees,
                    state.suspicionPerSecond
                )
            }

            if state.alerted {
                return String(
                    format: "LOS %d: %@ / %.0fm / %@ / arc %.0fdeg / %.1fs memory",
                    offset + 1,
                    state.label,
                    state.distanceMeters,
                    state.scanStateLabel,
                    state.fieldOfViewDegrees,
                    state.alertSecondsRemaining
                )
            }

            let viewDot = state.viewDot >= -0.999 ? state.viewDot : -1.0
            return String(
                format: "LOS %d: %@ / %.0fm of %.0fm / %@ / arc %.0fdeg / dot %.2f",
                offset + 1,
                state.label,
                state.distanceMeters,
                state.rangeMeters,
                state.scanStateLabel,
                state.fieldOfViewDegrees,
                viewDot
            )
        }
    }

    private func coreProfilingLine() -> String {
        let simulationStepCount: Int32 = latestProfilingSnapshot?.simulationStepCount ?? 0
        let movementStepCount: Int32 = latestProfilingSnapshot?.movementStepCount ?? 0
        let lineOfSightTestCount: Int32 = latestProfilingSnapshot?.lineOfSightTestCount ?? 0
        let lineOfSightSampleCount: Int32 = latestProfilingSnapshot?.lineOfSightSampleCount ?? 0

        return String(
            format: "Profiler: %d sim / %d move / %d LOS / %d samples",
            simulationStepCount,
            movementStepCount,
            lineOfSightTestCount,
            lineOfSightSampleCount
        )
    }

    private func formalProfilingBaselineLine() -> String {
        let simulationStepCount: Int32 = latestProfilingSnapshot?.simulationStepCount ?? 0
        let movementStepCount: Int32 = latestProfilingSnapshot?.movementStepCount ?? 0
        let lineOfSightTestCount: Int32 = latestProfilingSnapshot?.lineOfSightTestCount ?? 0
        let lineOfSightSampleCount: Int32 = latestProfilingSnapshot?.lineOfSightSampleCount ?? 0
        let sectorCount: Int32 = latestProfilingSnapshot?.sectorCount ?? 0
        let collisionVolumeCount: Int32 = latestProfilingSnapshot?.collisionVolumeCount ?? 0
        let groundSurfaceCount: Int32 = latestProfilingSnapshot?.groundSurfaceCount ?? 0
        let frameBaseline = frameTimingLine.replacingOccurrences(of: "Frame: ", with: "frame ")

        return String(
            format: "Profile Baseline: %@ / core %d sim %d move / LOS %d tests %d samples / world %d sectors %d blockers %d surfaces",
            frameBaseline,
            simulationStepCount,
            movementStepCount,
            lineOfSightTestCount,
            lineOfSightSampleCount,
            sectorCount,
            collisionVolumeCount,
            groundSurfaceCount
        )
    }

    private func csmRendererProfileLine() -> String {
        guard let mapConfiguration else {
            return "CSM Profile: waiting for scene shadow profile"
        }

        let frameBaseline = frameTimingLine.replacingOccurrences(of: "Frame: ", with: "frame ")
        let drawableCount = latestProfilingSnapshot?.sectorCount ?? 0
        let blockerCount = latestProfilingSnapshot?.collisionVolumeCount ?? 0
        return String(
            format: "CSM Profile: %@ / %@ / %@ / %d sectors %d blockers",
            mapConfiguration.shadowProfileStatus,
            mapConfiguration.shadowProfileSummary,
            frameBaseline,
            drawableCount,
            blockerCount
        )
    }

    private func distantLODAndReflectionLine() -> String {
        guard let mapConfiguration else {
            return "LOD Reflection: waiting for scene LOD and water profile"
        }

        let frameBaseline = frameTimingLine.replacingOccurrences(of: "Frame: ", with: "frame ")
        return "LOD Reflection: \(mapConfiguration.distantLODStatus) / \(mapConfiguration.distantLODSummary) / \(mapConfiguration.waterReflectionStatus) / \(mapConfiguration.waterReflectionSummary) / \(frameBaseline)"
    }

    private func packagingAutomationLine() -> String {
        guard let mapConfiguration else {
            return "Packaging: waiting for release packaging policy"
        }

        return "Packaging: \(configuration.releaseDisplayName) / \(mapConfiguration.packagingAutomationStatus) / \(mapConfiguration.packagingAutomationSummary)"
    }

    private func testerDistributionLine() -> String {
        guard let mapConfiguration else {
            return "Tester Delivery: waiting for tester distribution policy"
        }

        return "Tester Delivery: \(mapConfiguration.testerDistributionStatus) / \(mapConfiguration.testerDistributionSummary)"
    }

    private func lightingArchitectureLine() -> String {
        guard let mapConfiguration else {
            return "Lighting Plan: waiting for time-of-day and renderer architecture decision"
        }

        let frameBaseline = frameTimingLine.replacingOccurrences(of: "Frame: ", with: "frame ")
        return "Lighting Plan: \(mapConfiguration.lightingArchitectureStatus) / \(mapConfiguration.lightingArchitectureSummary) / \(frameBaseline)"
    }

    private func coreWorldLine() -> String {
        let sectorCount: Int32 = latestProfilingSnapshot?.sectorCount ?? 0
        let collisionVolumeCount: Int32 = latestProfilingSnapshot?.collisionVolumeCount ?? 0
        let groundSurfaceCount: Int32 = latestProfilingSnapshot?.groundSurfaceCount ?? 0

        return String(
            format: "Core World: %d sectors / %d blockers / %d surfaces",
            sectorCount,
            collisionVolumeCount,
            groundSurfaceCount
        )
    }

    private func rebuildOverlay() {
        let snapshot = latestSnapshot
        let pressed = pressedCommands
            .map(\.label)
            .sorted()
            .joined(separator: ", ")
        let storedSessionLine = storedReviewSessionLine ?? "Last Session: no persisted review state yet"
        let storedResumeLine = storedReviewResumeLine ?? "Review Resume: no persisted capture context yet"
        let storedGuardrailLine = storedReviewGuardrailLine ?? "Review Guardrail: no persisted review card to validate yet"
        let storedPreviewLine = storedReviewRestorePreviewLine ?? "Restore Preview: no persisted checkpoint target yet"
        let storedReadinessLine = storedReviewRestoreReadinessLine ?? "Restore Readiness: no persisted review card to inspect yet"
        let storedArmingLine = storedReviewManualRestoreArmingLine ?? "Manual Restore Arm: no persisted review card to inspect yet"
        let storedPromptLine = storedReviewManualRestorePromptLine ?? "Manual Restore Prompt: hidden until a review card is persisted"
        let storedChoiceLine = storedReviewManualRestoreChoiceLine ?? "Restore Choice: hidden / no persisted review card"
        let storedSelectionLine = storedReviewManualRestoreSelectionLine ?? "Restore Selection: unavailable / no persisted review card"
        let storedFreshStartLine = storedReviewRestoreFreshStartGuardLine ?? "Restore Fresh Start: unavailable / no persisted review card"
        let storedBoundaryResetLine = restoreBoundaryResetLine
        let storedReviewExpiryLine = restoreReviewExpiryLine
        let storedReviewScopeLine = restoreReviewScopeLine
        let storedReviewExecutionIntentLine = restoreReviewExecutionIntentLine
        let storedExecutionGateLine = storedReviewRestoreExecutionGateLine ?? "Restore Execution Gate: closed / no persisted review card"
        let storedExecutionDesignLine = storedReviewManualRestoreExecutionDesignLine ?? "Restore Execution Design: unavailable / no persisted review card"
        let storedSafetyCheckLine = storedReviewManualRestoreSafetyCheckLine ?? "Restore Safety Checks: unavailable / no persisted review card"
        let storedAuditLine = storedReviewRestoreAuditLine ?? "Restore Audit: no persisted review card"
        let storedFreshnessLine = storedReviewRestoreFreshnessLine ?? "Restore Freshness: no persisted review card"
        let storedRetentionLine = storedReviewRestoreRetentionLine ?? "Restore Retention: no persisted review card"
        let storedCleanupPreviewLine = storedReviewRestoreCleanupPreviewLine ?? "Restore Cleanup Preview: no persisted review card"
        let headerLines: [String] = [
            "Mode: \(configuration.bootMode)",
            "Demo: \(demoFlowState.label)\(isSettingsPresented ? " / settings" : "")",
            "Release: \(configuration.releaseDisplayName)",
            "Bundle: \(configuration.bundleIdentifier)",
            "Content: \(configuration.contentSourceSummary)",
            "Scene: \(sceneLabel)",
            "World: \(configuration.worldName)",
            "Assets: \(shortenedPath(configuration.assetRoot))",
            "World Data: \(shortenedPath(configuration.worldDataRoot))",
            "Manifest: \(shortenedPath(configuration.worldManifestPath))",
            "Locator: \(isMapPresented ? "Canberra map open" : "Canberra map hidden") / \(currentMapSectorName)",
            "Renderer: \(rendererName)",
            "Scene Summary: \(sceneSummary)",
            storedSessionLine,
            storedResumeLine,
            storedGuardrailLine,
            storedPreviewLine,
            storedReadinessLine,
            storedArmingLine,
            storedPromptLine,
            storedChoiceLine,
            storedSelectionLine,
            storedFreshStartLine,
            storedBoundaryResetLine,
            storedReviewExpiryLine,
            storedReviewScopeLine,
            storedReviewExecutionIntentLine,
            storedExecutionGateLine,
            storedExecutionDesignLine,
            storedSafetyCheckLine,
            storedAuditLine,
            storedFreshnessLine,
            storedRetentionLine,
            storedCleanupPreviewLine,
            restoreCleanupExecutionLine,
            "Session Audio: \(sessionAudioState) / world \(lastWorldAudioState) / movement \(lastMovementAudioState) / scope \(lastScopeAudioState)",
            String(
                format: "Scope: %@ / %.1fx / %.1f deg / x%.1f draw",
                isScopeActive ? "active" : "ready",
                scopeMagnification,
                scopeFieldOfViewDegrees,
                scopeDrawDistanceMultiplier
            ),
            briefingSummary,
            routeSummary,
            evasionSummary,
            streamingSummary,
        ]
        var metricLines = [
            "Viewport: \(Int(viewportSize.width)) x \(Int(viewportSize.height))",
            frameTimingLine,
            "Pressed: \(pressed.isEmpty ? "None" : pressed)",
            String(format: "Intent: strafe %.1f forward %.1f sprint %@", snapshot?.strafeIntent ?? 0, snapshot?.forwardIntent ?? 0, (snapshot?.sprinting ?? false) ? "on" : "off"),
            String(
                format: "Move Speed: %.2f m/s (walk %.2f / sprint %.2f / look %.3f)",
                snapshot?.moveSpeed ?? 0,
                snapshot?.walkSpeed ?? 0,
                snapshot?.sprintSpeed ?? 0,
                snapshot?.lookSensitivity ?? 0
            ),
            weaponStatusLine(),
            muzzleFeedbackLine(),
            scopePresentationText,
            scopeCalibrationLine(),
            scopeShotTimingText,
            threatStatusLine(),
            ballisticsProfileLine(),
            ballisticsPredictionLine(),
            coreProfilingLine(),
            formalProfilingBaselineLine(),
            csmRendererProfileLine(),
            distantLODAndReflectionLine(),
            packagingAutomationLine(),
            testerDistributionLine(),
            lightingArchitectureLine(),
            coreWorldLine(),
            String(format: "Optic: %@ / %.1fx", isScopeActive ? "raised" : "lowered", scopeMagnification),
            String(format: "Settings: look x%.2f / %@ / HUD %.0f%%", lookSensitivityScale, invertLookY ? "invert Y" : "standard Y", hudOpacity * 100),
            difficultyTelemetryLine(),
            String(format: "Ground: %.2f m / %@ / %d active sectors", snapshot?.groundHeight ?? 0, (snapshot?.grounded ?? false) ? "grounded" : "fallback", snapshot?.activeSectorCount ?? 0),
            String(
                format: "Route Metrics: %d / %d checkpoints / %.0fm / %d restarts",
                snapshot?.completedCheckpointCount ?? 0,
                snapshot?.totalCheckpointCount ?? 0,
                snapshot?.routeDistanceMeters ?? 0,
                snapshot?.restartCount ?? 0
            ),
            String(
                format: "Pressure: %.2f / %d alerted / %d watching / %d in range / %d fails",
                snapshot?.suspicionLevel ?? 0,
                snapshot?.alertedObserverCount ?? 0,
                snapshot?.seeingObserverCount ?? 0,
                snapshot?.activeObserverCount ?? 0,
                snapshot?.failCount ?? 0
            ),
            String(format: "Look: yaw %.1f pitch %.1f", snapshot?.yawDegrees ?? 0, snapshot?.pitchDegrees ?? 0),
            String(format: "Camera: %.2f %.2f %.2f", snapshot?.cameraX ?? 0, snapshot?.cameraY ?? 0, snapshot?.cameraZ ?? 0),
            String(format: "Mouse Delta: %.1f %.1f", lastMouseDelta.width, lastMouseDelta.height),
            String(format: "Uptime: %.2fs", snapshot?.elapsedSeconds ?? 0),
        ]
        metricLines.insert(
            contentsOf: [
                observerFeedbackLine(),
                worldMovementAudioLine(),
                vegetationConcealmentLine(),
                alternateRouteActivationLine,
                patrolPairFoundationLine(),
                losDebugOverlayLine(),
                scanStateOverlayLine(),
                scanHaltResumeLine()
            ] + lineOfSightDebugLines(limit: 3),
            at: 7
        )

        publishOverlayLines(
            headerLines + sceneDetails + briefingDetails + routeDetails + evasionDetails + streamingDetails + metricLines
        )
    }

    private func publishOverlayLines(_ newOverlayLines: [String]) {
        pendingOverlayLines = newOverlayLines

        guard !isOverlayPublishScheduled else {
            return
        }

        isOverlayPublishScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }

            self.isOverlayPublishScheduled = false
            guard let pendingOverlayLines = self.pendingOverlayLines else {
                return
            }

            self.pendingOverlayLines = nil
            if self.overlayLines != pendingOverlayLines {
                self.overlayLines = pendingOverlayLines
            }
        }
    }

    private var canRecoverGameplayInputFocus: Bool {
        menuPanel != .settings
    }

    var allowsGameplayInputFocusCapture: Bool {
        canRecoverGameplayInputFocus
    }

    var shouldKeepGameplayWindowKey: Bool {
        sceneReady && demoFlowState == .playing && menuPanel == nil
    }

    private func requestInputFocusIfNeeded() {
        guard canRecoverGameplayInputFocus else {
            return
        }

        inputFocusRequestID &+= 1
    }

    func scheduleGameplayInputFocusRecovery() {
        guard canRecoverGameplayInputFocus else {
            return
        }

        requestInputFocusIfNeeded()
        DispatchQueue.main.async { [weak self] in
            guard let self, self.canRecoverGameplayInputFocus else {
                return
            }

            self.requestInputFocusIfNeeded()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            guard let self, self.canRecoverGameplayInputFocus else {
                return
            }

            self.requestInputFocusIfNeeded()
        }
    }

    private func persistSettings() {
        let defaults = UserDefaults.standard
        defaults.set(hudOpacity, forKey: Self.hudOpacityDefaultsKey)
        defaults.set(invertLookY, forKey: Self.invertLookYDefaultsKey)
        defaults.set(lookSensitivityScale, forKey: Self.lookSensitivityScaleDefaultsKey)
        defaults.set(difficultyPreset.rawValue, forKey: Self.difficultyPresetDefaultsKey)
    }

    private var storedReviewSessionLine: String? {
        storedReviewSessionState?.shellLine
    }

    private var storedReviewResumeLine: String? {
        storedReviewSessionState?.captureLine
    }

    private var storedReviewGuardrailLine: String? {
        storedReviewSessionState?.guardrailLine
    }

    private var storedReviewRestorePreviewLine: String? {
        storedReviewSessionState?.restorePreviewLine
    }

    private var storedReviewRestoreReadinessLine: String? {
        storedReviewSessionState?.restoreReadinessLine(
            currentSceneLabel: sceneLabel,
            currentRouteSummary: routeSummary
        )
    }

    private var storedReviewManualRestoreArmingLine: String? {
        storedReviewSessionState?.manualRestoreArmingLine(
            currentSceneLabel: sceneLabel,
            currentRouteSummary: routeSummary
        )
    }

    private var storedReviewManualRestorePromptLine: String? {
        storedReviewSessionState?.manualRestorePromptLine(
            currentSceneLabel: sceneLabel,
            currentRouteSummary: routeSummary
        )
    }

    private var storedReviewManualRestoreChoiceLine: String? {
        storedReviewSessionState?.manualRestoreChoiceLine(
            currentSceneLabel: sceneLabel,
            currentRouteSummary: routeSummary
        )
    }

    private var manualRestoreChoiceTargetLabel: String? {
        storedReviewSessionState?.restoreChoiceTargetLabel(
            currentSceneLabel: sceneLabel,
            currentRouteSummary: routeSummary
        )
    }

    private var manualRestoreExecutionProgress: Int? {
        guard let storedReviewSessionState else {
            return nil
        }

        guard storedReviewSessionState.schemaVersion == 1,
              storedReviewSessionState.sceneLabel == sceneLabel,
              storedReviewSessionState.routeSummary == routeSummary else {
            return nil
        }

        guard storedReviewSessionState.totalCheckpointCount > 0,
              storedReviewSessionState.completedCheckpointCount >= 0,
              storedReviewSessionState.completedCheckpointCount < storedReviewSessionState.totalCheckpointCount,
              !storedReviewSessionState.routeComplete,
              storedReviewSessionState.nextCheckpointLabel != nil else {
            return nil
        }

        let ageSeconds = Int(max(Date().timeIntervalSince1970 - storedReviewSessionState.savedAt, 0))
        guard storedReviewSessionState.savedAt > 0,
              ageSeconds <= Self.reviewSessionStateFreshnessWindowSeconds else {
            return nil
        }

        return storedReviewSessionState.completedCheckpointCount
    }

    private var storedReviewManualRestoreSelectionLine: String? {
        storedReviewSessionState?.manualRestoreSelectionLine(
            currentSceneLabel: sceneLabel,
            currentRouteSummary: routeSummary,
            reviewedTargetLabel: reviewedManualRestoreTargetLabel
        )
    }

    private var storedReviewRestoreFreshStartGuardLine: String? {
        storedReviewSessionState?.restoreFreshStartGuardLine(
            currentSceneLabel: sceneLabel,
            currentRouteSummary: routeSummary,
            reviewedTargetLabel: reviewedManualRestoreTargetLabel,
            freshStartTargetLabel: freshStartConfirmedRestoreTargetLabel
        )
    }

    private var restoreReviewScopeLine: String {
        guard storedReviewSessionState != nil else {
            return "Restore Review Scope: runtime-only / no persisted review card"
        }

        guard let targetLabel = manualRestoreChoiceTargetLabel else {
            return "Restore Review Scope: runtime-only / no restorable target"
        }

        if reviewedManualRestoreTargetLabel == targetLabel || freshStartConfirmedRestoreTargetLabel == targetLabel {
            return "Restore Review Scope: runtime-only review of \(targetLabel) / not persisted"
        }

        return "Restore Review Scope: persisted target \(targetLabel) / review not stored"
    }

    private var restoreReviewExecutionIntentLine: String {
        guard storedReviewSessionState != nil else {
            return "Restore Review Intent: none / no persisted review card"
        }

        guard let targetLabel = manualRestoreChoiceTargetLabel else {
            return "Restore Review Intent: none / no restorable target"
        }

        if freshStartConfirmedRestoreTargetLabel == targetLabel {
            return "Restore Review Intent: fresh start confirmed for \(targetLabel) / no restore token"
        }

        if reviewedManualRestoreTargetLabel == targetLabel {
            return "Restore Review Intent: reviewed \(targetLabel) / explicit execution request may run restore"
        }

        return "Restore Review Intent: unreviewed \(targetLabel) / execution gate closed"
    }

    private var storedReviewRestoreExecutionGateLine: String? {
        storedReviewSessionState?.restoreExecutionGateLine(
            currentSceneLabel: sceneLabel,
            currentRouteSummary: routeSummary
        )
    }

    private var storedReviewManualRestoreExecutionDesignLine: String? {
        storedReviewSessionState?.manualRestoreExecutionDesignLine(
            currentSceneLabel: sceneLabel,
            currentRouteSummary: routeSummary
        )
    }

    private var storedReviewManualRestoreSafetyCheckLine: String? {
        storedReviewSessionState?.manualRestoreSafetyCheckLine(
            currentSceneLabel: sceneLabel,
            currentRouteSummary: routeSummary,
            maxAgeSeconds: Self.reviewSessionStateFreshnessWindowSeconds
        )
    }

    private var storedReviewRestoreAuditLine: String? {
        storedReviewSessionState?.restoreAuditLine(
            currentSceneLabel: sceneLabel,
            currentRouteSummary: routeSummary
        )
    }

    private var storedReviewRestoreFreshnessLine: String? {
        storedReviewSessionState?.restoreFreshnessLine(maxAgeSeconds: Self.reviewSessionStateFreshnessWindowSeconds)
    }

    private var storedReviewRestoreRetentionLine: String? {
        storedReviewSessionState?.restoreRetentionLine(maxAgeSeconds: Self.reviewSessionStateFreshnessWindowSeconds)
    }

    private var storedReviewRestoreCleanupPreviewLine: String? {
        storedReviewSessionState?.restoreCleanupPreviewLine(maxAgeSeconds: Self.reviewSessionStateFreshnessWindowSeconds)
    }

    private static func applyRestoreCleanup(to state: inout StoredReviewSessionState?) -> String {
        guard let storedState = state else {
            return "Restore Cleanup: no persisted review card"
        }

        let line = storedState.restoreCleanupExecutionLine(maxAgeSeconds: reviewSessionStateFreshnessWindowSeconds)
        if storedState.shouldClearForRestoreCleanup(maxAgeSeconds: reviewSessionStateFreshnessWindowSeconds) {
            UserDefaults.standard.removeObject(forKey: reviewSessionStateDefaultsKey)
            state = nil
        }

        return line
    }

    private func clearManualRestoreReviewState(reason: String, fallback: String) {
        guard reviewedManualRestoreTargetLabel != nil || freshStartConfirmedRestoreTargetLabel != nil else {
            restoreBoundaryResetLine = fallback
            return
        }

        let targetLabel = freshStartConfirmedRestoreTargetLabel ?? reviewedManualRestoreTargetLabel ?? "restore target"
        reviewedManualRestoreTargetLabel = nil
        freshStartConfirmedRestoreTargetLabel = nil
        restoreBoundaryResetLine = "Restore Boundary Reset: cleared \(targetLabel) at \(reason) / restore remains disabled"
        restoreReviewExpiryLine = "Restore Review Expiry: cleared \(targetLabel) at \(reason)"
    }

    private func persistReviewSessionState(from snapshot: GameFrameSnapshot) {
        guard sceneReady else {
            return
        }

        let totalCheckpointCount = max(Int(snapshot.totalCheckpointCount), 0)
        let completedCheckpointCount = max(min(Int(snapshot.completedCheckpointCount), totalCheckpointCount), 0)
        let nextCheckpointLabel = nextCheckpointLabel(
            completed: completedCheckpointCount,
            total: totalCheckpointCount
        )
        let reviewPackageLine = routeDetails.first(where: { $0.hasPrefix("Review Pack:") })
            ?? sceneDetails.first(where: { $0.hasPrefix("Review Pack:") })
            ?? "review pack unavailable"
        let state = StoredReviewSessionState(
            schemaVersion: 1,
            sceneLabel: sceneLabel,
            routeSummary: routeSummary,
            completedCheckpointCount: completedCheckpointCount,
            totalCheckpointCount: totalCheckpointCount,
            nextCheckpointLabel: nextCheckpointLabel,
            currentSectorName: currentMapSectorName,
            difficultyPreset: difficultyPreset.displayName,
            flowState: demoFlowState.label,
            mapPresented: isMapPresented,
            scopeActive: isScopeActive,
            routeComplete: snapshot.routeComplete,
            routeFailed: snapshot.routeFailed,
            reviewPackageLine: reviewPackageLine,
            savedAt: Date().timeIntervalSince1970
        )

        guard state != storedReviewSessionState else {
            return
        }

        refreshManualRestoreReviewExpiry(for: state)
        storedReviewSessionState = state
        restoreCleanupExecutionLine = state.restoreCleanupExecutionLine(
            maxAgeSeconds: Self.reviewSessionStateFreshnessWindowSeconds
        )
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: Self.reviewSessionStateDefaultsKey)
        }
    }

    private func refreshManualRestoreReviewExpiry(for state: StoredReviewSessionState) {
        let currentTargetLabel = state.restoreChoiceTargetLabel(
            currentSceneLabel: sceneLabel,
            currentRouteSummary: routeSummary
        )
        guard reviewedManualRestoreTargetLabel != nil || freshStartConfirmedRestoreTargetLabel != nil else {
            if let currentTargetLabel {
                restoreReviewExpiryLine = "Restore Review Expiry: ready for \(currentTargetLabel) review"
            } else {
                restoreReviewExpiryLine = "Restore Review Expiry: inactive / no restorable target"
            }
            return
        }

        let trackedTargetLabel = freshStartConfirmedRestoreTargetLabel ?? reviewedManualRestoreTargetLabel ?? "restore target"
        guard let currentTargetLabel else {
            reviewedManualRestoreTargetLabel = nil
            freshStartConfirmedRestoreTargetLabel = nil
            restoreReviewExpiryLine = "Restore Review Expiry: cleared \(trackedTargetLabel) / target no longer restorable"
            return
        }

        guard trackedTargetLabel == currentTargetLabel else {
            reviewedManualRestoreTargetLabel = nil
            freshStartConfirmedRestoreTargetLabel = nil
            restoreReviewExpiryLine = "Restore Review Expiry: cleared \(trackedTargetLabel) / current target is \(currentTargetLabel)"
            return
        }

        restoreReviewExpiryLine = "Restore Review Expiry: tracking \(currentTargetLabel) / target still current"
    }

    private func nextCheckpointLabel(completed: Int, total: Int) -> String? {
        guard let mapConfiguration else {
            return nil
        }

        let index = max(min(completed, min(total, mapConfiguration.checkpoints.count)), 0)
        guard index < mapConfiguration.checkpoints.count else {
            return nil
        }

        return mapConfiguration.checkpoints[index].label
    }

    private func shortenedPath(_ path: String) -> String {
        let components = URL(fileURLWithPath: path).pathComponents.filter { $0 != "/" }
        guard components.count > 3 else {
            return path
        }

        return components.suffix(3).joined(separator: "/")
    }

    private func preferredSectorName(
        for sectors: [SceneMapSector],
        playerX: Float,
        playerZ: Float
    ) -> String {
        let containingSectors = sectors.filter { sector in
            sector.contains(x: playerX, z: playerZ)
        }

        guard let sector = containingSectors.sorted(by: { lhs, rhs in
            let leftPriority = residencyPriority(lhs.residency)
            let rightPriority = residencyPriority(rhs.residency)
            if leftPriority != rightPriority {
                return leftPriority < rightPriority
            }
            if lhs.area != rhs.area {
                return lhs.area < rhs.area
            }
            return lhs.displayName < rhs.displayName
        }).first else {
            return "Outside basin bounds"
        }

        return sector.displayName
    }

    private func residencyPriority(_ residency: SectorResidency) -> Int {
        switch residency {
        case .local:
            return 0
        case .farField:
            return 1
        case .always:
            return 2
        }
    }

    private static func loadStoredSettings() -> StoredSessionSettings {
        let defaults = UserDefaults.standard
        let hudOpacity = defaults.object(forKey: hudOpacityDefaultsKey) as? Double ?? 0.88
        let invertLookY = defaults.object(forKey: invertLookYDefaultsKey) as? Bool ?? false
        let lookSensitivityScale = defaults.object(forKey: lookSensitivityScaleDefaultsKey) as? Double ?? 1.0
        let difficultyPreset = defaults.string(forKey: difficultyPresetDefaultsKey)
            .flatMap(RehearsalDifficultyPreset.init(rawValue:))
            ?? .baseline

        return StoredSessionSettings(
            hudOpacity: max(min(hudOpacity, 1.0), 0.35),
            invertLookY: invertLookY,
            lookSensitivityScale: max(min(lookSensitivityScale, 1.8), 0.6),
            difficultyPreset: difficultyPreset
        )
    }

    private static func loadStoredReviewSessionState() -> StoredReviewSessionState? {
        guard let data = UserDefaults.standard.data(forKey: reviewSessionStateDefaultsKey),
              let state = try? JSONDecoder().decode(StoredReviewSessionState.self, from: data),
              state.schemaVersion == 1 else {
            return nil
        }

        return state
    }

    private static let hudOpacityDefaultsKey = "milsimPony.hudOpacity"
    private static let invertLookYDefaultsKey = "milsimPony.invertLookY"
    private static let lookSensitivityScaleDefaultsKey = "milsimPony.lookSensitivityScale"
    private static let difficultyPresetDefaultsKey = "milsimPony.difficultyPreset"
    private static let reviewSessionStateDefaultsKey = "milsimPony.reviewSessionState.v1"
    private static let reviewSessionStateFreshnessWindowSeconds = 86_400
}
