import SwiftUI
import UIKit
import AVFoundation

struct GameView: View {
    let config: GameConfig
    let calibration: CalibrationData
    @Binding var navigationPath: NavigationPath

    @State private var engine: GameEngine?
    @State private var hasStarted = false
    @State private var showQuitConfirmation = false
    /// Lives here rather than in CameraPiPView so pausing (which removes the PiP from the
    /// hierarchy) and resuming keeps the patient's choice instead of popping it back open.
    @State private var isCameraPiPCollapsed = false
    @State private var lightHaptic = UIImpactFeedbackGenerator(style: .light)
    @State private var softHaptic = UIImpactFeedbackGenerator(style: .soft)
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let engine {
                TreeGrowthView(
                    phase: engine.currentPhase,
                    handHeight: engine.currentArmHeight,
                    treeGrowth: engine.treeGrowth,
                    treeHealth: engine.treeHealth,
                    isRestingProperly: engine.isRestingProperly,
                    sunlightThreshold: config.sunlightThreshold,
                    restThreshold: config.restThreshold,
                    waterLevel: engine.waterLevel,
                    isInSunlightZone: engine.isInSunlightZone,
                    growthSpurtCount: engine.growthSpurtCount,
                    treeSpecies: engine.treeSpecies
                )
                .ignoresSafeArea()
                .opacity(engine.isInCountdown ? 0.4 : 1.0)

                VStack(spacing: 8) {
                    ZStack {
                        repCounter(engine: engine)

                        if !engine.isInCountdown && !engine.isFinished {
                            HStack {
                                pauseButton(engine: engine)
                                Spacer()
                            }
                        }
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 16)

                    if engine.currentPhase == .active || engine.currentPhase == .rest {
                        phaseTimerDisplay(engine: engine)
                    }

                    Spacer()

                    if config.isTouchMode && !engine.isInCountdown && !engine.isFinished && !engine.isPaused {
                        Text("Drag up & down to move")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(.ultraThinMaterial.opacity(0.5), in: Capsule())
                            .padding(.bottom, 12)
                    }
                }
                .opacity(engine.isInCountdown ? 0.4 : 1.0)

                if config.isTouchMode && !engine.isInCountdown && !engine.isFinished && !engine.isPaused {
                    touchCaptureLayer(engine: engine)
                }

                if !engine.isInCountdown && !engine.isFinished && !engine.isPaused {
                    PhasePromptOverlay(prompt: engine.phasePrompt)
                        .offset(y: -40)
                }

                if config.isCameraMode,
                   let session = engine.poseProvider?.captureSession,
                   !engine.isPaused, !engine.isFinished {
                    cameraPiP(session: session, engine: engine)
                }

                if config.isCameraMode, engine.isTrackingLost,
                   !engine.isPaused, !engine.isFinished {
                    trackingLostBanner
                }

                if engine.isInCountdown {
                    countdownOverlay(engine: engine)
                }

                if engine.isPaused {
                    pauseOverlay(engine: engine)
                }

                if engine.isFinished {
                    finishedOverlay(engine: engine)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert("Leave Session?", isPresented: $showQuitConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                engine?.stop()
                navigationPath.removeLast(navigationPath.count)
            }
        } message: {
            Text("This session's progress will not be saved. You will lose all data from this session.")
        }
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true
            let e = GameEngine(config: config, calibration: calibration)
            e.treeSpecies = .random()
            self.engine = e
            e.start()
            lightHaptic.prepare()
            softHaptic.prepare()
        }
        .onDisappear {
            engine?.stop()
        }
        .onChange(of: engine?.growthSpurtCount ?? 0) { oldVal, newVal in
            guard newVal > oldVal, newVal > 0 else { return }
            lightHaptic.impactOccurred()
            lightHaptic.prepare()
        }
        .onChange(of: engine?.waterLevel ?? 0) { oldVal, newVal in
            if newVal > oldVal && Int(newVal * 5) > Int(oldVal * 5) {
                softHaptic.impactOccurred()
                softHaptic.prepare()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // App moving to background: pause the session. We don't auto-resume
            // on .active because the patient may have put the phone down.
            if newPhase == .background || newPhase == .inactive {
                if let engine, engine.isRunning, !engine.isPaused, !engine.isFinished {
                    engine.pause()
                }
            }
        }
    }

