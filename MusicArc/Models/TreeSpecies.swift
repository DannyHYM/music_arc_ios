import Foundation

enum TreeSpecies: String, CaseIterable, Codable {
    case oak
    case round
    case bushy
    case pine
    case acacia

    var displayName: String {
        switch self {
        case .oak: return "Oak"
        case .round: return "Round"
        case .bushy: return "Bushy"
        case .pine: return "Pine"
        case .acacia: return "Acacia"
        }
    }

    private static let oakRenderer = OakTreeRenderer()
    private static let roundRenderer = RoundTreeRenderer()
    private static let bushyRenderer = BushyTreeRenderer()
    private static let pineRenderer = PineTreeRenderer()
    private static let acaciaRenderer = AcaciaTreeRenderer()

    var renderer: any TreeRenderer {
        switch self {
        case .oak: return Self.oakRenderer
        case .round: return Self.roundRenderer
        case .bushy: return Self.bushyRenderer
        case .pine: return Self.pineRenderer
        case .acacia: return Self.acaciaRenderer
        }
    }

    static func random() -> TreeSpecies {
        allCases.randomElement() ?? .oak
    }
}
