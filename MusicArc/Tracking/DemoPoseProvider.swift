import Foundation
import Combine

final class DemoPoseProvider: PoseProvider {
    var armHeightPublisher: AnyPublisher<Double, Never> {
        armHeightSubject.eraseToAnyPublisher()
    }

    private let armHeightSubject = PassthroughSubject<Double, Never>()
    private var timer: AnyCancellable?
    private var elapsed: TimeInterval = 0

    private let activeDuration: TimeInterval
    private let restDuration: TimeInterval

    init(activeDuration: TimeInterval, restDuration: TimeInterval) {
        self.activeDuration = activeDuration
        self.restDuration = restDuration
    }

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

    /// Sine-style sweep that follows the configured active/rest cadence so the demo
    /// arm reaches its peak during the active phase and bottoms out during rest.
    private func syntheticHeight(at t: TimeInterval) -> Double {
        let cycleDuration = activeDuration + restDuration
        guard cycleDuration > 0 else { return 0.5 }

        let phase = t.truncatingRemainder(dividingBy: cycleDuration)

        // Ramp time scales with the phase length so customized cadences still look smooth.
        let rampUp: TimeInterval = min(0.5, activeDuration * 0.2)
        let rampDown: TimeInterval = min(0.3, activeDuration * 0.1)
        let settle: TimeInterval = min(0.3, restDuration * 0.15)

        let value: Double
        if phase < rampUp {
            let rampProgress = phase / rampUp
            value = 0.1 + 0.8 * smoothStep(rampProgress)
        } else if phase < activeDuration - rampDown {
            value = 0.9 + 0.05 * sin(phase * 3)
        } else if phase < activeDuration {
            let transitionProgress = (phase - (activeDuration - rampDown)) / rampDown
            value = 0.9 * (1 - smoothStep(transitionProgress)) + 0.1 * smoothStep(transitionProgress)
        } else if phase < activeDuration + settle {
            let settleProgress = (phase - activeDuration) / settle
            value = 0.1 * (1 + 0.5 * (1 - smoothStep(settleProgress)))
        } else {
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
