import SwiftUI

struct AmbientBlobBackground: View {
    @State private var phase1 = false
    @State private var phase2 = false

    private let bgColor = Color(red: 0.898, green: 0.965, blue: 0.894) // #E5F6E4

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            lowerBlob
            upperBlob
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                .easeInOut(duration: 8)
                .repeatForever(autoreverses: true)
            ) {
                phase1 = true
            }
            withAnimation(
                .easeInOut(duration: 10)
                .repeatForever(autoreverses: true)
            ) {
                phase2 = true
            }
        }
    }

    // MARK: - Lower Blob (#B1E6FF → #D0ECC5)

    private var lowerBlob: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.694, green: 0.902, blue: 1.0),   // #B1E6FF
                            Color(red: 0.816, green: 0.925, blue: 0.773)  // #D0ECC5
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: w * 0.85, height: h * 0.45)
                .rotationEffect(.degrees(phase1 ? 15 : -10))
                .scaleEffect(phase1 ? 1.05 : 0.95)
                .offset(
                    x: phase1 ? w * 0.15 : -w * 0.2,
                    y: phase1 ? h * 0.3 : -h * 0.2
                )
                .blur(radius: 40)
                .opacity(0.7)
        }
    }

    // MARK: - Upper Blob (#FFCB62 → #8F9EFF)

    private var upperBlob: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.796, blue: 0.384),   // #FFCB62
                            Color(red: 0.561, green: 0.620, blue: 1.0)    // #8F9EFF
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                )
                .frame(width: w * 0.75, height: h * 0.4)
                .rotationEffect(.degrees(phase2 ? -12 : 8))
                .scaleEffect(phase2 ? 0.95 : 1.08)
                .offset(
                    x: phase2 ? -w * 0.1 : w * 0.2,
                    y: phase2 ? -h * 0.25 : h * 0.25
                )
                .blur(radius: 35)
                .opacity(0.7)
        }
    }
}

#Preview {
    AmbientBlobBackground()
}
