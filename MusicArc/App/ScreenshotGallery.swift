#if DEBUG
import SwiftUI
import SwiftData
import AVFoundation
import Combine

/// Debug-only screenshot gallery.
///
/// Renders each product screen with fixed fake data so the real UI can be captured by
/// `scripts/capture_ui_screenshots.sh` (output in `docs/ui/`). Activated by launching the app
/// with the `MUSICARC_SCREENSHOT` environment variable set to one of `screenNames`; without it
/// the app behaves normally. The whole file is compiled out of release builds, and the product
/// views only carry tiny `#if DEBUG` injection points (a mock engine, a mock calibration state).
enum ScreenshotGallery {
    static let screenNames: [String] = [
        "welcome",
        "clinician-pin", "clinician-setup",
        "calibration-intro", "calibration-raise", "calibration-done",
        "game-countdown", "game-active", "game-rest", "game-paused", "game-finished",
        "summary", "history",
        "tree-oak", "tree-round", "tree-bushy", "tree-pine", "tree-acacia",
    ]

    static var requestedScreen: String? {
        ProcessInfo.processInfo.environment["MUSICARC_SCREENSHOT"]
    }

    static var isActive: Bool { requestedScreen != nil }

    // MARK: - Fake data

    /// The prescription the clinician "saved": deliberately non-default so the setup screen
    /// reads as configured.
    static let sampleConfig = GameConfig(
        repCount: 10,
        activeDuration: 5,
        restDuration: 4,
        inputMode: .camera,
        trackingArm: .right
    )

    /// Used by the calibration and game screens (default cadence, camera, right arm).
    static let gameConfig = GameConfig(inputMode: .camera, trackingArm: .right)

    static let sampleResult = GameResult(
        date: .now,
        durationSeconds: 61,
        totalReps: 8,
        completedReps: 8,
        treeGrowth: 0.87,
        treeHealth: 0.93,
        avgRestCompliance: 0.9,
        inputMode: .camera,
        treeSpecies: .pine
    )

    /// Vision-space poses (origin bottom-left, unmirrored) that land on `PlaceholderPersonView`'s
    /// silhouette once SkeletonOverlayView flips X and Y.
    static let raisedArmPose = ArmPose(
        shoulder: CGPoint(x: 0.34, y: 0.58),
        elbow: CGPoint(x: 0.27, y: 0.72),
        wrist: CGPoint(x: 0.23, y: 0.88),
        normalizedHeight: 0.9,
        isTracking: true
    )

    static let loweredArmPose = ArmPose(
        shoulder: CGPoint(x: 0.34, y: 0.58),
        elbow: CGPoint(x: 0.30, y: 0.42),
        wrist: CGPoint(x: 0.29, y: 0.28),
        normalizedHeight: 0.15,
        isTracking: true
    )

    // MARK: - Screens

    @MainActor
    static func makeView(for name: String) -> AnyView {
        switch name {
        case "welcome":
            seedPrescription()
            return AnyView(GalleryStack(pushed: false) { _ in EmptyView() })

        case "clinician-pin":
            return AnyView(GalleryStack { ClinicianPinView(navigationPath: $0) })

        case "clinician-setup":
            seedPrescription()
            return AnyView(GalleryStack { ClinicianConfigView(navigationPath: $0) })

        case "calibration-intro":
            return AnyView(GalleryStack {
                CalibrationView(config: gameConfig, navigationPath: $0, mock: CalibrationMock(
                    phase: .intro, pose: loweredArmPose, height: 0.2, progress: 0
                ))
            })

        case "calibration-raise":
            return AnyView(GalleryStack {
                CalibrationView(config: gameConfig, navigationPath: $0, mock: CalibrationMock(
                    phase: .raiseArm, pose: raisedArmPose, height: 0.88, progress: 0.6
                ))
            })

        case "calibration-done":
            return AnyView(GalleryStack {
                CalibrationView(config: gameConfig, navigationPath: $0, mock: CalibrationMock(
                    phase: .done, pose: loweredArmPose, height: 0.2, progress: 1
                ))
            })

        case "game-countdown":
            return AnyView(GalleryStack { gameView(engine: makeEngine(.countdown), path: $0) })

        case "game-active":
            return AnyView(GalleryStack { gameView(engine: makeEngine(.active), path: $0) })

        case "game-rest":
            return AnyView(GalleryStack { gameView(engine: makeEngine(.rest), path: $0) })

        case "game-paused":
            return AnyView(GalleryStack { gameView(engine: makeEngine(.paused), path: $0) })

        case "game-finished":
            return AnyView(GalleryStack { gameView(engine: makeEngine(.finished), path: $0) })

        case "summary":
            return AnyView(GalleryStack { SessionSummaryView(result: sampleResult, navigationPath: $0) })

        case "history":
            return AnyView(
                GalleryStack { _ in SessionHistoryView(clinicianAccess: false) }
                    .modelContainer(makeHistoryContainer())
            )

        case let name where name.hasPrefix("tree-"):
            let species = TreeSpecies(rawValue: String(name.dropFirst("tree-".count))) ?? .oak
            return AnyView(GalleryStack {
                TreePreviewView(species: species, navigationPath: $0, initialGrowth: 1.0)
            })

        default:
            return AnyView(Text("Unknown screenshot screen: \(name)"))
        }
    }

