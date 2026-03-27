import SwiftUI

struct TreeView: View {
    let growth: Double
    let health: Double

    private var g: Double { min(max(growth, 0), 1) }
    private var hp: Double { min(max(health, 0), 1) }

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let baseY = h * 0.92
            let cx = w * 0.5

            if g < 0.05 {
                drawSoilMound(context: context, cx: cx, baseY: baseY, w: w)
            } else if g < 0.20 {
                drawSoilMound(context: context, cx: cx, baseY: baseY, w: w)
                drawSprout(context: context, cx: cx, baseY: baseY, w: w, h: h)
            } else {
                drawRoots(context: context, cx: cx, baseY: baseY, w: w)
                drawTrunk(context: context, cx: cx, baseY: baseY, w: w, h: h)
                drawCanopy(context: context, cx: cx, baseY: baseY, w: w, h: h)
                if g >= 0.92 {
                    drawFruits(context: context, cx: cx, baseY: baseY, w: w, h: h)
                }
            }
        }
    }

    // MARK: - Soil Mound

    private func drawSoilMound(context: GraphicsContext, cx: CGFloat, baseY: CGFloat, w: CGFloat) {
        let moundW: CGFloat = w * 0.35
        let moundH: CGFloat = 12.0 + 6.0 * CGFloat(min(g / 0.05, 1))

        var mound = Path()
        mound.move(to: CGPoint(x: cx - moundW / 2, y: baseY))
        mound.addQuadCurve(
            to: CGPoint(x: cx + moundW / 2, y: baseY),
            control: CGPoint(x: cx, y: baseY - moundH)
        )
        mound.closeSubpath()

        context.fill(mound, with: .linearGradient(
            Gradient(colors: [
                Color(red: 0.45, green: 0.32, blue: 0.18),
                Color(red: 0.35, green: 0.24, blue: 0.12)
            ]),
            startPoint: CGPoint(x: cx, y: baseY - moundH),
            endPoint: CGPoint(x: cx, y: baseY)
        ))
    }

    // MARK: - Sprout (0.05 - 0.20)

    private func drawSprout(context: GraphicsContext, cx: CGFloat, baseY: CGFloat, w: CGFloat, h: CGFloat) {
        let t = CGFloat((g - 0.05) / 0.15)
        let stemH: CGFloat = (30 + 60 * t)
        let stemW: CGFloat = 3 + t * 2

        // Curved stem
        var stem = Path()
        stem.move(to: CGPoint(x: cx, y: baseY))
        stem.addQuadCurve(
            to: CGPoint(x: cx + 4 * t, y: baseY - stemH),
            control: CGPoint(x: cx - 8 * t, y: baseY - stemH * 0.5)
        )
        context.stroke(stem, with: .color(Color(red: 0.35, green: 0.6, blue: 0.25)),
                       style: StrokeStyle(lineWidth: stemW, lineCap: .round))

        let tipX = cx + 4 * t
        let tipY = baseY - stemH

        // Main leaf (teardrop shape)
        if t > 0.15 {
            let leafScale = min(1, (t - 0.15) / 0.4)
            let leafW: CGFloat = 18 * leafScale
            let leafH: CGFloat = 24 * leafScale

            var leaf = Path()
            leaf.move(to: CGPoint(x: tipX, y: tipY))
            leaf.addQuadCurve(
                to: CGPoint(x: tipX, y: tipY - leafH),
                control: CGPoint(x: tipX - leafW, y: tipY - leafH * 0.4)
            )
            leaf.addQuadCurve(
                to: CGPoint(x: tipX, y: tipY),
                control: CGPoint(x: tipX + leafW, y: tipY - leafH * 0.4)
            )

            context.fill(leaf, with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.3, green: 0.72, blue: 0.28),
                    Color(red: 0.22, green: 0.58, blue: 0.2)
                ]),
                startPoint: CGPoint(x: tipX, y: tipY - leafH),
                endPoint: CGPoint(x: tipX, y: tipY)
            ))

            // Leaf vein
            var vein = Path()
            vein.move(to: CGPoint(x: tipX, y: tipY))
            vein.addLine(to: CGPoint(x: tipX, y: tipY - leafH * 0.8))
            context.stroke(vein, with: .color(Color(red: 0.25, green: 0.5, blue: 0.2).opacity(0.5)),
                          style: StrokeStyle(lineWidth: 1))
        }

        // Second smaller leaf on opposite side
        if t > 0.5 {
            let leaf2Scale = min(1, (t - 0.5) / 0.3)
            let l2W: CGFloat = 12 * leaf2Scale
            let l2H: CGFloat = 16 * leaf2Scale
            let l2Y = tipY + stemH * 0.2

            var leaf2 = Path()
            leaf2.move(to: CGPoint(x: cx - 2, y: l2Y))
            leaf2.addQuadCurve(
                to: CGPoint(x: cx - 2 - l2W * 1.2, y: l2Y - l2H * 0.3),
                control: CGPoint(x: cx - 2 - l2W * 0.3, y: l2Y - l2H)
            )
            leaf2.addQuadCurve(
                to: CGPoint(x: cx - 2, y: l2Y),
                control: CGPoint(x: cx - 2 - l2W * 0.8, y: l2Y + l2H * 0.2)
            )

            context.fill(leaf2, with: .color(Color(red: 0.28, green: 0.65, blue: 0.25).opacity(0.85)))
        }
    }

    // MARK: - Trunk (0.20+)

    private func drawTrunk(context: GraphicsContext, cx: CGFloat, baseY: CGFloat, w: CGFloat, h: CGFloat) {
        let t = CGFloat((g - 0.20) / 0.80)
        let trunkH: CGFloat = h * (0.18 + 0.38 * t)
        let baseW: CGFloat = w * (0.06 + 0.08 * t)
        let topW: CGFloat = baseW * (0.3 + 0.2 * t)

        let topY = baseY - trunkH

        // Main trunk shape - organic taper with slight curve
        var trunk = Path()
        trunk.move(to: CGPoint(x: cx - baseW / 2, y: baseY))
        trunk.addCurve(
            to: CGPoint(x: cx - topW / 2, y: topY),
            control1: CGPoint(x: cx - baseW / 2 - 2, y: baseY - trunkH * 0.4),
            control2: CGPoint(x: cx - topW / 2 + 3, y: topY + trunkH * 0.3)
        )
        trunk.addLine(to: CGPoint(x: cx + topW / 2, y: topY))
        trunk.addCurve(
            to: CGPoint(x: cx + baseW / 2, y: baseY),
            control1: CGPoint(x: cx + topW / 2 - 2, y: topY + trunkH * 0.3),
            control2: CGPoint(x: cx + baseW / 2 + 3, y: baseY - trunkH * 0.4)
        )
        trunk.closeSubpath()

        context.fill(trunk, with: .linearGradient(
            Gradient(colors: [
                Color(red: 0.50, green: 0.35, blue: 0.18),
                Color(red: 0.38, green: 0.25, blue: 0.12),
                Color(red: 0.32, green: 0.20, blue: 0.08)
            ]),
            startPoint: CGPoint(x: cx - baseW, y: baseY),
            endPoint: CGPoint(x: cx + baseW, y: baseY)
        ))

        // Bark texture lines
        if t > 0.2 {
            let barkOpacity = 0.15 * Double(min(1, (t - 0.2) / 0.3))
            for i in 0..<4 {
                let yFrac = 0.2 + Double(i) * 0.18
                let by = baseY - trunkH * CGFloat(yFrac)
                let bw = baseW * CGFloat(1.0 - yFrac * 0.6) * 0.3

                var bark = Path()
                bark.move(to: CGPoint(x: cx - bw, y: by))
                bark.addQuadCurve(
                    to: CGPoint(x: cx + bw * 0.5, y: by - 4),
                    control: CGPoint(x: cx, y: by - 6)
                )
                context.stroke(bark, with: .color(Color(red: 0.25, green: 0.15, blue: 0.05).opacity(barkOpacity)),
                              style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            }
        }

        // Branches visible as part of trunk at higher growth
        if t > 0.3 {
            drawBranches(context: context, cx: cx, topY: topY, trunkH: trunkH, baseW: baseW, t: t, baseY: baseY)
        }
    }

    // MARK: - Branches

    private func drawBranches(context: GraphicsContext, cx: CGFloat, topY: CGFloat, trunkH: CGFloat, baseW: CGFloat, t: CGFloat, baseY: CGFloat) {
        let branchT = min(1, (t - 0.3) / 0.5)

        struct BranchDef {
            let yFrac: CGFloat
            let side: CGFloat
            let length: CGFloat
            let angle: CGFloat
            let thickness: CGFloat
        }

        let branches: [BranchDef] = [
            BranchDef(yFrac: 0.30, side: -1, length: 0.22, angle: 35, thickness: 0.6),
            BranchDef(yFrac: 0.22, side: 1,  length: 0.28, angle: 30, thickness: 0.7),
            BranchDef(yFrac: 0.42, side: -1, length: 0.18, angle: 45, thickness: 0.45),
            BranchDef(yFrac: 0.38, side: 1,  length: 0.20, angle: 40, thickness: 0.5),
            BranchDef(yFrac: 0.55, side: -1, length: 0.12, angle: 50, thickness: 0.35),
            BranchDef(yFrac: 0.52, side: 1,  length: 0.14, angle: 48, thickness: 0.4),
        ]

        for (i, b) in branches.enumerated() {
            let appear = min(1, max(0, (branchT - CGFloat(i) * 0.08) / 0.25))
            guard appear > 0 else { continue }

            let by = baseY - trunkH * b.yFrac
            let rad = b.angle * .pi / 180
            let len = trunkH * b.length * appear * branchT
            let endX = cx + b.side * len * cos(rad)
            let endY = by - len * sin(rad)

            var branch = Path()
            branch.move(to: CGPoint(x: cx, y: by))
            branch.addQuadCurve(
                to: CGPoint(x: endX, y: endY),
                control: CGPoint(x: cx + b.side * len * 0.4, y: by - len * 0.15)
            )

            let lw = baseW * b.thickness * appear
            context.stroke(branch, with: .color(Color(red: 0.42, green: 0.28, blue: 0.14)),
                          style: StrokeStyle(lineWidth: lw, lineCap: .round))
        }
    }

    // MARK: - Canopy (cloud-style foliage clusters)

    private func drawCanopy(context: GraphicsContext, cx: CGFloat, baseY: CGFloat, w: CGFloat, h: CGFloat) {
        let t = CGFloat((g - 0.20) / 0.80)
        let trunkH = h * (0.18 + 0.38 * t)
        let topY = baseY - trunkH

        let canopyScale = min(1.0, t / 0.6)
        guard canopyScale > 0 else { return }

        let maxR = w * 0.38 * canopyScale
        let healthSat = CGFloat(hp)

        // Leaf cluster color with health affecting saturation
        let darkGreen = Color(
            red: 0.15 + 0.2 * Double(1 - healthSat),
            green: 0.42 + 0.2 * Double(healthSat),
            blue: 0.12
        )
        let midGreen = Color(
            red: 0.2 + 0.18 * Double(1 - healthSat),
            green: 0.55 + 0.15 * Double(healthSat),
            blue: 0.15
        )
        let lightGreen = Color(
            red: 0.28 + 0.15 * Double(1 - healthSat),
            green: 0.65 + 0.1 * Double(healthSat),
            blue: 0.2
        )

        struct Blob {
            let dx: CGFloat
            let dy: CGFloat
            let r: CGFloat
            let layer: Int // 0=back, 1=mid, 2=front
        }

        let blobs: [Blob] = [
            // Back layer (darkest, largest)
            Blob(dx: -0.25, dy:  0.08, r: 0.70, layer: 0),
            Blob(dx:  0.28, dy:  0.10, r: 0.65, layer: 0),
            Blob(dx:  0.00, dy:  0.15, r: 0.75, layer: 0),
            // Mid layer
            Blob(dx: -0.35, dy: -0.05, r: 0.55, layer: 1),
            Blob(dx:  0.35, dy: -0.02, r: 0.50, layer: 1),
            Blob(dx:  0.05, dy: -0.10, r: 0.65, layer: 1),
            Blob(dx: -0.12, dy:  0.00, r: 0.72, layer: 1),
            Blob(dx:  0.18, dy:  0.02, r: 0.60, layer: 1),
            // Front layer (lightest, highlights)
            Blob(dx: -0.18, dy: -0.15, r: 0.48, layer: 2),
            Blob(dx:  0.20, dy: -0.12, r: 0.45, layer: 2),
            Blob(dx:  0.00, dy: -0.22, r: 0.50, layer: 2),
            Blob(dx: -0.30, dy:  0.00, r: 0.38, layer: 2),
            Blob(dx:  0.30, dy:  0.05, r: 0.40, layer: 2),
        ]

        let canopyCenterY = topY - maxR * 0.15

        for layer in 0...2 {
            let layerBlobs = blobs.filter { $0.layer == layer }
            let color: Color
            switch layer {
            case 0: color = darkGreen
            case 1: color = midGreen
            default: color = lightGreen
            }

            for blob in layerBlobs {
                let blobAppear = min(1, canopyScale * 1.5 - CGFloat(layer) * 0.15)
                guard blobAppear > 0 else { continue }

                let bx = cx + blob.dx * maxR
                let by = canopyCenterY + blob.dy * maxR
                let br = blob.r * maxR * blobAppear

                let rect = CGRect(x: bx - br, y: by - br, width: br * 2, height: br * 2)
                context.fill(Circle().path(in: rect), with: .color(color.opacity(Double(0.7 + 0.3 * blobAppear))))
            }
        }

        // Highlight spots (subtle lighter circles for depth)
        if canopyScale > 0.5 {
            let hlAlpha = Double(min(1, (canopyScale - 0.5) / 0.5)) * 0.3
            let highlights: [(CGFloat, CGFloat, CGFloat)] = [
                (-0.10, -0.18, 0.25),
                ( 0.12, -0.08, 0.20),
                (-0.25, -0.05, 0.18),
            ]
            for hl in highlights {
                let hx = cx + hl.0 * maxR
                let hy = canopyCenterY + hl.1 * maxR
                let hr = hl.2 * maxR
                let rect = CGRect(x: hx - hr, y: hy - hr, width: hr * 2, height: hr * 2)
                context.fill(Circle().path(in: rect), with: .color(Color.white.opacity(hlAlpha)))
            }
        }
    }

    // MARK: - Roots

    private func drawRoots(context: GraphicsContext, cx: CGFloat, baseY: CGFloat, w: CGFloat) {
        let t = CGFloat(min(1, (g - 0.20) / 0.40))
        guard t > 0 else { return }

        let roots: [(side: CGFloat, spread: CGFloat, depth: CGFloat, thickness: CGFloat)] = [
            (-1, 0.10, 0.06, 2.5),
            ( 1, 0.12, 0.07, 2.5),
            (-1, 0.06, 0.04, 1.5),
            ( 1, 0.07, 0.05, 1.5),
        ]

        for r in roots {
            let spread = w * r.spread * t
            let depth = w * r.depth * t

            var root = Path()
            root.move(to: CGPoint(x: cx, y: baseY + 2))
            root.addQuadCurve(
                to: CGPoint(x: cx + r.side * spread, y: baseY + depth),
                control: CGPoint(x: cx + r.side * spread * 0.4, y: baseY + depth * 0.7)
            )
            context.stroke(root, with: .color(Color(red: 0.4, green: 0.28, blue: 0.14).opacity(0.5 * Double(t))),
                          style: StrokeStyle(lineWidth: r.thickness * t, lineCap: .round))
        }
    }

    // MARK: - Fruits & Flowers

    private func drawFruits(context: GraphicsContext, cx: CGFloat, baseY: CGFloat, w: CGFloat, h: CGFloat) {
        let t = CGFloat((g - 0.20) / 0.80)
        let trunkH = h * (0.18 + 0.38 * t)
        let topY = baseY - trunkH
        let maxR = w * 0.38
        let canopyCenterY = topY - maxR * 0.15

        let fruitAppear = CGFloat(min(1, (g - 0.92) / 0.08))

        let fruits: [(dx: CGFloat, dy: CGFloat, size: CGFloat, color: Color)] = [
            (-0.22, -0.08, 8, Color(red: 0.9, green: 0.25, blue: 0.2)),
            ( 0.25, -0.05, 7, Color(red: 0.9, green: 0.25, blue: 0.2)),
            ( 0.05, -0.20, 7, Color(red: 0.95, green: 0.3, blue: 0.25)),
            (-0.15,  0.05, 6, Color(red: 0.9, green: 0.25, blue: 0.2)),
            ( 0.18,  0.08, 6, Color(red: 0.95, green: 0.3, blue: 0.25)),
            (-0.30,  0.00, 5, .pink),
            ( 0.32, -0.12, 5, .pink),
            ( 0.00,  0.10, 5, .pink),
        ]

        // Small white flowers
        let flowers: [(dx: CGFloat, dy: CGFloat)] = [
            (-0.12, -0.25), (0.15, -0.18), (-0.28, -0.12),
            (0.08,  0.12), (-0.20, 0.08), (0.28, 0.02),
        ]

        for f in flowers {
            let fx = cx + f.dx * maxR
            let fy = canopyCenterY + f.dy * maxR
            let fs: CGFloat = 5 * fruitAppear

            // Flower petals (5 small circles in a ring)
            for p in 0..<5 {
                let angle = CGFloat(p) * .pi * 2 / 5
                let px = fx + cos(angle) * fs * 0.5
                let py = fy + sin(angle) * fs * 0.5
                let rect = CGRect(x: px - fs * 0.4, y: py - fs * 0.4, width: fs * 0.8, height: fs * 0.8)
                context.fill(Circle().path(in: rect), with: .color(Color.white.opacity(0.85 * Double(fruitAppear))))
            }
            // Flower center
            let cRect = CGRect(x: fx - 2, y: fy - 2, width: 4, height: 4)
            context.fill(Circle().path(in: cRect), with: .color(Color.yellow.opacity(0.9 * Double(fruitAppear))))
        }

        for fruit in fruits {
            let fx = cx + fruit.dx * maxR
            let fy = canopyCenterY + fruit.dy * maxR
            let fs = fruit.size * fruitAppear

            let rect = CGRect(x: fx - fs / 2, y: fy - fs / 2, width: fs, height: fs)
            context.fill(Circle().path(in: rect), with: .color(fruit.color.opacity(Double(fruitAppear))))

            // Tiny highlight on each fruit
            let hlRect = CGRect(x: fx - fs * 0.15, y: fy - fs * 0.3, width: fs * 0.3, height: fs * 0.3)
            context.fill(Circle().path(in: hlRect), with: .color(Color.white.opacity(0.4 * Double(fruitAppear))))
        }
    }
}

