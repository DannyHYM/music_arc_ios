import SwiftUI

struct ClinicianPinView: View {
    @Binding var navigationPath: NavigationPath

    @State private var enteredDigits: String = ""
    @State private var shakeTrigger: Int = 0
    @State private var errorMessage: String?
    @State private var isUnlocked = false
    @FocusState private var fieldFocused: Bool

    private let pinLength = 4

    var body: some View {
        ZStack {
            AmbientBlobBackground()

            VStack(spacing: 28) {
                Spacer()

                Image(systemName: "lock.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.forestMid)

                Text("Clinician Access")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.forestDark)

                Text("Enter the 4-digit PIN to configure exercises.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                pinDots
                    .modifier(ShakeEffect(amount: 8, shakesPerUnit: 3, animatableData: CGFloat(shakeTrigger)))

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                hiddenInputField

                Spacer()
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fieldFocused = true
        }
    }

    private var pinDots: some View {
        HStack(spacing: 18) {
            ForEach(0..<pinLength, id: \.self) { i in
                Circle()
                    .stroke(Color.forestMid, lineWidth: 2)
                    .background(
                        Circle()
                            .fill(i < enteredDigits.count
                                  ? Color.forestPrimary
                                  : Color.clear)
                    )
                    .frame(width: 22, height: 22)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            fieldFocused = true
        }
    }

    private var hiddenInputField: some View {
        TextField("", text: Binding(
            get: { enteredDigits },
            set: { newValue in handleInput(newValue) }
        ))
        .keyboardType(.numberPad)
        .textContentType(.oneTimeCode)
        .focused($fieldFocused)
        .frame(width: 1, height: 1)
        .opacity(0.01)
        .accessibilityLabel("Clinician PIN")
    }

    private func handleInput(_ raw: String) {
        // The TextField's binding setter is not only called per keystroke — UIKit also
        // re-invokes it with the unchanged text on end-editing (keyboard dismissing as the
        // next screen is pushed). Without this guard that extra call re-validates "1234"
        // and navigates a second time, which is what produced the double mount.
        guard !isUnlocked else { return }

        let digits = raw.filter(\.isNumber)
        enteredDigits = String(digits.prefix(pinLength))
        errorMessage = nil

        if enteredDigits.count == pinLength {
            if ClinicianAuth.validate(enteredDigits) {
                isUnlocked = true
                enteredDigits = ""
                // Replace this screen with the config screen so Back from Clinician Setup
                // returns to Welcome rather than to an already-passed PIN gate.
                if !navigationPath.isEmpty {
                    navigationPath.removeLast()
                }
                navigationPath.append(AppRoute.clinicianConfig)
            } else {
                withAnimation(.default) {
                    shakeTrigger += 1
                }
                errorMessage = "Incorrect PIN"
                enteredDigits = ""
            }
        }
    }
}

private struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * shakesPerUnit), y: 0))
    }
}

#Preview {
    NavigationStack {
        ClinicianPinView(navigationPath: .constant(NavigationPath()))
    }
}
