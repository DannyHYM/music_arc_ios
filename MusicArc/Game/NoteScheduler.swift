import Foundation

struct NoteScheduler {
    /// Generates a sequence of notes spread across the session duration.
    /// Notes avoid the first 3 seconds (countdown) and last 2 seconds (wind-down).
    static func generate(config: GameConfig) -> [GameNote] {
        let startBuffer: TimeInterval = 3.0
        let endBuffer: TimeInterval = 2.0
        let totalDuration = TimeInterval(config.durationSeconds)

        guard totalDuration > startBuffer + endBuffer else { return [] }

        let playWindow = totalDuration - startBuffer - endBuffer
        let interval = playWindow / Double(config.noteCount)

        return (0..<config.noteCount).map { i in
            let time = startBuffer + Double(i) * interval + Double.random(in: 0...(interval * 0.3))
            let height = config.targetHeights.randomElement() ?? 0.5
            return GameNote(targetHeight: height, scheduledTime: time)
        }
        .sorted { $0.scheduledTime < $1.scheduledTime }
    }
}
