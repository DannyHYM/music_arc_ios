import SwiftUI

struct TreeGrowthView: View {
    let phase: GamePhase
    let handHeight: Double
    let treeGrowth: Double
    let treeHealth: Double
    let isRestingProperly: Bool
    let sunlightThreshold: Double
    let restThreshold: Double
    let waterLevel: Double
    let isInSunlightZone: Bool
    let growthSpurtCount: Int

    @State private var treeScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                SkyView(
                    phase: phase,
                    handHeight: handHeight,
                    isRestingProperly: isRestingProperly,
                    isInSunlightZone: isInSunlightZone,
                    sunlightThreshold: sunlightThreshold
                )

                GroundView(phase: phase)

                TreeView(growth: treeGrowth, health: treeHealth)
                    .frame(width: w * 0.85, height: h * 0.85)
                    .position(x: w * 0.5, y: h * 0.52)
                    .scaleEffect(treeScale)
                    .animation(.easeInOut(duration: 0.4), value: treeGrowth)

                if phase == .rest {
                    WaterLevelView(waterLevel: waterLevel)
                        .frame(width: w * 0.35, height: 14)
                        .position(x: w * 0.5, y: h * 0.91)
                        .transition(.opacity)
                }

                ParticleOverlay(
                    phase: phase,
                    handHeight: handHeight,
                    isRestingProperly: isRestingProperly,
                    sunlightThreshold: sunlightThreshold,
                    isInSunlightZone: isInSunlightZone,
                    waterLevel: waterLevel,
                    treeGrowth: treeGrowth,
                    size: geo.size
                )
            }
        }
        .clipped()
        .onChange(of: growthSpurtCount) {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) {
                treeScale = 1.04
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.15)) {
                treeScale = 1.0
            }
        }
    }
}

// MARK: - Water Level

struct WaterLevelView: View {
    let waterLevel: Double

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "drop.fill")
                .font(.system(size: 8))
                .foregroundStyle(.cyan.opacity(0.8))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.cyan.opacity(0.5), .blue.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * waterLevel)
                        .animation(.easeInOut(duration: 0.3), value: waterLevel)
                }
            }
        }
    }
}

// MARK: - Particle Overlay

struct ParticleOverlay: View {
    let phase: GamePhase
    let handHeight: Double
    let isRestingProperly: Bool
    let sunlightThreshold: Double
    let isInSunlightZone: Bool
    let waterLevel: Double
    let treeGrowth: Double
    let size: CGSize

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                if phase == .active && isInSunlightZone {
                    drawSparkles(context: context, size: canvasSize, time: time)
                }

