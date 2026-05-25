import SwiftUI
import SwiftData

@main
struct MusicArcApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(Self.sharedModelContainer)
    }

    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([GameSession.self])
        let persistentConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [persistentConfig])
        } catch {
            // The persistent store could not be opened (typically a schema change).
            // Fall back to an in-memory container so the app stays usable, but preserve
            // the on-disk store untouched — a real migration plan can recover from it
            // in a future release. Patient sees an empty history this launch.
            NSLog("MusicArc: persistent ModelContainer failed (\(error)); falling back to in-memory.")
            let inMemoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [inMemoryConfig])
            } catch {
                fatalError("Could not create even an in-memory ModelContainer: \(error)")
            }
        }
    }()
}
