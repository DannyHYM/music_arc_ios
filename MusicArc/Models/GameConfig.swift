import Foundation

enum InputMode: String, Hashable, CaseIterable {
    case camera = "Camera"
    case touch = "Touch"
    case demo = "Auto Demo"
}

enum TrackingArm: String, Hashable, CaseIterable {
    case left = "Left"
    case right = "Right"
}

struct GameConfig: Hashable {
    var repCount: Int = 8
    var activeDuration: TimeInterval = 4.0
    var restDuration: TimeInterval = 3.0
    var sunlightThreshold: Double = 0.7
    var restThreshold: Double = 0.3
    var inputMode: InputMode = .touch
    var trackingArm: TrackingArm = .right

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
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }
}
