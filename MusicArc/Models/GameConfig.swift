import Foundation

enum InputMode: String, Codable, Hashable, CaseIterable {
    case camera = "Camera"
    case touch = "Touch"
    case demo = "Auto Demo"
}

enum TrackingArm: String, Codable, Hashable, CaseIterable {
    case left = "Left"
    case right = "Right"
}

/// Clinical scoring knobs. Defaults preserve historical behavior so existing
/// prescriptions don't change meaning on upgrade.
struct ScoringConfig: Codable, Hashable {
    /// Rest-compliance threshold (0-1) above which a rep awards a health restore at phase end.
    var restComplianceThreshold: Double = 0.7
    /// Health restored at the end of a compliant rest phase (scaled by compliance).
    var healthRestoreMax: Double = 0.05
    /// Health penalty per second of active arm-up time during the rest phase.
    var healthPenaltyPerSecond: Double = 0.02
    /// Coefficient applied to waterLevel for the next-rep growth multiplier.
    var restBonusScale: Double = 0.3
    /// Number of growth spurts per rep (`maxGrowthPerRep / spurtsPerRep` = spurt threshold).
    var spurtsPerRep: Double = 4.0

    static let `default` = ScoringConfig()
}

struct GameConfig: Codable, Hashable {
    var repCount: Int = 8
    var activeDuration: TimeInterval = 4.0
    var restDuration: TimeInterval = 3.0
    var sunlightThreshold: Double = 0.7
    var restThreshold: Double = 0.3
    var inputMode: InputMode = .touch
    var trackingArm: TrackingArm = .right

    /// Computed for now so it stays out of the encoded form (existing prescriptions
    /// in UserDefaults don't have this field). Promote to a stored property once
    /// the clinician UI exposes scoring knobs.
    var scoring: ScoringConfig { .default }

    var isDemoMode: Bool { inputMode == .demo }
    var isTouchMode: Bool { inputMode == .touch }
    var isCameraMode: Bool { inputMode == .camera }

    var totalSessionDuration: TimeInterval {
        let countdown: TimeInterval = 3.0
        let buffer: TimeInterval = 2.0
        return countdown + Double(repCount) * (activeDuration + restDuration) + buffer
    }

    var totalSessionSeconds: Int { Int(ceil(totalSessionDuration)) }

    static var cameraAvailable: Bool {
        #if DEBUG
        // Screenshot gallery runs in the simulator but must show the camera-mode UI as a
        // device would (no "not available" warning, no fallback to touch).
        if ScreenshotGallery.isActive { return true }
        #endif
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }
}