    // MARK: - Builders

    private static func seedPrescription() {
        try? PrescriptionStore.shared.save(Prescription(config: sampleConfig, lastUpdated: .now))
    }

    @MainActor
    private static func gameView(engine: GameEngine, path: Binding<NavigationPath>) -> some View {
        GameView(
            config: gameConfig,
            calibration: CalibrationData(),
            navigationPath: path,
            mockEngine: engine
        )
    }

    enum GameMockState {
        case countdown, active, rest, paused, finished
    }

    /// A GameEngine frozen mid-session. No timers or providers run; GameView just renders it.
    @MainActor
    static func makeEngine(_ state: GameMockState) -> GameEngine {
        let engine = GameEngine(config: gameConfig, calibration: CalibrationData())
        engine.treeSpecies = .oak
        engine.reps = RepScheduler.generate(config: gameConfig)
        engine.isRunning = true

        switch state {
        case .countdown:
            // No provider: in the product the pipeline doesn't exist until the countdown ends,
            // so the camera PiP must not appear here.
            engine.isInCountdown = true
            engine.countdownValue = 3
            engine.currentPhase = .countdown

        case .active, .paused:
            engine.installMockProvider(MockPoseProvider())
            engine.isInCountdown = false
            engine.currentPhase = .active
            engine.currentRepIndex = 3
            engine.phaseTimeRemaining = 2.4
            engine.treeGrowth = 0.42
            engine.treeHealth = 0.95
            engine.waterLevel = 0.7
            engine.currentArmHeight = 0.85
            engine.isInSunlightZone = true
            engine.currentPose = raisedArmPose
            engine.isPaused = (state == .paused)

        case .rest:
            engine.installMockProvider(MockPoseProvider())
            engine.isInCountdown = false
            engine.currentPhase = .rest
            engine.currentRepIndex = 3
            engine.phaseTimeRemaining = 1.8
            engine.treeGrowth = 0.48
            engine.treeHealth = 0.95
            engine.waterLevel = 0.55
            engine.currentArmHeight = 0.15
            engine.isRestingProperly = true
            engine.isInSunlightZone = false
            engine.currentPose = loweredArmPose
            engine.phasePrompt = "Rest & water your tree"

        case .finished:
            engine.isInCountdown = false
            engine.currentPhase = .complete
            engine.currentRepIndex = gameConfig.repCount
            engine.treeGrowth = 0.87
            engine.treeHealth = 0.93
            engine.isRunning = false
            engine.isFinished = true
        }
        return engine
    }

