import Foundation
import AVFoundation
import Combine
import CoreGraphics

struct ArmPose: Equatable {
    let shoulder: CGPoint?
    let elbow: CGPoint?
    let wrist: CGPoint?
    let normalizedHeight: Double
    let isTracking: Bool

    static let untracked = ArmPose(
        shoulder: nil, elbow: nil, wrist: nil,
        normalizedHeight: 0.5, isTracking: false
    )
}

protocol PoseProvider: AnyObject {
    var armHeightPublisher: AnyPublisher<Double, Never> { get }
    var armPosePublisher: AnyPublisher<ArmPose, Never>? { get }
    var captureSession: AVCaptureSession? { get }
    func start()
    func stop()
    func pause()
    func resume()
}

extension PoseProvider {
    var armPosePublisher: AnyPublisher<ArmPose, Never>? { nil }
    var captureSession: AVCaptureSession? { nil }

    func pause() { stop() }
    func resume() { start() }
}
