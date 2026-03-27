import Foundation

struct RepScheduler {
    static let countdownDuration: TimeInterval = 3.0

    static func generate(config: GameConfig) -> [Rep] {
        (0..<config.repCount).map { i in
            let repStart = countdownDuration + Double(i) * (config.activeDuration + config.restDuration)
            return Rep(
                index: i,
                activeStartTime: repStart,
                activeDuration: config.activeDuration,
                restStartTime: repStart + config.activeDuration,
                restDuration: config.restDuration
            )
        }
    }
}
