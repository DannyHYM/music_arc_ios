import Foundation

struct GameNote: Identifiable, Hashable {
    let id = UUID()
    let targetHeight: Double
    let scheduledTime: TimeInterval
    var hitTime: TimeInterval?
    var wasHit: Bool = false
    var wasJudged: Bool = false
}
