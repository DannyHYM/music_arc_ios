import SwiftUI

struct TreeGrowthView: View {
    let phase: GamePhase
    let handHeight: Double
    let treeGrowth: Double
    let treeHealth: Double
    let isRestingProperly: Bool
    let sunlightThreshold: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                SkyView(phase: phase, handHeight: handHeight, isRestingProperly: isRestingProperly)

                GroundView(phase: phase)

                TreeView(growth: treeGrowth, health: treeHealth)
                    .frame(width: w * 0.85, height: h * 0.85)
                    .position(x: w * 0.5, y: h * 0.52)
                    .animation(.easeInOut(duration: 0.4), value: treeGrowth)

                ParticleOverlay(
                    phase: phase,
                    handHeight: handHeight,
                    isRestingProperly: isRestingProperly,
                    sunlightThreshold: sunlightThreshold,
                    treeGrowth: treeGrowth,
                    size: geo.size
                )

                HandGuideView(
                    phase: phase,
                    handHeight: handHeight,
                    sunlightThreshold: sunlightThreshold,
                    restThreshold: 0.3
                )
                .frame(width: 44, height: h * 0.7)
                .position(x: w - 30, y: h * 0.45)
            }
        }
        .clipped()
    }
}

// MARK: - Particle Overlay

struct ParticleOverlay: View {
    let phase: GamePhase
    let handHeight: Double
    let isRestingProperly: Bool
    let sunlightThreshold: Double
    let treeGrowth: Double
    let size: CGSize

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
            Canvas { context, canvasSize in
                let time = timeline.date.timeIntervalSinceReferenceDate

                if phase == .active && handHeight >= sunlightThreshold {
                    if handHeight >= 0.85 {
                        drawSparkles(context: context, size: canvasSize, time: time)
                    }
                }

                if phase == .rest {
                    if isRestingProperly {
                        drawRain(context: context, size: canvasSize, time: time)
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
        let intensity = (handHeight - 0.85) / 0.15

        for i in 0..<Int(8 * intensity + 4) {
            let seed = Double(i) * 97.3
            let angle = fract(time * 0.4 + seed * 0.13) * .pi * 2
            let radius: CGFloat = 30 + CGFloat(fract(seed * 0.2)) * size.width * 0.2
            let x = centerX + radius * CGFloat(cos(angle))
            let y = treeTop + radius * 0.5 * CGFloat(sin(angle))
            let sparkleSize: CGFloat = 2.5 + 2 * CGFloat(fract(seed * 0.3))
            let opacity = 0.4 + 0.4 * (0.5 + 0.5 * sin(time * 4 + seed))

            let rect = CGRect(x: x - sparkleSize / 2, y: y - sparkleSize / 2, width: sparkleSize, height: sparkleSize)

            // 4-point star shape
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
        for i in 0..<35 {
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

    private func drawFallingLeaves(context: GraphicsContext, size: CGSize, time: TimeInterval) {
        for i in 0..<10 {
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

// MARK: - Hand Guide

struct HandGuideView: View {
    let phase: GamePhase
    let handHeight: Double
    let sunlightThreshold: Double
    let restThreshold: Double

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width

            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 6)

                let indicatorY = h * (1.0 - handHeight)
                let icon = phase == .active ? "sun.max.fill" : "drop.fill"
                let color: Color = phase == .active ? .yellow : .cyan

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(color)
                    .shadow(color: color.opacity(0.5), radius: 4)
                    .position(x: w / 2, y: indicatorY)
                    .animation(.easeOut(duration: 0.1), value: handHeight)

                if phase == .active {
                    let targetY = h * (1.0 - sunlightThreshold)
                    TargetLine(label: "Raise here", color: .yellow.opacity(0.7))
                        .position(x: w / 2, y: targetY)
                } else if phase == .rest {
                    let targetY = h * (1.0 - restThreshold)
                    TargetLine(label: "Rest here", color: .cyan.opacity(0.7))
                        .position(x: w / 2, y: targetY)
                }
            }
        }
    }
}

private struct TargetLine: View {
    let label: String
    let color: Color

    @State private var pulse = false

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(color)
            RoundedRectangle(cornerRadius: 1)
                .fill(color)
                .frame(width: 30, height: 2)
                .scaleEffect(x: pulse ? 1.15 : 0.85)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulse)
        }
        .onAppear { pulse = true }
    }
}
