import SwiftUI

struct AcaciaTreeRenderer: TreeRenderer {
    private let trunkColor = Color(red: 0.55, green: 0.40, blue: 0.26)
    private let trunkShadow = Color(red: 0.48, green: 0.34, blue: 0.22)
    private let sproutGreen = Color(red: 0.30, green: 0.62, blue: 0.25)

    func draw(in context: GraphicsContext, size: CGSize, growth: Double, health: Double) {
        let g = min(max(growth, 0), 1)
        let hp = min(max(health, 0), 1)
        let w = size.width
        let h = size.height
        let baseY = h * 0.95
        let cx = w * 0.5

        if g < 0.05 {
            drawSoilMound(context: context, cx: cx, baseY: baseY, w: w, g: g)
        } else if g < 0.25 {
            drawSoilMound(context: context, cx: cx, baseY: baseY, w: w, g: g)
            drawSprout(context: context, cx: cx, baseY: baseY, w: w, h: h, g: g)
        } else {
            drawTree(context: context, cx: cx, baseY: baseY, w: w, h: h, g: g, hp: hp)
        }
    }

    // MARK: - Soil Mound

    private func drawSoilMound(context: GraphicsContext, cx: CGFloat, baseY: CGFloat, w: CGFloat, g: Double) {
        let moundW: CGFloat = w * 0.30
        let moundH: CGFloat = 10.0 + 5.0 * CGFloat(min(g / 0.05, 1))

        var mound = Path()
        mound.move(to: CGPoint(x: cx - moundW / 2, y: baseY))
        mound.addQuadCurve(
            to: CGPoint(x: cx + moundW / 2, y: baseY),
            control: CGPoint(x: cx, y: baseY - moundH)
        )
        mound.closeSubpath()
        context.fill(mound, with: .color(Color(red: 0.42, green: 0.30, blue: 0.16)))
    }

    // MARK: - Sprout (0.05 - 0.25)

    private func drawSprout(context: GraphicsContext, cx: CGFloat, baseY: CGFloat, w: CGFloat, h: CGFloat, g: Double) {
        let t = CGFloat((g - 0.05) / 0.20)
        let stemH: CGFloat = 25 + 55 * t
        let stemW: CGFloat = 2.5 + t * 1.5

        var stem = Path()
        stem.move(to: CGPoint(x: cx, y: baseY))
        stem.addLine(to: CGPoint(x: cx, y: baseY - stemH))
        context.stroke(stem, with: .color(sproutGreen),
                       style: StrokeStyle(lineWidth: stemW, lineCap: .round))

        let tipY = baseY - stemH

        if t > 0.1 {
            let leafT = min(1, (t - 0.1) / 0.5)
            let leafLen: CGFloat = 14 * leafT
            let leafW: CGFloat = 9 * leafT

            var leftLeaf = Path()
            leftLeaf.move(to: CGPoint(x: cx, y: tipY + 2))
            leftLeaf.addQuadCurve(
                to: CGPoint(x: cx - leafLen * 0.7, y: tipY - leafLen),
                control: CGPoint(x: cx - leafW, y: tipY - leafLen * 0.3)
            )
            leftLeaf.addQuadCurve(
                to: CGPoint(x: cx, y: tipY + 2),
                control: CGPoint(x: cx - leafW * 0.1, y: tipY - leafLen * 0.5)
            )
            context.fill(leftLeaf, with: .color(sproutGreen))

            var rightLeaf = Path()
            rightLeaf.move(to: CGPoint(x: cx, y: tipY + 2))
            rightLeaf.addQuadCurve(
                to: CGPoint(x: cx + leafLen * 0.7, y: tipY - leafLen),
                control: CGPoint(x: cx + leafW, y: tipY - leafLen * 0.3)
            )
            rightLeaf.addQuadCurve(
                to: CGPoint(x: cx, y: tipY + 2),
                control: CGPoint(x: cx + leafW * 0.1, y: tipY - leafLen * 0.5)
            )
            context.fill(rightLeaf, with: .color(Color(red: 0.36, green: 0.70, blue: 0.30)))
        }
    }

    // MARK: - Full Tree

    private struct BranchDef {
        let startFrac: CGFloat
        let angleDeg: CGFloat
        let lenFrac: CGFloat
        let side: CGFloat
        let appearT: CGFloat
        let thickness: CGFloat
    }

    private struct DomeDef {
        let branchIdx: Int
        let radiusFrac: CGFloat
        let appearT: CGFloat
        let colorTier: Int
    }