    @MainActor
    private static func makeHistoryContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: GameSession.self, configurations: config)
        let day: TimeInterval = 86_400
        let samples: [(daysAgo: Double, growth: Double, health: Double, species: TreeSpecies)] = [
            (13, 0.35, 1.0, .oak),
            (10, 0.60, 0.9, .round),
            (7, 0.78, 0.95, .bushy),
            (4, 0.92, 1.0, .pine),
            (1, 0.85, 0.8, .acacia),
        ]
        for sample in samples {
            container.mainContext.insert(GameSession(
                date: Date(timeIntervalSinceNow: -sample.daysAgo * day),
                durationSeconds: 61,
                totalReps: 8,
                completedReps: 8,
                treeGrowth: sample.growth,
                treeHealth: sample.health,
                avgRestCompliance: 0.9,
                isDemoMode: false,
                treeSpecies: sample.species
            ))
        }
        return container
    }
}

// MARK: - Supporting types

/// Fixed calibration state injected into CalibrationView in place of the live camera pipeline.
struct CalibrationMock {
    let phase: CalibrationView.CalibrationPhase
    let pose: ArmPose
    let height: Double
    let progress: Double
}

/// A PoseProvider that never publishes. Exposes a session so GameView shows the camera PiP.
final class MockPoseProvider: PoseProvider {
    let armHeightPublisher: AnyPublisher<Double, Never> = Empty().eraseToAnyPublisher()
    let captureSession: AVCaptureSession? = AVCaptureSession()
    func start() {}
    func stop() {}
}

/// Stand-in for the live camera feed: a dim room with a person silhouette whose right arm
/// (viewer's right, as in the mirrored preview) is raised or lowered. The geometry matches
/// `ScreenshotGallery.raisedArmPose` / `loweredArmPose` so the real SkeletonOverlayView
/// lands on the figure.
struct PlaceholderPersonView: View {
    var armRaised: Bool = true

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * w, y: y * h) }

            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    Gradient(colors: [
                        Color(red: 0.20, green: 0.22, blue: 0.25),
                        Color(red: 0.08, green: 0.09, blue: 0.11),
                    ]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: h)
                )
            )

            let body = GraphicsContext.Shading.color(Color(white: 0.72).opacity(0.55))
            let limb = StrokeStyle(lineWidth: w * 0.075, lineCap: .round, lineJoin: .round)

            let headRadius = w * 0.085
            context.fill(
                Path(ellipseIn: CGRect(
                    x: 0.5 * w - headRadius, y: 0.30 * h - headRadius,
                    width: 2 * headRadius, height: 2 * headRadius
                )),
                with: body
            )

            var neck = Path()
            neck.move(to: at(0.5, 0.36))
            neck.addLine(to: at(0.5, 0.44))
            context.stroke(neck, with: body, style: limb)

            var torso = Path()
            torso.move(to: at(0.34, 0.42))
            torso.addLine(to: at(0.66, 0.42))
            torso.addLine(to: at(0.60, 0.85))
            torso.addLine(to: at(0.40, 0.85))
            torso.closeSubpath()
            context.fill(torso, with: body)

            var leftArm = Path()
            leftArm.move(to: at(0.34, 0.42))
            leftArm.addLine(to: at(0.30, 0.58))
            leftArm.addLine(to: at(0.29, 0.72))
            context.stroke(leftArm, with: body, style: limb)

            var rightArm = Path()
            rightArm.move(to: at(0.66, 0.42))
            if armRaised {
                rightArm.addLine(to: at(0.73, 0.28))
                rightArm.addLine(to: at(0.77, 0.12))
            } else {
                rightArm.addLine(to: at(0.70, 0.58))
                rightArm.addLine(to: at(0.71, 0.72))
            }
            context.stroke(rightArm, with: body, style: limb)
        }
    }
}

/// Real navigation chrome for a gallery screen: a NavigationStack rooted at WelcomeView with
/// `content` pushed on top, so the Back button and title bar match the product.
private struct GalleryStack<Content: View>: View {
    @State private var path: NavigationPath
    private let content: (Binding<NavigationPath>) -> Content

    init(pushed: Bool = true, @ViewBuilder content: @escaping (Binding<NavigationPath>) -> Content) {
        var initialPath = NavigationPath()
        if pushed {
            initialPath.append("gallery-screen")
        }
        _path = State(initialValue: initialPath)
        self.content = content
    }

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView(navigationPath: $path)
                .navigationDestination(for: String.self) { _ in
                    content($path)
                }
        }
    }
}
#endif