    // MARK: - Camera PiP

    private func cameraPiP(session: AVCaptureSession, engine: GameEngine) -> some View {
        CameraPiPView(session: session, engine: engine, isCollapsed: $isCameraPiPCollapsed)
    }
}

/// Camera preview + skeleton in the top-left, collapsible to a pull tab on the left edge.
///
/// Isolated so the 30 Hz `currentPose` updates re-render only this small view. When the
/// overlay lived inside GameView.body, every pose frame re-evaluated the whole scene
/// (tree, sky, HUD) on the main thread on top of the game tick.
///
/// Collapsing only translates the card off-screen; the capture session and Vision keep
/// running, so tracking, scoring and the tracking-lost banner are unaffected and there is
/// no session re-attach cost when it slides back.
private struct CameraPiPView: View {
    let session: AVCaptureSession
    let engine: GameEngine
    @Binding var isCollapsed: Bool

    private let cardSize = CGSize(width: 110, height: 150)
    private let leadingInset: CGFloat = 12
    private let tabWidth: CGFloat = 22

    var body: some View {
        VStack {
            HStack(spacing: 0) {
                previewCard
                pullTab
                Spacer()
            }
            .padding(.leading, leadingInset)
            // Slide the card fully off-screen so only the tab remains, flush with the edge.
            .offset(x: isCollapsed ? -(cardSize.width + leadingInset) : 0)
            .animation(.easeInOut(duration: 0.25), value: isCollapsed)
            .padding(.top, 60)
            Spacer()
        }
    }

    private var previewCard: some View {
        ZStack {
            CameraPreviewView(session: session)
            SkeletonOverlayView(pose: engine.currentPose)
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture { isCollapsed = true }
        .accessibilityLabel("Camera preview")
        .accessibilityHint("Tap to hide.")
    }

    private var pullTab: some View {
        Button {
            isCollapsed.toggle()
        } label: {
            Image(systemName: isCollapsed ? "chevron.right" : "chevron.left")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: tabWidth, height: 44)
                .background(
                    .ultraThinMaterial.opacity(0.85),
                    in: UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 10,
                        topTrailingRadius: 10
                    )
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isCollapsed ? "Show camera preview" : "Hide camera preview")
    }
}

extension GameView {

    private var trackingLostBanner: some View {
        VStack {
            Spacer().frame(height: 220)
            HStack(spacing: 8) {
                Image(systemName: "video.slash.fill")
                    .foregroundStyle(.orange)
                Text("Move so the camera can see your arm")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial.opacity(0.7), in: Capsule())
            Spacer()
        }
        .allowsHitTesting(false)
    }

    // MARK: - Touch Input

