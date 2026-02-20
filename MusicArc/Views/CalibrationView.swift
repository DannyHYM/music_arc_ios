import SwiftUI
import Combine

struct CalibrationView: View {
    let config: GameConfig
    @Binding var navigationPath: NavigationPath

    @State private var phase: CalibrationPhase = .intro
    @State private var recordedMin: Double = 1.0
    @State private var recordedMax: Double = 0.0
    @State private var currentHeight: Double = 0.5
    @State private var poseProvider: (any PoseProvider)?
    @State private var cancellable: AnyCancellable?
    @State private var phaseTimer: AnyCancellable?
    @State private var progress: Double = 0

    enum CalibrationPhase: String {
        case intro = "Get Ready"
        case raiseArm = "Raise Your Arm"
        case lowerArm = "Lower Your Arm"
        case done = "All Set!"
    }

    private var needsCalibration: Bool {
        config.isCameraMode
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                phaseIcon
                    .font(.system(size: 72))
                    .foregroundStyle(.white)

                Text(phase.rawValue)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(phaseInstruction)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                if phase == .raiseArm || phase == .lowerArm {
                    ProgressView(value: progress)
                        .tint(.purple)
                        .padding(.horizontal, 60)

                    heightBar
                }

                Spacer()

                if phase == .intro {
                    Button {
                        if needsCalibration {
                            startCalibration()
                        } else {
                            skipCalibration()
                        }
                    } label: {
                        Text(needsCalibration ? "Begin Calibration" : "Continue")
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .padding(.horizontal, 40)
                }

                if phase == .done {
                    Button {
                        finishCalibration()
                    } label: {
                        Label("Start Game", systemImage: "play.fill")
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .padding(.horizontal, 40)
                }

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    cleanup()
                    navigationPath.removeLast()
                }
                .foregroundStyle(.white)
            }
        }
        .onDisappear { cleanup() }
    }

    private var phaseIcon: some View {
        Group {
            switch phase {
            case .intro: Image(systemName: needsCalibration ? "figure.stand" : "hand.draw")
            case .raiseArm: Image(systemName: "arrow.up.circle.fill")
            case .lowerArm: Image(systemName: "arrow.down.circle.fill")
            case .done: Image(systemName: "checkmark.circle.fill")
            }
        }
    }

    private var phaseInstruction: String {
        switch phase {
        case .intro:
            if config.isTouchMode {
                return "Touch mode: drag your finger up/down to control arm height.\n\nNo calibration needed."
            } else if config.isDemoMode {
                return "Auto-demo mode will play the game automatically.\n\nNo calibration needed."
            } else {
                return "Stand so the camera can see your upper body. We'll quickly measure your arm range."
            }
        case .raiseArm:
            return "Raise your arm as HIGH as you can and hold it there."
        case .lowerArm:
            return "Now lower your arm as LOW as comfortable and hold."
        case .done:
            return "Calibration complete! Your arm range has been recorded."
        }
    }

    private var heightBar: some View {
        HStack(spacing: 8) {
            Text("Low")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.15))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.purple)
                        .frame(width: geo.size.width * currentHeight)
                }
            }
            .frame(height: 10)
            Text("High")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal, 40)
    }

    private func startCalibration() {
        let provider: any PoseProvider = PoseDetector()
        self.poseProvider = provider

        cancellable = provider.armHeightPublisher
            .receive(on: DispatchQueue.main)
            .sink { height in
                self.currentHeight = height
                if self.phase == .raiseArm {
                    self.recordedMax = max(self.recordedMax, height)
                } else if self.phase == .lowerArm {
                    self.recordedMin = min(self.recordedMin, height)
                }
            }

        provider.start()
        beginRaisePhase()
    }

    private func beginRaisePhase() {
        phase = .raiseArm
        progress = 0
        startPhaseTimer(duration: 4.0) {
            beginLowerPhase()
        }
    }

    private func beginLowerPhase() {
        phase = .lowerArm
        progress = 0
        startPhaseTimer(duration: 4.0) {
            phase = .done
            poseProvider?.stop()
        }
    }

    private func startPhaseTimer(duration: TimeInterval, completion: @escaping () -> Void) {
        let start = Date()
        phaseTimer?.cancel()
        phaseTimer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                let elapsed = Date().timeIntervalSince(start)
                progress = min(elapsed / duration, 1.0)
                if elapsed >= duration {
                    phaseTimer?.cancel()
                    completion()
                }
            }
    }

    private func skipCalibration() {
        let cal = CalibrationData(minHeight: 0.0, maxHeight: 1.0)
        navigationPath.append(AppRoute.game(config, cal))
    }

    private func finishCalibration() {
        let padding = 0.05
        let cal = CalibrationData(
            minHeight: max(0, recordedMin - padding),
            maxHeight: min(1, recordedMax + padding)
        )
        cleanup()
        navigationPath.append(AppRoute.game(config, cal))
    }

    private func cleanup() {
        phaseTimer?.cancel()
        cancellable?.cancel()
        poseProvider?.stop()
    }
}
