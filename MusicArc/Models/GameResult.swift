import Foundation

struct GameResult: Hashable {
    let date: Date
    let durationSeconds: Int
    let totalNotes: Int
    let hits: Int
    let misses: Int
    let maxStreak: Int
    let inputMode: InputMode

    var hitRate: Double {
        guard totalNotes > 0 else { return 0 }
        return Double(hits) / Double(totalNotes)
    }

    var isDemoMode: Bool { inputMode == .demo }
}
