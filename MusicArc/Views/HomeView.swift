import SwiftUI

struct HomeView: View {
    @Binding var navigationPath: NavigationPath
    @State private var inputMode: InputMode = .touch
    @State private var sessionDuration = 60

    private let durationOptions = [30, 45, 60, 90]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemBackground), Color.purple.opacity(0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "waveform.path")
                        .font(.system(size: 64))
                        .foregroundStyle(.purple)
                    Text("Music Arc")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                    Text("Rehab Game Prototype")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(spacing: 16) {
                    Text("Session Duration")
                        .font(.headline)
                    Picker("Duration", selection: $sessionDuration) {
                        ForEach(durationOptions, id: \.self) { d in
                            Text("\(d)s").tag(d)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 40)
                }

                VStack(spacing: 10) {
                    Text("Input Mode")
                        .font(.headline)

                    Picker("Input Mode", selection: $inputMode) {
                        ForEach(InputMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 40)

                    Text(inputModeDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .frame(height: 32)

                    if inputMode == .camera && !GameConfig.cameraAvailable {
                        Label("Camera not available in Simulator", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Button {
                    let effectiveMode: InputMode
                    if inputMode == .camera && !GameConfig.cameraAvailable {
                        effectiveMode = .touch
                    } else {
                        effectiveMode = inputMode
                    }
                    let config = GameConfig(
                        durationSeconds: sessionDuration,
                        inputMode: effectiveMode
                    )
                    navigationPath.append(AppRoute.calibration(config))
                } label: {
                    Label("Start Session", systemImage: "play.fill")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .padding(.horizontal, 40)

                Button {
                    navigationPath.append(AppRoute.history)
                } label: {
                    Label("Session History", systemImage: "clock.arrow.circlepath")
                        .font(.body)
                }
                .padding(.bottom, 8)

                Spacer()
            }
        }
        .navigationBarHidden(true)
    }

    private var inputModeDescription: String {
        switch inputMode {
        case .camera:
            return "Uses the rear camera + body pose tracking"
        case .touch:
            return "Drag up/down on screen to control arm height"
        case .demo:
            return "Automated arm movement (watch the game play itself)"
        }
    }
}
