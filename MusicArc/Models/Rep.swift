import Foundation

struct Rep: Identifiable {
    let id = UUID()
    let index: Int
    let activeStartTime: TimeInterval
    let activeDuration: TimeInterval
    let restStartTime: TimeInterval
    let restDuration: TimeInterval
    var growthEarned: Double = 0.0
    var restCompliance: Double = 1.0
    var isComplete: Bool = false

    var totalDuration: TimeInterval { activeDuration + restDuration }
    var activeEndTime: TimeInterval { activeStartTime + activeDuration }
    var restEndTime: TimeInterval { restStartTime + restDuration }
}
