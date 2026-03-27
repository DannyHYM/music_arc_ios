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
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Schema changed incompatibly -- delete old store and retry
            let storeURL = config.url
            try? FileManager.default.removeItem(at: storeURL)
            // Also remove journal/wal files
            let dir = storeURL.deletingLastPathComponent()
            let storeName = storeURL.lastPathComponent
            for suffix in ["-shm", "-wal"] {
                try? FileManager.default.removeItem(at: dir.appendingPathComponent(storeName + suffix))
            }
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()
}
