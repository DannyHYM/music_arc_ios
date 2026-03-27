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
                TreeGrowthView(
                    phase: engine.currentPhase,
                    handHeight: engine.currentArmHeight,
                    treeGrowth: engine.treeGrowth,
                    treeHealth: engine.treeHealth,
                    isRestingProperly: engine.isRestingProperly,
                    sunlightThreshold: config.sunlightThreshold
                )
                .ignoresSafeArea()
                .opacity(engine.isInCountdown ? 0.4 : 1.0)

                VStack {
                    hudBar(engine: engine)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    Spacer()

                    if config.isTouchMode && !engine.isInCountdown && !engine.isFinished {
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

    // MARK: - HUD

    private func hudBar(engine: GameEngine) -> some View {
        HStack(spacing: 0) {
            phaseLabel(engine: engine)

            Spacer()

            repCounter(engine: engine)

            Spacer()

            growthDisplay(engine: engine)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial.opacity(0.6), in: RoundedRectangle(cornerRadius: 14))
    }

    private func phaseLabel(engine: GameEngine) -> some View {
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
            label = "Rest..."
            color = .cyan
        case .countdown:
            icon = "clock.fill"
            label = "Ready"
            color = .white
        case .complete:
            icon = "checkmark.seal.fill"
            label = "Done!"
            color = .green
        }

        return HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 14))

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                if engine.currentPhase == .active || engine.currentPhase == .rest {
                    Text(String(format: "%.1fs", max(0, engine.phaseTimeRemaining)))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .frame(minWidth: 80, alignment: .leading)
    }

    private func repCounter(engine: GameEngine) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<config.repCount, id: \.self) { i in
                Circle()
                    .fill(repDotColor(index: i, engine: engine))
                    .frame(width: 7, height: 7)
            }
        }
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

    private func growthDisplay(engine: GameEngine) -> some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 2.5)
                Circle()
                    .trim(from: 0, to: engine.treeGrowth)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 24, height: 24)

            Text("\(Int(engine.treeGrowth * 100))%")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.green)
        }
        .frame(minWidth: 70, alignment: .trailing)
    }

    // MARK: - Overlays

    private func countdownOverlay(engine: GameEngine) -> some View {
        VStack(spacing: 16) {
            Text(engine.countdownValue > 0 ? "\(engine.countdownValue)" : "Grow!")
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

#Preview {
    GameView(
        config: GameConfig(inputMode: .demo),
        calibration: CalibrationData(minHeight: 0.0, maxHeight: 1.0),
        navigationPath: .constant(NavigationPath())
    )
}