    private func drawTree(context: GraphicsContext, cx: CGFloat, baseY: CGFloat, w: CGFloat, h: CGFloat, g: Double, hp: Double) {
        let t = CGFloat((g - 0.25) / 0.75)
        let hpF = CGFloat(hp)

        let trunkH = h * (0.20 + 0.32 * t)
        let trunkW = w * (0.03 + 0.04 * t)

        // Trunk leans slightly right
        let trunkLean = w * 0.03 * t
        let trunkTopX = cx + trunkLean
        let trunkTopY = baseY - trunkH

        // Draw trunk as a tapered quad
        drawTrunk(context: context, cx: cx, baseY: baseY,
                  topX: trunkTopX, topY: trunkTopY, trunkW: trunkW)

        // Branch definitions
        let branchDefs: [BranchDef] = [
            // First branch: up-left (appears first, like the sprout reference)
            BranchDef(startFrac: 0.40, angleDeg: 55, lenFrac: 0.38, side: -1, appearT: 0.05, thickness: 0.7),
            // Main continuation: up with slight right lean
            BranchDef(startFrac: 0.35, angleDeg: 10, lenFrac: 0.42, side: 1, appearT: 0.20, thickness: 0.75),
            // Right branch: goes right
            BranchDef(startFrac: 0.50, angleDeg: 55, lenFrac: 0.35, side: 1, appearT: 0.35, thickness: 0.6),
            // Left lower branch
            BranchDef(startFrac: 0.60, angleDeg: 65, lenFrac: 0.28, side: -1, appearT: 0.50, thickness: 0.5),
        ]

        // Compute branch endpoints
        struct ComputedBranch {
            let startX: CGFloat
            let startY: CGFloat
            let tipX: CGFloat
            let tipY: CGFloat
            let progress: CGFloat
            let thickness: CGFloat
        }

        var branches: [ComputedBranch] = []
        for bd in branchDefs {
            let bp = min(1, max(0, (t - bd.appearT) / 0.30))
            guard bp > 0 else {
                branches.append(ComputedBranch(startX: 0, startY: 0, tipX: 0, tipY: 0, progress: 0, thickness: 0))
                continue
            }

            let startY = baseY - trunkH * (1 - bd.startFrac)
            let startFracT = bd.startFrac
            let startX = cx + trunkLean * (1 - startFracT)

            let rad = bd.angleDeg * .pi / 180
            let fullLen = trunkH * bd.lenFrac
            let curLen = fullLen * bp
            let tipX = startX + bd.side * sin(rad) * curLen
            let tipY = startY - cos(rad) * curLen

            branches.append(ComputedBranch(
                startX: startX, startY: startY,
                tipX: tipX, tipY: tipY,
                progress: bp,
                thickness: trunkW * bd.thickness
            ))

            // Draw branch
            drawBranch(context: context,
                       startX: startX, startY: startY,
                       endX: tipX, endY: tipY,
                       thickness: trunkW * bd.thickness * bp)
        }

        // Dome definitions tied to branches
        let domeDefs: [DomeDef] = [
            DomeDef(branchIdx: 0, radiusFrac: 0.10, appearT: 0.15, colorTier: 1),
            DomeDef(branchIdx: 1, radiusFrac: 0.16, appearT: 0.30, colorTier: 0),
            DomeDef(branchIdx: 2, radiusFrac: 0.13, appearT: 0.45, colorTier: 1),
            DomeDef(branchIdx: 3, radiusFrac: 0.10, appearT: 0.55, colorTier: 2),
        ]

        // Health-adjusted dome colors: (left, right) pairs per tier
        let domeColors: [(Color, Color)] = [
            // Tier 0: darkest (main top dome)
            (Color(red: 0.22 + 0.10 * Double(1 - hpF), green: 0.42 * Double(hpF), blue: 0.16 * Double(hpF)),
             Color(red: 0.14 + 0.08 * Double(1 - hpF), green: 0.32 * Double(hpF), blue: 0.10 * Double(hpF))),
            // Tier 1: medium green
            (Color(red: 0.36 + 0.08 * Double(1 - hpF), green: 0.58 * Double(hpF), blue: 0.22 * Double(hpF)),
             Color(red: 0.26 + 0.08 * Double(1 - hpF), green: 0.46 * Double(hpF), blue: 0.18 * Double(hpF))),
            // Tier 2: bright/light green
            (Color(red: 0.46 + 0.08 * Double(1 - hpF), green: 0.68 * Double(hpF), blue: 0.18 * Double(hpF)),
             Color(red: 0.36 + 0.08 * Double(1 - hpF), green: 0.56 * Double(hpF), blue: 0.14 * Double(hpF))),
        ]

        // Draw domes on branch tips (back to front for layering)
        // Sort by Y position so higher domes draw on top
        struct DomeToDraw {
            let cx: CGFloat
            let cy: CGFloat
            let radius: CGFloat
            let leftColor: Color
            let rightColor: Color
        }

        var domes: [DomeToDraw] = []
        for dd in domeDefs {
            guard dd.branchIdx < branches.count else { continue }
            let branch = branches[dd.branchIdx]
            guard branch.progress > 0 else { continue }

            let appear = min(1, max(0, (t - dd.appearT) / 0.25))
            guard appear > 0 else { continue }

            let radius = w * dd.radiusFrac * appear
            let (leftC, rightC) = domeColors[min(dd.colorTier, domeColors.count - 1)]

            domes.append(DomeToDraw(
                cx: branch.tipX,
                cy: branch.tipY,
                radius: radius,
                leftColor: leftC,
                rightColor: rightC
            ))
        }

        // Sort: draw lower (larger Y) domes first so upper ones overlap
        domes.sort { $0.cy > $1.cy }

        for dome in domes {
            guard dome.radius > 1 else { continue }
            drawDome(context: context,
                     cx: dome.cx, baselineY: dome.cy,
                     radius: dome.radius,
                     leftColor: dome.leftColor, rightColor: dome.rightColor)
        }
    }

