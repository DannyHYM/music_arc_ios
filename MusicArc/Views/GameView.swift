import SwiftUI

struct GameView: View {
    let config: GameConfig
    let calibration: CalibrationData
    @Binding var navigationPath: NavigationPath

    @State private var engine: GameEngine?
    @State private var hasStarted = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let engine {
                NoteLaneView(
                    notes: engine.notes,
                    currentArmHeight: engine.currentArmHeight,
                    elapsedTime: engine.elapsedTime
                )
                .padding()
                .opacity(engine.isInCountdown ? 0.3 : 1.0)

                VStack {
                    HStack {
                        timerDisplay(engine: engine)
                        Spacer()
                        inputModeBadge
                        Spacer()
                        scoreDisplay(engine: engine)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Spacer()

                    heightIndicatorBar(engine: engine)
                        .padding(.bottom, 8)

                    if config.isTouchMode && !engine.isInCountdown && !engine.isFinished {
                        Text("Drag up & down to move")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                            .padding(.bottom, 12)
                    }
                }
                .opacity(engine.isInCountdown ? 0.3 : 1.0)

                if config.isTouchMode && !engine.isInCountdown && !engine.isFinished {
                    touchCaptureLayer(engine: engine)
                }

                if engine.isInCountdown {
                    countdownOverlay(engine: engine)
                }

                if engine.isFinished {
                    finishedOverlay(engine: engine)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true
            let e = GameEngine(config: config, calibration: calibration)
            self.engine = e
            e.start()
        }
        .onDisappear {
            engine?.stop()
        }
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

    // MARK: - Overlays

    private var inputModeBadge: some View {
        Text(config.inputMode.rawValue.uppercased())
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.ultraThinMaterial, in: Capsule())
            .foregroundStyle(.white.opacity(0.7))
    }

    private func countdownOverlay(engine: GameEngine) -> some View {
        VStack(spacing: 16) {
            Text(engine.countdownValue > 0 ? "\(engine.countdownValue)" : "GO!")
                .font(.system(size: 96, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: engine.countdownValue)
            Text(config.isTouchMode ? "Drag up & down to play" : "Get ready...")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private func finishedOverlay(engine: GameEngine) -> some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)
                Text("Session Complete!")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                Text("\(engine.scoreTracker.hits) / \(engine.notes.count) notes hit")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
                Button("View Results") {
                    let result = engine.buildResult()
                    self.engine?.stop()
                    navigationPath.removeLast(navigationPath.count)
                    navigationPath.append(AppRoute.summary(result))
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .padding(.top, 8)
            }
        }
    }

    // MARK: - HUD Elements

    private func timerDisplay(engine: GameEngine) -> some View {
        let remaining = max(0, Double(config.durationSeconds) - engine.elapsedTime)
        return Text(String(format: "%02d:%02d", Int(remaining) / 60, Int(remaining) % 60))
            .font(.system(size: 28, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
    }

    private func scoreDisplay(engine: GameEngine) -> some View {
        HStack(spacing: 12) {
            Label("\(engine.scoreTracker.hits)", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Label("\(engine.scoreTracker.misses)", systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
        }
        .font(.system(size: 18, weight: .semibold, design: .rounded))
    }

    private func heightIndicatorBar(engine: GameEngine) -> some View {
        HStack(spacing: 4) {
            Text("Arm")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.15))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.purple)
                        .frame(width: geo.size.width * engine.currentArmHeight)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 20)
    }
}
