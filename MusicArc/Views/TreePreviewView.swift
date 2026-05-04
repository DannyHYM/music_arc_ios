import SwiftUI

struct TreePreviewView: View {
    let species: TreeSpecies
    @Binding var navigationPath: NavigationPath

    @State private var growth: Double = 0.0
    @State private var isPressing = false
    @GestureState private var isHolding = false

    private let growthRate: Double = 0.3

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.5, green: 0.75, blue: 1.0),
                    Color(red: 0.7, green: 0.88, blue: 1.0),
                    Color(red: 0.85, green: 0.92, blue: 0.75)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.35, green: 0.6, blue: 0.25),
                                Color(red: 0.25, green: 0.45, blue: 0.18)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 140)
            }
            .ignoresSafeArea(edges: .bottom)

            TreeView(growth: growth, health: 1.0, species: species)
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
                .animation(.easeInOut(duration: 0.15), value: growth)

            VStack {
                Spacer()

                Text("\(Int(growth * 100))%")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.3), in: Capsule())

                Text(isPressing ? "Growing..." : "Press & hold to grow")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.bottom, 40)
            }

            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isPressing {
                                isPressing = true
                            }
                        }
                        .onEnded { _ in
                            isPressing = false
                        }
                )
        }
        .navigationTitle(species.displayName + " Tree")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset") {
                    growth = 0
                }
                .foregroundStyle(.white)
            }
        }
        .onAppear {
            growth = 0
        }
        .onReceive(
            Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()
        ) { _ in
            guard isPressing, growth < 1.0 else { return }
            growth = min(1.0, growth + growthRate / 30.0)
        }
    }
}

#Preview {
    NavigationStack {
        TreePreviewView(
            species: .round,
            navigationPath: .constant(NavigationPath())
        )
    }
}
