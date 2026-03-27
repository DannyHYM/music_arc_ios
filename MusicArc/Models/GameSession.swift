import Foundation
import SwiftData

@Model
final class GameSession {
    var date: Date
    var durationSeconds: Int
    var totalReps: Int
    var completedReps: Int
    var treeGrowth: Double
    var treeHealth: Double
    var avgRestCompliance: Double
    var isDemoMode: Bool

    init(
        date: Date = .now,
        durationSeconds: Int = 0,
        totalReps: Int = 0,
        completedReps: Int = 0,
        treeGrowth: Double = 0,
        treeHealth: Double = 1.0,
        avgRestCompliance: Double = 1.0,
        isDemoMode: Bool = false
    ) {
        self.date = date
        self.durationSeconds = durationSeconds
        self.totalReps = totalReps
        self.completedReps = completedReps
        self.treeGrowth = treeGrowth
        self.treeHealth = treeHealth
        self.avgRestCompliance = avgRestCompliance
        self.isDemoMode = isDemoMode
    }
}
