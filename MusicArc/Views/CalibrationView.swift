import SwiftUI
import Combine

struct CalibrationView: View {
    let config: GameConfig
    @Binding var navigationPath: NavigationPath

    @State private var phase: CalibrationPhase = .intro
    @State private var recordedMin: Double = 1.0
    @State private var recordedMax: Double = 0.0
    @State private var currentHeight: Double = 0.5
    @State private var currentPose = ArmPose(
        shoulder: nil, elbow: nil, wrist: nil,
        normalizedHeight: 0.5, isTracking: false
    )
    @State private var poseDetector: PoseDetector?
    @State private var heightCancellable: AnyCancellable?
    @State private var poseCancellable: AnyCancellable?
    @State private var phaseTimer: AnyCancellable?
    @State private var progress: Double = 0

    enum CalibrationPhase: String {
        case intro = "Get Ready"
        case raiseArm = "Reach for the Sun"
        case lowerArm = "Return to Earth"
        case done = "All Set!"
    }

    private var needsCalibration: Bool {
        config.isCameraMode
    }

    var body: some View {
        ZStack {
            if needsCalibration, let detector = poseDetector {
                CameraPreviewView(session: detector.captureSession)
                    .ignoresSafeArea()

                SkeletonOverlayView(pose: currentPose)
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.55),
                        Color.black.opacity(0.2),
                        Color.black.opacity(0.55)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.15, green: 0.25, blue: 0.1),
                        Color(red: 0.1, green: 0.18, blue: 0.08),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }

            VStack(spacing: 32) {
                if needsCalibration {
                    trackingStatusBadge
                        .padding(.top, 16)
                }

                Spacer()

                phaseIcon
                    .font(.system(size: 72))
                    .foregroundStyle(.white)

                Text(phase.rawValue)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(phaseInstruction)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                if phase == .raiseArm || phase == .lowerArm {
                    ProgressView(value: progress)
                        .tint(.green)
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
                    .tint(Color(red: 0.25, green: 0.6, blue: 0.25))
                    .padding(.horizontal, 40)
                }

                if phase == .done {
                    VStack(spacing: 12) {
                        Button {
                            finishCalibration()
                        } label: {
                            Label("Start Growing", systemImage: "leaf.fill")
                                .font(.title3.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)

                        Button {
                            restartCalibration()
                        } label: {
                            Label("Re-calibrate", systemImage: "arrow.counterclockwise")
                                .font(.body.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)
                    }
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
        .onAppear {
            if needsCalibration {
                setupPoseDetector()
            }
        }
        .onDisappear { cleanup() }
    }

    // MARK: - Tracking Status

    private var trackingStatusBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(currentPose.isTracking ? Color.green : Color.orange)
                .frame(width: 8, height: 8)

            Text(currentPose.isTracking ? "Tracking your arm" : "Looking for you\u{2026}")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial.opacity(0.6), in: Capsule())
    }

    // MARK: - Phase UI

    private var phaseIcon: some View {
        Group {
            switch phase {
            case .intro: Image(systemName: needsCalibration ? "figure.stand" : "hand.draw")
            case .raiseArm: Image(systemName: "sun.max.fill")
            case .lowerArm: Image(systemName: "arrow.down.to.line")
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
                return "Position yourself so the camera can see your upper body.\nCheck the tracking dots on your arm, then tap begin."
            }
        case .raiseArm:
            return "Raise your hand as HIGH as you can and hold it there.\nThis is how high the sun will go!"
        case .lowerArm:
            return "Now lower your hand as LOW as comfortable and hold.\nThis is your resting position."
        case .done:
            return "Calibration complete! Your range has been recorded.\nLet's grow a tree!"
        }
    }

    private var heightBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.down")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.15))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.green.opacity(0.6), .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * currentHeight)
                }
            }
            .frame(height: 10)
            Image(systemName: "sun.max.fill")
                .font(.caption2)
                .foregroundStyle(.yellow.opacity(0.7))
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Pose Detection

    private func setupPoseDetector() {
        let detector = PoseDetector(trackingArm: config.trackingArm)
        self.poseDetector = detector

        heightCancellable = detector.armHeightPublisher
            .receive(on: DispatchQueue.main)
            .sink { height in
                self.currentHeight = height
                if self.phase == .raiseArm {
                    self.recordedMax = max(self.recordedMax, height)
                } else if self.phase == .lowerArm {
                    self.recordedMin = min(self.recordedMin, height)
                }
            }

        poseCancellable = detector.armPosePublisher?
            .receive(on: DispatchQueue.main)
            .sink { pose in
                self.currentPose = pose
            }

        detector.start()
    }

    // MARK: - Calibration Flow

    private func startCalibration() {
        beginRaisePhase()
    }

    private func restartCalibration() {
        phaseTimer?.cancel()
        recordedMin = 1.0
        recordedMax = 0.0
        progress = 0
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
        heightCancellable?.cancel()
        poseCancellable?.cancel()
        poseDetector?.stop()
        poseDetector = nil
    }
}

#Preview {
    NavigationStack {
        CalibrationView(
            config: GameConfig(inputMode: .touch),
            navigationPath: .constant(NavigationPath())
        )
    }
}
