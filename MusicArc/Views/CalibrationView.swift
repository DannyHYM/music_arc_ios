import SwiftUI
import Combine
import AVFoundation

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
    @State private var phaseStartedAt: Date?

    private let phaseDuration: TimeInterval = 4.0
    private let settleDuration: TimeInterval = 1.5
    private let samplingGracePeriod: TimeInterval = 0.5
    private let minimumRange: Double = 0.15

    enum CalibrationPhase: Equatable {
        case intro
        case raiseArm
        case settle
        case lowerArm
        case done
        case failedNarrowRange
        case cameraDenied
    }

    private var needsCalibration: Bool {
        config.isCameraMode
    }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 32) {
                if needsCalibration && phase != .cameraDenied {
                    trackingStatusBadge
                        .padding(.top, 16)
                }

                Spacer()

                phaseIcon
                    .font(.system(size: 72))
                    .foregroundStyle(.white)

                Text(phaseTitle)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text(phaseInstruction)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                if phase == .raiseArm || phase == .lowerArm || phase == .settle {
                    ProgressView(value: progress)
                        .tint(phase == .settle ? .yellow : .green)
                        .padding(.horizontal, 60)

                    heightBar
                }

                Spacer()

                phaseActionButtons

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
        .onAppear(perform: handleAppear)
        .onDisappear { cleanup() }
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundLayer: some View {
        if needsCalibration, let detector = poseDetector, let session = detector.captureSession, phase != .cameraDenied {
            CameraPreviewView(session: session)
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
            case .settle: Image(systemName: "hourglass")
            case .lowerArm: Image(systemName: "arrow.down.to.line")
            case .done: Image(systemName: "checkmark.circle.fill")
            case .failedNarrowRange: Image(systemName: "exclamationmark.triangle.fill")
            case .cameraDenied: Image(systemName: "video.slash.fill")
            }
        }
    }

    private var phaseTitle: String {
        switch phase {
        case .intro: return "Get Ready"
        case .raiseArm: return "Reach for the Sun"
        case .settle: return "Get Set"
        case .lowerArm: return "Return to Earth"
        case .done: return "All Set!"
        case .failedNarrowRange: return "Let's Try Again"
        case .cameraDenied: return "Camera Needed"
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
                return "Stand about an arm's length from the phone so your shoulders are in frame.\n\nWhen you're ready, tap Begin Calibration."
            }
        case .raiseArm:
            return "Raise your hand as HIGH as you can and hold it there.\nThis is how high the sun will go!"
        case .settle:
            return "Get ready to lower your arm…"
        case .lowerArm:
            return "Now lower your hand as LOW as comfortable and hold.\nThis is your resting position."
        case .done:
            return "Calibration complete! Your range has been recorded.\nLet's grow a tree!"
        case .failedNarrowRange:
            return "We didn't see your arm move enough.\nMake sure you raise and lower as much as you can, and try again."
        case .cameraDenied:
            return "Camera access is needed for pose tracking.\nOpen Settings to enable it, or use Touch mode instead."
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

    // MARK: - Action Buttons

    @ViewBuilder
    private var phaseActionButtons: some View {
        switch phase {
        case .intro:
            Button {
                if needsCalibration {
                    requestCameraAndStart()
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
            .tint(Color.forestPrimary)
            .padding(.horizontal, 40)

        case .done:
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

        case .failedNarrowRange:
            Button {
                restartCalibration()
            } label: {
                Label("Try Again", systemImage: "arrow.counterclockwise")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .padding(.horizontal, 40)

        case .cameraDenied:
            VStack(spacing: 12) {
                Button {
                    openSettings()
                } label: {
                    Label("Open Settings", systemImage: "gear")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)

                Button {
                    cleanup()
                    navigationPath.removeLast()
                } label: {
                    Text("Back")
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .tint(.white)
            }
            .padding(.horizontal, 40)

        default:
            EmptyView()
        }
    }

    // MARK: - Lifecycle

    private func handleAppear() {
        // For non-camera modes, no setup is required — patient taps Continue from the intro.
        guard needsCalibration else { return }

        // Don't start the pose detector until the user opts in via "Begin Calibration".
        // This avoids triggering the camera permission prompt at view appear.
    }

    private func requestCameraAndStart() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            setupPoseDetector()
            startCalibration()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        setupPoseDetector()
                        startCalibration()
                    } else {
                        phase = .cameraDenied
                    }
                }
            }
        case .denied, .restricted:
            phase = .cameraDenied
        @unknown default:
            phase = .cameraDenied
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Pose Detection

    private func setupPoseDetector() {
        // Tear down any prior detector before creating a new one.
        heightCancellable?.cancel()
        poseCancellable?.cancel()
        poseDetector?.stop()

        let detector = PoseDetector(trackingArm: config.trackingArm)
        self.poseDetector = detector

        heightCancellable = detector.armHeightPublisher
            .receive(on: DispatchQueue.main)
            .sink { height in
                self.currentHeight = height
                guard self.isSamplingActive else { return }
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

    private var isSamplingActive: Bool {
        guard let phaseStartedAt else { return false }
        return Date().timeIntervalSince(phaseStartedAt) >= samplingGracePeriod
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
        phaseStartedAt = Date()
        startPhaseTimer(duration: phaseDuration) {
            beginSettlePhase()
        }
    }

    private func beginSettlePhase() {
        phase = .settle
        progress = 0
        phaseStartedAt = Date()
        startPhaseTimer(duration: settleDuration) {
            beginLowerPhase()
        }
    }

    private func beginLowerPhase() {
        phase = .lowerArm
        progress = 0
        phaseStartedAt = Date()
        startPhaseTimer(duration: phaseDuration) {
            validateAndComplete()
        }
    }

    private func validateAndComplete() {
        let range = recordedMax - recordedMin
        if range >= minimumRange {
            phase = .done
        } else {
            phase = .failedNarrowRange
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
