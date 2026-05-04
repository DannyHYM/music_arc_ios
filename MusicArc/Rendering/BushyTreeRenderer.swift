import SwiftUI

struct BushyTreeRenderer: TreeRenderer {
    private let trunkColor = Color(red: 0.55, green: 0.40, blue: 0.26)
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
            let layout = computeLayout(cx: cx, baseY: baseY, w: w, h: h, g: g)
            drawBackgroundFoliage(context: context, layout: layout, w: w, h: h, g: g, hp: hp)
            drawTrunkAndBranches(context: context, cx: cx, layout: layout)
            drawFoliageCapsules(context: context, layout: layout, w: w, g: g, hp: hp)
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

    // MARK: - Layout

    private struct Branch {
        let startX: CGFloat
        let startY: CGFloat
        let endX: CGFloat
        let endY: CGFloat
        let progress: CGFloat
        let thickness: CGFloat
    }

    private struct CapsuleDef {
        let cx: CGFloat
        let cy: CGFloat
        let capsuleW: CGFloat
        let capsuleH: CGFloat
        let appear: CGFloat
        let colorTier: Int
    }

    private struct TreeLayout {
        let cx: CGFloat
        let baseY: CGFloat
        let trunkH: CGFloat
        let trunkW: CGFloat
        let trunkTopY: CGFloat
        let foliageTopY: CGFloat
        let branches: [Branch]
        let capsules: [CapsuleDef]
    }

    private func computeLayout(cx: CGFloat, baseY: CGFloat, w: CGFloat, h: CGFloat, g: Double) -> TreeLayout {
        let t = CGFloat((g - 0.25) / 0.75)
        let trunkH = h * (0.20 + 0.35 * t)
        let trunkW = w * (0.04 + 0.04 * t)
        let trunkTopY = baseY - trunkH

        struct BDef {
            let angleDeg: CGFloat
            let lenFrac: CGFloat
            let startFrac: CGFloat
            let appearT: CGFloat
            let side: CGFloat
        }

        let branchDefs: [BDef] = [
            BDef(angleDeg: 5,  lenFrac: 0.35, startFrac: 0.50, appearT: 0.10, side: -1),
            BDef(angleDeg: 40, lenFrac: 0.32, startFrac: 0.48, appearT: 0.15, side: 1),
            BDef(angleDeg: 55, lenFrac: 0.30, startFrac: 0.58, appearT: 0.25, side: -1),
            BDef(angleDeg: 50, lenFrac: 0.28, startFrac: 0.68, appearT: 0.30, side: 1),
            BDef(angleDeg: 65, lenFrac: 0.24, startFrac: 0.78, appearT: 0.40, side: -1),
            BDef(angleDeg: 45, lenFrac: 0.25, startFrac: 0.38, appearT: 0.50, side: 1),
        ]

        var branches: [Branch] = []
        var foliageTopY = trunkTopY

        for bd in branchDefs {
            let bp = min(1, max(0, (t - bd.appearT) / 0.30))
            guard bp > 0 else { continue }

            let startY = baseY - trunkH * (1 - bd.startFrac)
            let rad = bd.angleDeg * .pi / 180
            let len = trunkH * bd.lenFrac * bp
            let endX = cx + bd.side * sin(rad) * len
            let endY = startY - cos(rad) * len

            branches.append(Branch(
                startX: cx, startY: startY,
                endX: endX, endY: endY,
                progress: bp,
                thickness: trunkW * 0.55
            ))
            foliageTopY = min(foliageTopY, endY)
        }

        struct CDef {
            let branchIdx: Int
            let posAlong: CGFloat
            let wFrac: CGFloat
            let hFrac: CGFloat
            let appearT: CGFloat
            let colorTier: Int
        }

        let capsuleDefs: [CDef] = [
            CDef(branchIdx: 0, posAlong: 0.85, wFrac: 0.28, hFrac: 0.12, appearT: 0.15, colorTier: 2),
            CDef(branchIdx: 1, posAlong: 0.80, wFrac: 0.30, hFrac: 0.11, appearT: 0.20, colorTier: 1),
            CDef(branchIdx: 0, posAlong: 0.50, wFrac: 0.26, hFrac: 0.11, appearT: 0.28, colorTier: 1),
            CDef(branchIdx: 2, posAlong: 0.80, wFrac: 0.30, hFrac: 0.11, appearT: 0.30, colorTier: 1),
            CDef(branchIdx: 3, posAlong: 0.80, wFrac: 0.28, hFrac: 0.11, appearT: 0.35, colorTier: 1),
            CDef(branchIdx: 2, posAlong: 0.45, wFrac: 0.24, hFrac: 0.10, appearT: 0.40, colorTier: 0),
            CDef(branchIdx: 4, posAlong: 0.80, wFrac: 0.28, hFrac: 0.10, appearT: 0.45, colorTier: 1),
            CDef(branchIdx: 5, posAlong: 0.80, wFrac: 0.26, hFrac: 0.10, appearT: 0.50, colorTier: 1),
            CDef(branchIdx: 3, posAlong: 0.45, wFrac: 0.22, hFrac: 0.09, appearT: 0.55, colorTier: 0),
            CDef(branchIdx: 1, posAlong: 0.40, wFrac: 0.20, hFrac: 0.09, appearT: 0.60, colorTier: 1),
            CDef(branchIdx: 4, posAlong: 0.40, wFrac: 0.24, hFrac: 0.10, appearT: 0.65, colorTier: 0),
        ]

        var capsules: [CapsuleDef] = []
        for cd in capsuleDefs {
            guard cd.branchIdx < branches.count else { continue }
            let branch = branches[cd.branchIdx]

            let appear = min(1, max(0, (t - cd.appearT) / 0.20))
            guard appear > 0 else { continue }

            let clampedPos = min(cd.posAlong, branch.progress)
            let px = branch.startX + (branch.endX - branch.startX) * clampedPos
            let py = branch.startY + (branch.endY - branch.startY) * clampedPos

            capsules.append(CapsuleDef(
                cx: px,
                cy: py - w * cd.hFrac * 0.2,
                capsuleW: w * cd.wFrac * appear,
                capsuleH: w * cd.hFrac * appear,
                appear: appear,
                colorTier: cd.colorTier
            ))
        }

        return TreeLayout(
            cx: cx, baseY: baseY,
            trunkH: trunkH, trunkW: trunkW,
            trunkTopY: trunkTopY,
            foliageTopY: foliageTopY,
            branches: branches,
            capsules: capsules
        )
    }

