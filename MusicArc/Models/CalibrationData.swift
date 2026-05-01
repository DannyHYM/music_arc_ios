import Foundation

struct CalibrationData: Hashable {
    var minHeight: Double = 0.0
    var maxHeight: Double = 1.0

    func normalize(_ rawValue: Double) -> Double {
        guard maxHeight > minHeight else { return 0.5 }
        let normalized = (rawValue - minHeight) / (maxHeight - minHeight)
        return min(1.0, max(0.0, normalized))
    }
}
