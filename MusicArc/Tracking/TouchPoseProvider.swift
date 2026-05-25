import Foundation
import Combine

final class TouchPoseProvider: PoseProvider {
    var armHeightPublisher: AnyPublisher<Double, Never> {
        armHeightSubject.eraseToAnyPublisher()
    }

    private let armHeightSubject = CurrentValueSubject<Double, Never>(0.5)

    func start() {
        // No timer needed — updateHeight publishes on demand and
        // CurrentValueSubject hands the latest value to new subscribers.
    }

    func stop() {
        // No-op.
    }

    func updateHeight(_ normalized: Double) {
        armHeightSubject.send(min(1.0, max(0.0, normalized)))
    }
}
