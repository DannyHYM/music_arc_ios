import Foundation

final class ScoreTracker {
    private(set) var hits = 0
    private(set) var misses = 0
    private(set) var currentStreak = 0
    private(set) var maxStreak = 0

    var totalJudged: Int { hits + misses }

    var hitRate: Double {
        guard totalJudged > 0 else { return 0 }
        return Double(hits) / Double(totalJudged)
    }

    func recordHit() {
        hits += 1
        currentStreak += 1
        maxStreak = max(maxStreak, currentStreak)
    }

    func recordMiss() {
        misses += 1
        currentStreak = 0
    }

    func reset() {
        hits = 0
        misses = 0
        currentStreak = 0
        maxStreak = 0
    }
}
