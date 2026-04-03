import SwiftUI

struct HomeView: View {
    @Binding var navigationPath: NavigationPath
    @State private var inputMode: InputMode = .touch
    @State private var trackingArm: TrackingArm = .right
    @State private var repCount: Int = 8
    @State private var activeDuration: Double = 4.0
    @State private var restDuration: Double = 3.0

    private var estimatedTime: Int {
        let config = GameConfig(
            repCount: repCount,
            activeDuration: activeDuration,
            restDuration: restDuration,
            inputMode: inputMode,
            trackingArm: trackingArm
        )
        return config.totalSessionSeconds
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.85, green: 0.95, blue: 0.85),
                    Color(red: 0.65, green: 0.85, blue: 0.65),
                    Color(red: 0.4, green: 0.65, blue: 0.35)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 20)

                    headerSection

                    sessionConfigSection

                    inputModeSection

                    if inputMode == .camera {
                        trackingArmSection
                    }

                    startButton

                    historyButton

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "tree.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color(red: 0.25, green: 0.55, blue: 0.25))

            Text("MusicArc Forest")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.15, green: 0.35, blue: 0.15))

            Text("Grow your tree through movement")
                .font(.subheadline)
                .foregroundStyle(Color(red: 0.3, green: 0.5, blue: 0.3))
        }
    }

    // MARK: - Session Config

    private var sessionConfigSection: some View {
        VStack(spacing: 16) {
            Text("Session Setup")
                .font(.headline)
                .foregroundStyle(Color(red: 0.2, green: 0.4, blue: 0.2))

            VStack(spacing: 12) {
                configRow(
                    label: "Reps",
                    value: "\(repCount)",
                    icon: "repeat"
                ) {
                    Stepper("", value: $repCount, in: 4...16)
                        .labelsHidden()
                }

                configRow(
                    label: "Hold Time",
                    value: String(format: "%.0fs", activeDuration),
                    icon: "sun.max.fill"
                ) {
                    Stepper("", value: $activeDuration, in: 2...20, step: 1)
                        .labelsHidden()
                }

                configRow(
                    label: "Rest Time",
                    value: String(format: "%.0fs", restDuration),
                    icon: "moon.fill"
                ) {
                    Stepper("", value: $restDuration, in: 2...30, step: 1)
                        .labelsHidden()
                }

                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                    Text("Estimated: \(estimatedTime)s")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private func configRow<Content: View>(label: String, value: String, icon: String, @ViewBuilder control: () -> Content) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Color(red: 0.3, green: 0.6, blue: 0.3))
                .frame(width: 24)
            Text(label)
                .font(.body)
            Spacer()
            Text(value)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(Color(red: 0.2, green: 0.5, blue: 0.2))
                .frame(width: 40, alignment: .trailing)
            control()
        }
    }

    // MARK: - Input Mode

    private var inputModeSection: some View {
        VStack(spacing: 10) {
            Text("Input Mode")
                .font(.headline)
                .foregroundStyle(Color(red: 0.2, green: 0.4, blue: 0.2))

            Picker("Input Mode", selection: $inputMode) {
                ForEach(InputMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text(inputModeDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(height: 32)

            if inputMode == .camera && !GameConfig.cameraAvailable {
                Label("Camera not available in Simulator", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    // MARK: - Tracking Arm

    private var trackingArmSection: some View {
        VStack(spacing: 10) {
            Text("Tracking Arm")
                .font(.headline)
                .foregroundStyle(Color(red: 0.2, green: 0.4, blue: 0.2))

            Picker("Tracking Arm", selection: $trackingArm) {
                ForEach(TrackingArm.allCases, id: \.self) { arm in
                    Label(arm.rawValue, systemImage: arm == .left ? "hand.raised.fill" : "hand.raised.fill")
                        .tag(arm)
                }
            }
            .pickerStyle(.segmented)

            Text("Which arm will you raise during the exercise?")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Buttons

    private var startButton: some View {
        Button {
            let effectiveMode: InputMode
            if inputMode == .camera && !GameConfig.cameraAvailable {
                effectiveMode = .touch
            } else {
                effectiveMode = inputMode
            }
            let config = GameConfig(
                repCount: repCount,
                activeDuration: activeDuration,
                restDuration: restDuration,
                inputMode: effectiveMode,
                trackingArm: trackingArm
            )
            navigationPath.append(AppRoute.calibration(config))
        } label: {
            Label("Start Growing", systemImage: "leaf.fill")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color(red: 0.25, green: 0.6, blue: 0.25))
    }

    private var historyButton: some View {
        Button {
            navigationPath.append(AppRoute.history)
        } label: {
            Label("My Forest", systemImage: "tree.fill")
                .font(.body)
        }
        .foregroundStyle(Color(red: 0.2, green: 0.45, blue: 0.2))
    }

    private var inputModeDescription: String {
        switch inputMode {
        case .camera:
            return "Uses the front camera + body pose tracking"
        case .touch:
            return "Drag up/down on screen to control arm height"
        case .demo:
            return "Automated arm movement (watch the game play itself)"
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(navigationPath: .constant(NavigationPath()))
    }
}
