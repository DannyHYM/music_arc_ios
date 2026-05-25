import SwiftUI

extension Color {
    // Forest palette — the canonical greens/browns used across the app.
    // Existing color literals can migrate to these incrementally.

    static let forestDark = Color(red: 0.15, green: 0.35, blue: 0.15)
    static let forestPrimary = Color(red: 0.25, green: 0.6, blue: 0.25)
    static let forestMid = Color(red: 0.2, green: 0.45, blue: 0.2)
    static let forestAccent = Color(red: 0.3, green: 0.6, blue: 0.3)
    static let forestSoft = Color(red: 0.2, green: 0.4, blue: 0.2)

    // Background tones used by AmbientBlobBackground and history backdrops.
    static let mossBackground = Color(red: 0.898, green: 0.965, blue: 0.894)
}
