import SwiftUI

struct SkyView: View {
    let phase: GamePhase
    let handHeight: Double
    let isRestingProperly: Bool

    private var isDay: Bool { phase == .active || phase == .countdown }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                skyGradient
                    .ignoresSafeArea()

                if isDay {
                    sunView(in: geo)
                } else if phase == .rest {
                    nightElements(in: geo)
                }
            }
            .animation(.easeInOut(duration: 1.0), value: isDay)
            .animation(.easeInOut(duration: 0.5), value: isRestingProperly)
        }
    }

    // MARK: - Sky Gradient

    private var skyGradient: some View {
        Group {
            if phase == .rest && !isRestingProperly {
                LinearGradient(
                    colors: [
                        Color(red: 0.35, green: 0.15, blue: 0.1),
                        Color(red: 0.5, green: 0.2, blue: 0.1),
                        Color(red: 0.3, green: 0.15, blue: 0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else if isDay {
                LinearGradient(
                    colors: [
                        Color(red: 0.4, green: 0.7, blue: 1.0),
                        Color(red: 0.6, green: 0.85, blue: 1.0),
                        Color(red: 1.0, green: 0.85, blue: 0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.2),
                        Color(red: 0.1, green: 0.08, blue: 0.3),
                        Color(red: 0.15, green: 0.1, blue: 0.25)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    // MARK: - Sun

    private func sunView(in geo: GeometryProxy) -> some View {
        let sunMinY = geo.size.height * 0.7
        let sunMaxY = geo.size.height * 0.12
        let sunY = sunMinY - (sunMinY - sunMaxY) * handHeight
        let sunX = geo.size.width * 0.8
        let intensity = max(0, (handHeight - 0.3) / 0.7)

        return ZStack {
            Circle()
                .fill(Color.yellow.opacity(0.15 * intensity))
                .frame(width: 120, height: 120)

            Circle()
                .fill(Color.yellow.opacity(0.3 * intensity))
                .frame(width: 80, height: 80)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, .yellow, .orange.opacity(0.8)],
                        center: .center,
                        startRadius: 5,
                        endRadius: 25
                    )
                )
                .frame(width: 50, height: 50)

            ForEach(0..<8, id: \.self) { i in
                let angle = Double(i) * 45.0
                let rayLength: CGFloat = 15 + 10 * intensity
                RayShape(length: rayLength)
                    .stroke(Color.yellow.opacity(0.4 * intensity), lineWidth: 2)
                    .frame(width: rayLength * 2, height: rayLength * 2)
                    .rotationEffect(.degrees(angle))
            }
        }
        .position(x: sunX, y: sunY)
        .animation(.easeOut(duration: 0.15), value: handHeight)
    }

    // MARK: - Night Elements

    private func nightElements(in geo: GeometryProxy) -> some View {
        let w = geo.size.width
        let h = geo.size.height

        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.9), Color(red: 0.8, green: 0.8, blue: 0.6).opacity(0.6)],
                        center: UnitPoint(x: 0.4, y: 0.4),
                        startRadius: 2,
                        endRadius: 20
                    )
                )
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .fill(Color(red: 0.05, green: 0.05, blue: 0.2))
                        .frame(width: 30, height: 30)
                        .offset(x: 8, y: -5)
                )
                .position(x: w * 0.8, y: h * 0.12)
                .opacity(isRestingProperly ? 1.0 : 0.3)

            ForEach(0..<20, id: \.self) { i in
                let starX = CGFloat.random(in: 0...1)
                let starY = CGFloat.random(in: 0...0.5)
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.3...0.8)))
                    .frame(width: CGFloat.random(in: 1.5...3.5), height: CGFloat.random(in: 1.5...3.5))
                    .position(x: w * starX, y: h * starY)
            }
        }
    }
}

// MARK: - Ray Shape

private struct RayShape: Shape {
    let length: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.move(to: CGPoint(x: center.x, y: center.y - 28))
        path.addLine(to: CGPoint(x: center.x, y: center.y - 28 - length))
        return path
    }
}

struct GroundView: View {
    let phase: GamePhase

    private var isDay: Bool { phase == .active || phase == .countdown }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Spacer()

                ZStack(alignment: .top) {
                    Rectangle()
                        .fill(grassGradient)
                        .frame(height: geo.size.height * 0.15)

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [grassTopColor.opacity(0.6), grassTopColor.opacity(0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 8)
                }
            }
            .animation(.easeInOut(duration: 1.0), value: isDay)
        }
    }

    private var grassGradient: LinearGradient {
        if isDay {
            return LinearGradient(
                colors: [
                    Color(red: 0.3, green: 0.55, blue: 0.2),
                    Color(red: 0.25, green: 0.4, blue: 0.15),
                    Color(red: 0.2, green: 0.3, blue: 0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.22, blue: 0.08),
                    Color(red: 0.08, green: 0.15, blue: 0.05),
                    Color(red: 0.05, green: 0.1, blue: 0.03)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var grassTopColor: Color {
        isDay ? Color(red: 0.4, green: 0.65, blue: 0.25) : Color(red: 0.15, green: 0.25, blue: 0.1)
    }
}