    // MARK: - Background Foliage

    private func drawBackgroundFoliage(context: GraphicsContext, layout: TreeLayout, w: CGFloat, h: CGFloat, g: Double, hp: Double) {
        let t = CGFloat((g - 0.25) / 0.75)
        let bgT = min(1, max(0, (t - 0.55) / 0.35))
        guard bgT > 0 else { return }

        let hpF = CGFloat(hp)

        let bgDarkL = Color(
            red: 0.16 + 0.12 * Double(1 - hpF),
            green: 0.38 * Double(hpF),
            blue: 0.12 * Double(hpF)
        )
        let bgDarkR = Color(
            red: 0.22 + 0.10 * Double(1 - hpF),
            green: 0.44 * Double(hpF),
            blue: 0.16 * Double(hpF)
        )

        // Anchor blobs to the middle of the trunk, growing outward
        let trunkMidY = layout.baseY - layout.trunkH * 0.55
        let blobHalfH = layout.trunkH * 0.42 * bgT

        // Left blob: centered on trunk, offset slightly left, grows wider
        let leftW = w * 0.55 * bgT
        let leftCX = layout.cx - w * 0.06 * bgT
        let leftRect = CGRect(
            x: leftCX - leftW / 2,
            y: trunkMidY - blobHalfH,
            width: leftW,
            height: blobHalfH * 2
        )
        let leftR = min(leftW, blobHalfH * 2) * 0.22
        context.fill(RoundedRectangle(cornerRadius: leftR).path(in: leftRect),
                    with: .color(bgDarkL.opacity(Double(bgT))))

        // Right blob: centered on trunk, offset slightly right, grows wider
        let rightW = w * 0.55 * bgT
        let rightCX = layout.cx + w * 0.10 * bgT
        let rightRect = CGRect(
            x: rightCX - rightW / 2,
            y: trunkMidY - blobHalfH * 0.92,
            width: rightW,
            height: blobHalfH * 1.84
        )
        let rightR = min(rightW, blobHalfH * 1.84) * 0.22
        context.fill(RoundedRectangle(cornerRadius: rightR).path(in: rightRect),
                    with: .color(bgDarkR.opacity(Double(bgT))))
    }

