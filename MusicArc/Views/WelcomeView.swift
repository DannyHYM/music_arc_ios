import SwiftUI

struct WelcomeView: View {
    @Binding var navigationPath: NavigationPath

    @State private var prescription: Prescription?
    @State private var didLoad = false

    var body: some View {
        ZStack {
            AmbientBlobBackground()

            VStack(spacing: 28) {
                Spacer()

                titleSection

                Spacer().frame(height: 16)

                if prescription != nil {
                    beginButton
                } else {
                    emptyPrescriptionCard
                }

                myTreesButton

                Spacer()

                clinicianLink
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 32)
        }
        .navigationBarHidden(true)
        .dynamicTypeSize(.medium ... .accessibility3)
        .onAppear(perform: loadPrescription)
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "tree.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color(red: 0.25, green: 0.55, blue: 0.25))

            Text("Welcome to MusicArc")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.15, green: 0.35, blue: 0.15))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Begin Button

    private var beginButton: some View {
        Button(action: beginSession) {
            Label("Begin", systemImage: "leaf.fill")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color(red: 0.25, green: 0.6, blue: 0.25))
        .accessibilityLabel("Begin session")
        .accessibilityHint("Starts your exercise session.")
    }

    // MARK: - Empty State

    private var emptyPrescriptionCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.fill.questionmark")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text("Ask your clinician to set up your exercises.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                // Disabled equivalent of Begin — still tappable to show what's missing.
                navigationPath.append(AppRoute.clinicianPin)
            } label: {
                Text("Set Up Now")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(Color(red: 0.2, green: 0.45, blue: 0.2))
            .padding(.top, 4)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - My Trees

    private var myTreesButton: some View {
        Button {
            navigationPath.append(AppRoute.history(clinicianAccess: false))
        } label: {
            Label("My Trees", systemImage: "tree")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.bordered)
        .tint(Color(red: 0.2, green: 0.45, blue: 0.2))
        .accessibilityHint("See the trees you have grown from past sessions.")
    }

    // MARK: - Clinician Link

    private var clinicianLink: some View {
        Button {
            navigationPath.append(AppRoute.clinicianPin)
        } label: {
            Text("I'm a clinician")
                .font(.footnote)
                .foregroundStyle(Color(red: 0.2, green: 0.45, blue: 0.2).opacity(0.7))
                .underline()
        }
        .accessibilityLabel("Clinician access")
        .accessibilityHint("Opens the PIN screen to configure exercises.")
    }

    // MARK: - Actions

    private func loadPrescription() {
        // Always refresh on appear — the clinician may have just saved a new config.
        prescription = PrescriptionStore.shared.load()
        didLoad = true
    }

    private func beginSession() {
        guard let prescription else { return }
        let config = prescription.config

        if config.inputMode == .camera {
            navigationPath.append(AppRoute.calibration(config))
        } else {
            let cal = CalibrationData(minHeight: 0.0, maxHeight: 1.0)
            navigationPath.append(AppRoute.game(config, cal))
        }
    }
}

#Preview("With prescription") {
    NavigationStack {
        WelcomeView(navigationPath: .constant(NavigationPath()))
    }
}