                if phase == .rest {
                    if isRestingProperly {
                        drawRain(context: context, size: canvasSize, time: time)
                        if waterLevel > 0.1 {
                            drawRootGlow(context: context, size: canvasSize)
                        }
                    } else {
                        drawFallingLeaves(context: context, size: canvasSize, time: time)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func drawSparkles(context: GraphicsContext, size: CGSize, time: TimeInterval) {
        let centerX = size.width * 0.5
        let treeTop = size.height * (0.25 - 0.15 * treeGrowth)
        let intensity = min(1.0, (handHeight - sunlightThreshold) / (1.0 - sunlightThreshold))
        let sparkleCount = Int(4 + 8 * intensity)

        for i in 0..<sparkleCount {
            let seed = Double(i) * 97.3
            let angle = fract(time * 0.4 + seed * 0.13) * .pi * 2
            let radius: CGFloat = 30 + CGFloat(fract(seed * 0.2)) * size.width * 0.2
            let x = centerX + radius * CGFloat(cos(angle))
            let y = treeTop + radius * 0.5 * CGFloat(sin(angle))
            let sparkleSize: CGFloat = 2.5 + 2 * CGFloat(fract(seed * 0.3))
            let opacity = 0.4 + 0.4 * (0.5 + 0.5 * sin(time * 4 + seed))

            var star = Path()
            star.move(to: CGPoint(x: x, y: y - sparkleSize))
            star.addLine(to: CGPoint(x: x + sparkleSize * 0.25, y: y - sparkleSize * 0.25))
            star.addLine(to: CGPoint(x: x + sparkleSize, y: y))
            star.addLine(to: CGPoint(x: x + sparkleSize * 0.25, y: y + sparkleSize * 0.25))
            star.addLine(to: CGPoint(x: x, y: y + sparkleSize))
            star.addLine(to: CGPoint(x: x - sparkleSize * 0.25, y: y + sparkleSize * 0.25))
            star.addLine(to: CGPoint(x: x - sparkleSize, y: y))
            star.addLine(to: CGPoint(x: x - sparkleSize * 0.25, y: y - sparkleSize * 0.25))
            star.closeSubpath()

            context.fill(star, with: .color(Color.yellow.opacity(opacity * intensity)))
        }
    }

    private func drawRain(context: GraphicsContext, size: CGSize, time: TimeInterval) {
        let dropCount = max(10, Int(10 + 25 * waterLevel))
        for i in 0..<dropCount {
            let seed = Double(i) * 47.9
            let x = size.width * CGFloat(fract(seed * 0.1 + time * 0.015))
            let speed = 0.3 + 0.25 * fract(seed * 0.2)
            let y = size.height * CGFloat(fract(time * speed + seed * 0.05))
            let dropLength: CGFloat = 10 + 8 * CGFloat(fract(seed * 0.3))

            var path = Path()
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x - 1.5, y: y + dropLength))

            context.stroke(path, with: .color(Color(red: 0.55, green: 0.75, blue: 1.0).opacity(0.35)),
                          lineWidth: 1.5)
        }
    }

    private func drawRootGlow(context: GraphicsContext, size: CGSize) {
        let cx = size.width * 0.5
        let baseY = size.height * 0.87
        let radius = size.width * 0.15 * waterLevel
        let glowRect = CGRect(
            x: cx - radius, y: baseY - radius * 0.4,
            width: radius * 2, height: radius * 0.8
        )
        context.fill(
            Ellipse().path(in: glowRect),
            with: .color(Color(red: 0.3, green: 0.6, blue: 0.9).opacity(0.2 * waterLevel))
        )
    }

    private func drawFallingLeaves(context: GraphicsContext, size: CGSize, time: TimeInterval) {
        for i in 0..<12 {
            let seed = Double(i) * 67.3
            let speed = 0.12 + 0.08 * fract(seed * 0.2)
            let x = size.width * CGFloat(fract(seed * 0.15 + sin(time * 0.5 + seed) * 0.06))
            let y = size.height * CGFloat(fract(time * speed + seed * 0.1))
            let rotation = time * 2 + seed

            let leafW: CGFloat = 6 + 4 * CGFloat(fract(seed * 0.3))
            let leafH: CGFloat = leafW * 0.5

            let colors: [Color] = [
                Color(red: 0.75, green: 0.5, blue: 0.15),
                Color(red: 0.85, green: 0.45, blue: 0.1),
                Color(red: 0.65, green: 0.4, blue: 0.12)
            ]

            var leaf = Path()
            leaf.move(to: CGPoint(x: x - leafW / 2, y: y))
            leaf.addQuadCurve(
                to: CGPoint(x: x + leafW / 2, y: y),
                control: CGPoint(x: x, y: y - leafH)
            )
            leaf.addQuadCurve(
                to: CGPoint(x: x - leafW / 2, y: y),
                control: CGPoint(x: x, y: y + leafH * 0.5)
            )

            var transform = CGAffineTransform.identity
            transform = transform.translatedBy(x: x, y: y)
            transform = transform.rotated(by: CGFloat(rotation))
            transform = transform.translatedBy(x: -x, y: -y)

            context.fill(leaf.applying(transform), with: .color(colors[i % colors.count].opacity(0.65)))
        }
    }

    private func fract(_ value: Double) -> CGFloat {
        CGFloat(value - floor(value))
    }
}
