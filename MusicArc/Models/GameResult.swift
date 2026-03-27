import Foundation

struct GameResult: Hashable {
    let date: Date
    let durationSeconds: Int
    let totalReps: Int
    let completedReps: Int
    let treeGrowth: Double
    let treeHealth: Double
    let avgRestCompliance: Double
    let inputMode: InputMode

    var isDemoMode: Bool { inputMode == .demo }

    var growthPercentage: Int { Int(treeGrowth * 100) }
}