// MARK: - Previews

#Preview("Seed") {
    ZStack {
        Color(red: 0.5, green: 0.75, blue: 1).ignoresSafeArea()
        VStack { Spacer(); Color(red: 0.3, green: 0.55, blue: 0.2).frame(height: 120) }
        TreeView(growth: 0.03, health: 1.0)
            .frame(width: 300, height: 500)
    }
}

#Preview("Sprout") {
    ZStack {
        Color(red: 0.5, green: 0.75, blue: 1).ignoresSafeArea()
        VStack { Spacer(); Color(red: 0.3, green: 0.55, blue: 0.2).frame(height: 120) }
        TreeView(growth: 0.15, health: 1.0)
            .frame(width: 300, height: 500)
    }
}

#Preview("Young") {
    ZStack {
        Color(red: 0.5, green: 0.75, blue: 1).ignoresSafeArea()
        VStack { Spacer(); Color(red: 0.3, green: 0.55, blue: 0.2).frame(height: 120) }
        TreeView(growth: 0.4, health: 1.0)
            .frame(width: 300, height: 500)
    }
}

#Preview("Half Grown") {
    ZStack {
        Color(red: 0.5, green: 0.75, blue: 1).ignoresSafeArea()
        VStack { Spacer(); Color(red: 0.3, green: 0.55, blue: 0.2).frame(height: 120) }
        TreeView(growth: 0.65, health: 1.0)
            .frame(width: 300, height: 500)
    }
}

#Preview("Full Tree") {
    ZStack {
        Color(red: 0.5, green: 0.75, blue: 1).ignoresSafeArea()
        VStack { Spacer(); Color(red: 0.3, green: 0.55, blue: 0.2).frame(height: 120) }
        TreeView(growth: 1.0, health: 1.0)
            .frame(width: 300, height: 500)
    }
}

#Preview("Wilted") {
    ZStack {
        Color(red: 0.5, green: 0.75, blue: 1).ignoresSafeArea()
        VStack { Spacer(); Color(red: 0.3, green: 0.55, blue: 0.2).frame(height: 120) }
        TreeView(growth: 0.8, health: 0.2)
            .frame(width: 300, height: 500)
    }
}
