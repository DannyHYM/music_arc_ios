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

    /// Simulates a rep cycle: raise high for ~4s, then drop low for ~3s.
    /// Matches the default GameConfig active/rest durations.
    private func syntheticHeight(at t: TimeInterval) -> Double {
        let activeDuration = 4.0
        let restDuration = 3.0
        let cycleDuration = activeDuration + restDuration
        let phase = t.truncatingRemainder(dividingBy: cycleDuration)

        let value: Double
        if phase < 0.5 {
            // Ramp up from rest to active
            let rampProgress = phase / 0.5
            value = 0.1 + 0.8 * smoothStep(rampProgress)
        } else if phase < activeDuration - 0.3 {
            // Hold at max with slight variation
            value = 0.9 + 0.05 * sin(phase * 3)
        } else if phase < activeDuration {
            // Transition down
            let transitionProgress = (phase - (activeDuration - 0.3)) / 0.3
            value = 0.9 * (1 - smoothStep(transitionProgress)) + 0.1 * smoothStep(transitionProgress)
        } else if phase < activeDuration + 0.3 {
            // Settling into rest
            let settleProgress = (phase - activeDuration) / 0.3
            value = 0.1 * (1 + 0.5 * (1 - smoothStep(settleProgress)))
        } else {
            // Resting low
            value = 0.1 + 0.03 * sin(phase * 2)
        }

        let noise = Double.random(in: -0.015...0.015)
        return min(1.0, max(0.0, value + noise))
    }

    private func smoothStep(_ t: Double) -> Double {
        let clamped = min(1, max(0, t))
        return clamped * clamped * (3 - 2 * clamped)
    }
}