    // MARK: - Trunk & Branches

    private func drawTrunkAndBranches(context: GraphicsContext, cx: CGFloat, layout: TreeLayout) {
        // Trunk only extends up to foliage zone, not above it
        let visibleTrunkTop = layout.foliageTopY + layout.trunkH * 0.05
        var trunk = Path()
        trunk.addRect(CGRect(
            x: cx - layout.trunkW / 2,
            y: visibleTrunkTop,
            width: layout.trunkW,
            height: layout.baseY - visibleTrunkTop
        ))
        context.fill(trunk, with: .color(trunkColor))

        for branch in layout.branches {
            var path = Path()
            path.move(to: CGPoint(x: branch.startX - branch.thickness / 2, y: branch.startY))
            path.addLine(to: CGPoint(x: branch.endX - branch.thickness * 0.3, y: branch.endY))
            path.addLine(to: CGPoint(x: branch.endX + branch.thickness * 0.3, y: branch.endY))
            path.addLine(to: CGPoint(x: branch.startX + branch.thickness / 2, y: branch.startY))
            path.closeSubpath()
            context.fill(path, with: .color(trunkColor))
        }
    }

    // MARK: - Foliage Capsules

    private func drawFoliageCapsules(context: GraphicsContext, layout: TreeLayout, w: CGFloat, g: Double, hp: Double) {
        let hpF = CGFloat(hp)

        let colors: [(Color, Color)] = [
            (Color(red: 0.24 + 0.15 * Double(1 - hpF), green: 0.48 * Double(hpF), blue: 0.20 * Double(hpF)),
             Color(red: 0.32 + 0.12 * Double(1 - hpF), green: 0.55 * Double(hpF), blue: 0.25 * Double(hpF))),
            (Color(red: 0.35 + 0.10 * Double(1 - hpF), green: 0.60 * Double(hpF), blue: 0.22 * Double(hpF)),
             Color(red: 0.42 + 0.08 * Double(1 - hpF), green: 0.65 * Double(hpF), blue: 0.28 * Double(hpF))),
            (Color(red: 0.46 + 0.10 * Double(1 - hpF), green: 0.72 * Double(hpF), blue: 0.18 * Double(hpF)),
             Color(red: 0.55 + 0.08 * Double(1 - hpF), green: 0.68 * Double(hpF), blue: 0.28 * Double(hpF))),
        ]

        for cap in layout.capsules {
            guard cap.capsuleW > 1 && cap.capsuleH > 1 else { continue }
            let (leftColor, rightColor) = colors[min(cap.colorTier, colors.count - 1)]
            drawSplitCapsule(context: context,
                            cx: cap.cx, cy: cap.cy,
                            w: cap.capsuleW, h: cap.capsuleH,
                            leftColor: leftColor, rightColor: rightColor)
        }
    }

    // MARK: - Split Capsule Helper

    private func drawSplitCapsule(context: GraphicsContext, cx: CGFloat, cy: CGFloat, w: CGFloat, h: CGFloat, leftColor: Color, rightColor: Color) {
        let cornerR = min(w, h) * 0.45
        let rect = CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h)

        context.fill(RoundedRectangle(cornerRadius: cornerR).path(in: rect), with: .color(leftColor))

        let rightRect = CGRect(x: cx, y: cy - h / 2, width: w / 2, height: h)
        var clipContext = context
        clipContext.clip(to: RoundedRectangle(cornerRadius: cornerR).path(in: rect))
        clipContext.fill(Rectangle().path(in: rightRect), with: .color(rightColor))
    }
}
