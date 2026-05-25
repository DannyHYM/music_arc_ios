import Foundation

struct Prescription: Codable, Hashable {
    var config: GameConfig
    var lastUpdated: Date

    static let `default` = Prescription(config: GameConfig(), lastUpdated: .now)
}
