import SwiftUI

struct ContentView: View {
    @State private var navigationPath = NavigationPath()

    var body: some View {
        #if DEBUG
        if let screen = ScreenshotGallery.requestedScreen {
            ScreenshotGallery.makeView(for: screen)
        } else {
            productBody
        }
        #else
        productBody
        #endif
    }

    private var productBody: some View {
        NavigationStack(path: $navigationPath) {
            WelcomeView(navigationPath: $navigationPath)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .clinicianPin:
                        ClinicianPinView(navigationPath: $navigationPath)
                    case .clinicianConfig:
                        ClinicianConfigView(navigationPath: $navigationPath)
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
                    case .history(let clinicianAccess):
                        SessionHistoryView(clinicianAccess: clinicianAccess)
                    case .treePreview(let species):
                        TreePreviewView(species: species, navigationPath: $navigationPath)
                    }
                }
        }
    }
}

enum AppRoute: Hashable {
    case clinicianPin
    case clinicianConfig
    case calibration(GameConfig)
    case game(GameConfig, CalibrationData)
    case summary(GameResult)
    case history(clinicianAccess: Bool)
    case treePreview(TreeSpecies)
}

#Preview {
    ContentView()
        .modelContainer(for: GameSession.self, inMemory: true)
}
