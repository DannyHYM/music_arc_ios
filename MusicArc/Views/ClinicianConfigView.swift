import SwiftUI

struct ClinicianConfigView: View {
    @Binding var navigationPath: NavigationPath

    @State private var inputMode: InputMode = .touch
    @State private var trackingArm: TrackingArm = .right
    @State private var repCount: Int = 8
    @State private var activeDuration: Double = 4.0
    @State private var restDuration: Double = 3.0
    @State private var didLoad = false
    @State private var saveBanner: String?

    private var currentConfig: GameConfig {
        let effectiveMode: InputMode = (inputMode == .camera && !GameConfig.cameraAvailable)
            ? .touch
            : inputMode
        return GameConfig(
            repCount: repCount,
            activeDuration: activeDuration,
            restDuration: restDuration,
            inputMode: effectiveMode,
            trackingArm: trackingArm
        )
    }

    private var estimatedTime: Int {
        currentConfig.totalSessionSeconds
    }

    var body: some View {
        ZStack {
            AmbientBlobBackground()

            ScrollView {
                VStack(spacing: 20) {
                    header
                        .padding(.top, 24)

                    sessionConfigSection

                    inputModeSection

                    if inputMode == .camera {
                        trackingArmSection
                    }

                    treePreviewSection

                    actionButtons

                    if let saveBanner {
                        Text(saveBanner)
                            .font(.footnote)
                            .foregroundStyle(.green)
                            .padding(.vertical, 4)
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 28)
            }
        }
        .navigationTitle("Clinician Setup")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadIfNeeded)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 6) {
            Image(systemName: "stethoscope")
                .font(.system(size: 30))
                .foregroundStyle(Color(red: 0.25, green: 0.5, blue: 0.25))

            Text("Configure Patient Exercise")
                .font(.headline)
                .foregroundStyle(Color.forestDark)

            Text("These settings will be used every time the patient taps Begin.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }

    // MARK: - Session Config

    private var sessionConfigSection: some View {
        VStack(spacing: 14) {
            Text("Session")
                .font(.headline)
                .foregroundStyle(Color.forestSoft)

            VStack(spacing: 12) {
                configRow(label: "Reps", value: "\(repCount)", icon: "repeat") {
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

    private func configRow<Content: View>(
        label: String,
        value: String,
        icon: String,
        @ViewBuilder control: () -> Content
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Color.forestAccent)
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
                .foregroundStyle(Color.forestSoft)

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
                Label("Camera not available in Simulator (will fall back to Touch)",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var inputModeDescription: String {
        switch inputMode {
        case .camera:
            return "Front camera tracks the patient's arm via pose detection."
        case .touch:
            return "Patient drags up/down on screen. Useful if camera setup is difficult."
        case .demo:
            return "Auto-demo plays the game automatically — for clinician demonstration."
        }
    }

    // MARK: - Tracking Arm

    private var trackingArmSection: some View {
        VStack(spacing: 10) {
            Text("Tracking Arm")
                .font(.headline)
                .foregroundStyle(Color.forestSoft)

            Picker("Tracking Arm", selection: $trackingArm) {
                ForEach(TrackingArm.allCases, id: \.self) { arm in
                    Text(arm.rawValue).tag(arm)
                }
            }
            .pickerStyle(.segmented)

            Text("Which arm the patient will raise during the exercise.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Tree Preview

    private var treePreviewSection: some View {
        VStack(spacing: 10) {
            Text("Tree Previews")
                .font(.headline)
                .foregroundStyle(Color.forestSoft)

            HStack(spacing: 12) {
                ForEach(TreeSpecies.allCases, id: \.self) { species in
                    Button {
                        navigationPath.append(AppRoute.treePreview(species))
                    } label: {
                        VStack(spacing: 8) {
                            TreeView(growth: 0.85, health: 1.0, species: species)
                                .frame(width: 50, height: 60)
                                .allowsHitTesting(false)
                            Text(species.displayName)
                                .font(.caption.weight(.medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .foregroundStyle(Color.forestMid)
                }
            }

            Text("Tree species is chosen randomly each session.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                save()
            } label: {
                Label("Save Configuration", systemImage: "checkmark.circle.fill")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.forestPrimary)

            Button {
                testRun()
            } label: {
                Label("Test Run", systemImage: "play.circle")
                    .font(.body)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(Color.forestMid)

            Button {
                navigationPath.append(AppRoute.history(clinicianAccess: true))
            } label: {
                Label("View Patient History", systemImage: "list.bullet.rectangle")
                    .font(.body)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(Color.forestMid)
        }
    }

    // MARK: - Persistence

    private func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true

        if let existing = PrescriptionStore.shared.load() {
            let cfg = existing.config
            repCount = cfg.repCount
            activeDuration = cfg.activeDuration
            restDuration = cfg.restDuration
            inputMode = cfg.inputMode
            trackingArm = cfg.trackingArm
        }
    }

    private func save() {
        let prescription = Prescription(config: currentConfig, lastUpdated: .now)
        do {
            try PrescriptionStore.shared.save(prescription)
            saveBanner = "Saved — patient can now press Begin."
        } catch {
            saveBanner = "Couldn't save: \(error.localizedDescription)"
        }
    }

    private func testRun() {
        // Save before testing so the test reflects what the patient will see.
        let prescription = Prescription(config: currentConfig, lastUpdated: .now)
        try? PrescriptionStore.shared.save(prescription)

        let config = currentConfig
        if config.inputMode == .camera {
            navigationPath.append(AppRoute.calibration(config))
        } else {
            let cal = CalibrationData(minHeight: 0.0, maxHeight: 1.0)
            navigationPath.append(AppRoute.game(config, cal))
        }
    }
}

#Preview {
    NavigationStack {
        ClinicianConfigView(navigationPath: .constant(NavigationPath()))
    }
}
