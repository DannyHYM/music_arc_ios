import Foundation
import Combine
import CoreGraphics

struct ArmPose: Equatable {
    let shoulder: CGPoint?
    let elbow: CGPoint?
    let wrist: CGPoint?
    let normalizedHeight: Double
    let isTracking: Bool
}

protocol PoseProvider: AnyObject {
    var armHeightPublisher: AnyPublisher<Double, Never> { get }
    var armPosePublisher: AnyPublisher<ArmPose, Never>? { get }
    func start()
    func stop()
}

extension PoseProvider {
    var armPosePublisher: AnyPublisher<ArmPose, Never>? { nil }
}
