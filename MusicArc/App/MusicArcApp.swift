import SwiftUI
import SwiftData

@main
struct MusicArcApp: App {
    init() {
        // Warm the audio session/engine up long before the first game so the first tone
        // doesn't stall the main thread on hardware start-up. Runs in the background.
        AudioManager.shared.prepare()
        #if DEBUG
        MainThreadWatchdog.start()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(Self.sharedModelContainer)
    }

    #if DEBUG
    /// Debug-only diagnostic for the "UI frozen but camera preview still moving" reports.
    /// Pings the main run loop every 100 ms and logs any stall longer than `threshold`, so a
    /// remaining hang shows up in the Xcode console with its duration.
    private enum MainThreadWatchdog {
        static let threshold: TimeInterval = 0.25

        static func start() {
            let thread = Thread {
                while true {
                    let sema = DispatchSemaphore(value: 0)
                    let sent = Date()
                    DispatchQueue.main.async { sema.signal() }
                    if sema.wait(timeout: .now() + threshold) == .timedOut {
                        sema.wait()
                        NSLog("MusicArc: main thread stalled for %.0f ms", Date().timeIntervalSince(sent) * 1000)
                    }
                    Thread.sleep(forTimeInterval: 0.1)
                }
            }
            thread.name = "MusicArc.MainThreadWatchdog"
            thread.qualityOfService = .utility
            thread.start()
        }
    }
    #endif

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