    private func touchCaptureLayer(engine: GameEngine) -> some View {
        GeometryReader { geo in
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let normalized = 1.0 - (value.location.y / geo.size.height)
                            let clamped = min(1.0, max(0.0, normalized))
                            engine.touchProvider?.updateHeight(clamped)
                        }
                )
        }
    }

    // MARK: - Pause Button

    private func pauseButton(engine: GameEngine) -> some View {
        Button {
            engine.pause()
        } label: {
            Image(systemName: "pause.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial.opacity(0.6), in: Circle())
        }
        .accessibilityLabel("Pause session")
    }

    // MARK: - HUD

    private func repCounter(engine: GameEngine) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<config.repCount, id: \.self) { i in
                Circle()
                    .fill(repDotColor(index: i, engine: engine))
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial.opacity(0.5), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rep \(min(engine.currentRepIndex + 1, config.repCount)) of \(config.repCount)")
    }

    private func repDotColor(index: Int, engine: GameEngine) -> Color {
        if index < engine.currentRepIndex {
            return .green.opacity(0.8)
        } else if index == engine.currentRepIndex && !engine.isFinished {
            return .white
        } else {
            return .white.opacity(0.25)
        }
    }

    private func phaseTimerDisplay(engine: GameEngine) -> some View {
        let icon: String
        let label: String
        let color: Color

        switch engine.currentPhase {
        case .active:
            icon = "sun.max.fill"
            label = "Grow!"
            color = .yellow
        case .rest:
            icon = "moon.fill"
            label = "Rest"
            color = .cyan
        default:
            icon = "clock.fill"
            label = ""
            color = .white
        }

        let seconds = Int(ceil(max(0, engine.phaseTimeRemaining)))

        return VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(color)

                Text(label)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text("\(seconds)")
                .font(.system(size: 80, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.2), value: seconds)
        }
        .shadow(color: .black.opacity(0.6), radius: 10, y: 3)
    }

    // MARK: - Overlays

    private func countdownOverlay(engine: GameEngine) -> some View {
        VStack(spacing: 20) {
            Text(engine.countdownValue > 0 ? "\(engine.countdownValue)" : "Grow!")
                .font(.system(size: 96, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: engine.countdownValue)

            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "sun.max.fill")
                        .foregroundStyle(.yellow)
                        .frame(width: 24)
                    Text("Raise your hand to grow the tree")
                        .foregroundStyle(.white.opacity(0.85))
                }

                HStack(spacing: 10) {
                    Image(systemName: "cloud.rain.fill")
                        .foregroundStyle(.cyan)
                        .frame(width: 24)
                    Text("Lower your hand to water it")
                        .foregroundStyle(.white.opacity(0.85))
                }

                if config.isTouchMode {
                    HStack(spacing: 10) {
                        Image(systemName: "hand.draw")
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 24)
                        Text("Drag up & down to control")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial.opacity(0.4), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private func pauseOverlay(engine: GameEngine) -> some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Paused")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.bottom, 8)

                glassmorphicButton(
                    title: "Continue",
                    icon: "play.fill",
                    tint: .green
                ) {
                    engine.resume()
                }

                glassmorphicButton(
                    title: "Restart",
                    icon: "arrow.counterclockwise",
                    tint: .yellow
                ) {
                    engine.stop()
                    let e = GameEngine(config: config, calibration: calibration)
                    e.treeSpecies = .random()
                    self.engine = e
                    e.start()
                }

                glassmorphicButton(
                    title: "Go Home",
                    icon: "house.fill",
                    tint: .red
                ) {
                    showQuitConfirmation = true
                }
            }
        }
    }

    private func glassmorphicButton(
        title: String,
        icon: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 220, height: 54)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(tint.opacity(0.4), lineWidth: 1)
                    )
            }
        }
    }

    private func finishedOverlay(engine: GameEngine) -> some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "tree.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)

                Text("Session Complete!")
                    .font(.title.bold())
                    .foregroundStyle(.white)

                Text("Your tree grew to \(Int(engine.treeGrowth * 100))%")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))

                Button("View Results") {
                    let result = engine.buildResult()
                    self.engine?.stop()
                    navigationPath.removeLast(navigationPath.count)
                    navigationPath.append(AppRoute.summary(result))
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - Phase Prompt

private struct PhasePromptOverlay: View {
    let prompt: String?

    var body: some View {
        ZStack {
            if let prompt {
                Text(prompt)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.6), radius: 8, y: 3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .transition(.opacity.combined(with: .offset(y: -10)))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: prompt)
    }
}

#Preview {
    GameView(
        config: GameConfig(inputMode: .demo),
        calibration: CalibrationData(minHeight: 0.0, maxHeight: 1.0),
        navigationPath: .constant(NavigationPath())
    )
}
