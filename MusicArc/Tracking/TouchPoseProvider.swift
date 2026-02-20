import Foundation
import Combine

final class TouchPoseProvider: PoseProvider {
    var armHeightPublisher: AnyPublisher<Double, Never> {
        armHeightSubject.eraseToAnyPublisher()
    }

    private let armHeightSubject = CurrentValueSubject<Double, Never>(0.5)
    private var timer: AnyCancellable?

    func start() {
        timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.armHeightSubject.send(self.armHeightSubject.value)
            }
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    func updateHeight(_ normalized: Double) {
        armHeightSubject.send(min(1.0, max(0.0, normalized)))
    }
}
