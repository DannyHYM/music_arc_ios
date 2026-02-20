import SwiftUI
import SwiftData

@main
struct MusicArcApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: GameSession.self)
    }
}
