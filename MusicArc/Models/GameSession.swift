import Foundation
import SwiftData

@Model
final class GameSession {
    var date: Date
    var durationSeconds: Int
    var totalNotes: Int
    var hits: Int
    var misses: Int
    var maxStreak: Int
    var hitRate: Double
    var isDemoMode: Bool

    init(
        date: Date = .now,
        durationSeconds: Int = 0,
        totalNotes: Int = 0,
        hits: Int = 0,
        misses: Int = 0,
        maxStreak: Int = 0,
        hitRate: Double = 0,
        isDemoMode: Bool = false
    ) {
        self.date = date
        self.durationSeconds = durationSeconds
        self.totalNotes = totalNotes
        self.hits = hits
        self.misses = misses
        self.maxStreak = maxStreak
        self.hitRate = hitRate
        self.isDemoMode = isDemoMode
    }
}
