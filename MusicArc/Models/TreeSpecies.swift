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

    var renderer: any TreeRenderer {
        switch self {
        case .oak: return OakTreeRenderer()
        case .round: return RoundTreeRenderer()
        case .bushy: return BushyTreeRenderer()
        case .pine: return PineTreeRenderer()
        case .acacia: return AcaciaTreeRenderer()
        }
    }

    static func random() -> TreeSpecies {
        allCases.randomElement() ?? .oak
    }
}
