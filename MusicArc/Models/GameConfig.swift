import Foundation

enum InputMode: String, Hashable, CaseIterable {
    case camera = "Camera"
    case touch = "Touch"
    case demo = "Auto Demo"
}

struct GameConfig: Hashable {
    var durationSeconds: Int = 60
    var noteCount: Int = 12
    var targetHeights: [Double] = [0.2, 0.5, 0.8]
    var hitTolerance: Double = 0.15
    var inputMode: InputMode = .touch

    var isDemoMode: Bool { inputMode == .demo }
    var isTouchMode: Bool { inputMode == .touch }
    var isCameraMode: Bool { inputMode == .camera }

    static var cameraAvailable: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }
}
