import SwiftUI

struct ContentView: View {
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            HomeView(navigationPath: $navigationPath)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .calibration(let config):
                        CalibrationView(config: config, navigationPath: $navigationPath)
                    case .game(let config, let calibration):
                        GameView(
                            config: config,
                            calibration: calibration,
                            navigationPath: $navigationPath
                        )
                    case .summary(let result):
                        SessionSummaryView(result: result, navigationPath: $navigationPath)
                    case .history:
                        SessionHistoryView()
                    }
                }
        }
    }
}

enum AppRoute: Hashable {
    case calibration(GameConfig)
    case game(GameConfig, CalibrationData)
    case summary(GameResult)
    case history
}

#Preview {
    ContentView()
        .modelContainer(for: GameSession.self, inMemory: true)
}
