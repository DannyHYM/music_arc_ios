import Foundation
import Combine

final class DemoPoseProvider: PoseProvider {
    var armHeightPublisher: AnyPublisher<Double, Never> {
        armHeightSubject.eraseToAnyPublisher()
    }

    private let armHeightSubject = PassthroughSubject<Double, Never>()
    private var timer: AnyCancellable?
    private var elapsed: TimeInterval = 0

    func start() {
        elapsed = 0
        timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.elapsed += 1.0 / 30.0
                let height = self.syntheticHeight(at: self.elapsed)
                self.armHeightSubject.send(height)
            }
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    /// Produces a smoothly varying height between 0.1 and 0.9
    /// that cycles through low/mid/high to match the default target heights.
    private func syntheticHeight(at t: TimeInterval) -> Double {
        let targets = [0.2, 0.5, 0.8, 0.5]
        let cycleDuration = 4.0
        let phase = t.truncatingRemainder(dividingBy: cycleDuration)
        let segmentDuration = cycleDuration / Double(targets.count)
        let segmentIndex = Int(phase / segmentDuration)
        let segmentProgress = (phase - Double(segmentIndex) * segmentDuration) / segmentDuration

        let from = targets[segmentIndex]
        let to = targets[(segmentIndex + 1) % targets.count]

        let smoothT = 0.5 - 0.5 * cos(segmentProgress * .pi)
        let value = from + (to - from) * smoothT

        let noise = Double.random(in: -0.02...0.02)
        return min(1.0, max(0.0, value + noise))
    }
}