    // MARK: - Trunk

    private func drawTrunk(context: GraphicsContext, cx: CGFloat, baseY: CGFloat,
                           topX: CGFloat, topY: CGFloat, trunkW: CGFloat) {
        let bottomW = trunkW
        let topW = trunkW * 0.65

        var trunk = Path()
        trunk.move(to: CGPoint(x: cx - bottomW / 2, y: baseY))
        trunk.addLine(to: CGPoint(x: topX - topW / 2, y: topY))
        trunk.addLine(to: CGPoint(x: topX + topW / 2, y: topY))
        trunk.addLine(to: CGPoint(x: cx + bottomW / 2, y: baseY))
        trunk.closeSubpath()
        context.fill(trunk, with: .color(trunkColor))

        // Shadow on right half
        var shadow = Path()
        shadow.move(to: CGPoint(x: cx, y: baseY))
        shadow.addLine(to: CGPoint(x: topX, y: topY))
        shadow.addLine(to: CGPoint(x: topX + topW / 2, y: topY))
        shadow.addLine(to: CGPoint(x: cx + bottomW / 2, y: baseY))
        shadow.closeSubpath()
        context.fill(shadow, with: .color(trunkShadow))
    }

    // MARK: - Branch

    private func drawBranch(context: GraphicsContext, startX: CGFloat, startY: CGFloat,
                            endX: CGFloat, endY: CGFloat, thickness: CGFloat) {
        guard thickness > 0.5 else { return }

        let dx = endX - startX
        let dy = endY - startY
        let len = sqrt(dx * dx + dy * dy)
        guard len > 0 else { return }

        let nx = -dy / len
        let ny = dx / len

        let startHalf = thickness * 0.5
        let endHalf = thickness * 0.3

        var path = Path()
        path.move(to: CGPoint(x: startX + nx * startHalf, y: startY + ny * startHalf))
        path.addLine(to: CGPoint(x: endX + nx * endHalf, y: endY + ny * endHalf))
        path.addLine(to: CGPoint(x: endX - nx * endHalf, y: endY - ny * endHalf))
        path.addLine(to: CGPoint(x: startX - nx * startHalf, y: startY - ny * startHalf))
        path.closeSubpath()
        context.fill(path, with: .color(trunkColor))
    }

    // MARK: - Dome (semi-circle with split color)

    private func drawDome(context: GraphicsContext, cx: CGFloat, baselineY: CGFloat,
                          radius: CGFloat, leftColor: Color, rightColor: Color) {
        // Semi-circle: flat bottom at baselineY, dome rises above
        var dome = Path()
        dome.move(to: CGPoint(x: cx - radius, y: baselineY))
        dome.addArc(
            center: CGPoint(x: cx, y: baselineY),
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        dome.closeSubpath()

        // Left half
        context.fill(dome, with: .color(leftColor))

        // Right half overlay
        var rightCtx = context
        rightCtx.clip(to: dome)
        let rightRect = CGRect(x: cx, y: baselineY - radius, width: radius, height: radius)
        rightCtx.fill(Rectangle().path(in: rightRect), with: .color(rightColor))
    }
}
