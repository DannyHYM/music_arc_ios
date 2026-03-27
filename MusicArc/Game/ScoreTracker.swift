import Foundation

final class ScoreTracker {
    private(set) var totalGrowth: Double = 0.0
    private(set) var treeHealth: Double = 1.0
    private(set) var repGrowths: [Double] = []
    private(set) var repRestScores: [Double] = []
    private(set) var completedReps: Int = 0

    var growthPercentage: Double { min(totalGrowth, 1.0) }

    var averageRestCompliance: Double {
        guard !repRestScores.isEmpty else { return 1.0 }
        return repRestScores.reduce(0, +) / Double(repRestScores.count)
    }

    func addGrowth(_ amount: Double) {
        totalGrowth = min(totalGrowth + amount, 1.0)
    }

    func penalizeHealth(_ amount: Double) {
        treeHealth = max(treeHealth - amount, 0.0)
    }

    func restoreHealth(_ amount: Double) {
        treeHealth = min(treeHealth + amount, 1.0)
    }

    func finishRep(growth: Double, restCompliance: Double) {
        repGrowths.append(growth)
        repRestScores.append(restCompliance)
        completedReps += 1
    }

    func reset() {
        totalGrowth = 0.0
        treeHealth = 1.0
        repGrowths = []
        repRestScores = []
        completedReps = 0
    }
}
