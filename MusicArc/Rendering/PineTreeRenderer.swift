import SwiftUI

struct PineTreeRenderer: TreeRenderer {
    private let trunkColor = Color(red: 0.55, green: 0.40, blue: 0.26)
    private let trunkShadow = Color(red: 0.45, green: 0.32, blue: 0.20)
    private let sproutGreen = Color(red: 0.30, green: 0.62, blue: 0.25)

    private let foliageLight = Color(red: 0.42, green: 0.66, blue: 0.24)
    private let foliageMid = Color(red: 0.34, green: 0.56, blue: 0.20)
    private let foliageDark = Color(red: 0.24, green: 0.44, blue: 0.16)
    private let foliageShadow = Color(red: 0.20, green: 0.38, blue: 0.14)

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

    // MARK: - Full Tree (0.25 - 1.0)

    private func drawTree(context: GraphicsContext, cx: CGFloat, baseY: CGFloat, w: CGFloat, h: CGFloat, g: Double, hp: Double) {
        let t = CGFloat((g - 0.25) / 0.75)
        let hpF = CGFloat(hp)

        let trunkH = h * (0.12 + 0.22 * t)
        let trunkW = w * (0.04 + 0.04 * t)
        let trunkTopY = baseY - trunkH

        // The foliage zone sits on top of the trunk
        let totalFoliageH = h * (0.15 + 0.38 * t)

        // Tier definitions: each tier is a triangle
        // bottomY = where the triangle base sits
        // topY = the apex
        // halfW = half the base width
        struct Tier {
            let topY: CGFloat
            let bottomY: CGFloat
            let halfW: CGFloat
            let appear: CGFloat
        }

        // Tiers grow from the trunk top, stacking upward
        // Tier 1 (bottom, widest) appears first
        let tier1Appear = min(1, t / 0.35)
        // Tier 2 (middle) appears at t=0.25
        let tier2Appear = min(1, max(0, (t - 0.25) / 0.35))
        // Tier 3 (top, smallest) appears at t=0.55
        let tier3Appear = min(1, max(0, (t - 0.55) / 0.35))

        let tier1BottomY = trunkTopY + trunkW * 0.3
        let tier1H = totalFoliageH * 0.45 * tier1Appear
        let tier1TopY = tier1BottomY - tier1H
        let tier1HalfW = w * (0.22 + 0.16 * t) * tier1Appear

        let tier2BottomY = tier1TopY + tier1H * 0.35
        let tier2H = totalFoliageH * 0.42 * tier2Appear
        let tier2TopY = tier2BottomY - tier2H
        let tier2HalfW = w * (0.17 + 0.12 * t) * tier2Appear

        let tier3BottomY = tier2TopY + tier2H * 0.35
        let tier3H = totalFoliageH * 0.38 * tier3Appear
        let tier3TopY = tier3BottomY - tier3H
        let tier3HalfW = w * (0.12 + 0.08 * t) * tier3Appear

        var tiers: [Tier] = []

        if tier1Appear > 0 {
            tiers.append(Tier(topY: tier1TopY, bottomY: tier1BottomY, halfW: tier1HalfW, appear: tier1Appear))
        }
        if tier2Appear > 0 {
            tiers.append(Tier(topY: tier2TopY, bottomY: tier2BottomY, halfW: tier2HalfW, appear: tier2Appear))
        }
        if tier3Appear > 0 {
            tiers.append(Tier(topY: tier3TopY, bottomY: tier3BottomY, halfW: tier3HalfW, appear: tier3Appear))
        }

        // Trunk: draw up to where the bottom tier covers it
        let trunkVisibleTop = tiers.isEmpty ? trunkTopY : tiers[0].bottomY - tiers[0].halfW * 0.1

        // Trunk shadow (right half slightly darker)
        var trunkPath = Path()
        trunkPath.addRect(CGRect(
            x: cx - trunkW / 2,
            y: trunkVisibleTop,
            width: trunkW,
            height: baseY - trunkVisibleTop
        ))
        context.fill(trunkPath, with: .color(trunkColor))

        var trunkShadowPath = Path()
        trunkShadowPath.addRect(CGRect(
            x: cx,
            y: trunkVisibleTop,
            width: trunkW / 2,
            height: baseY - trunkVisibleTop
        ))
        context.fill(trunkShadowPath, with: .color(trunkShadow))

        // Health-adjusted colors
        let lightC = Color(
            red: 0.42 + 0.10 * Double(1 - hpF),
            green: 0.66 * Double(hpF),
            blue: 0.24 * Double(hpF)
        )
        let midC = Color(
            red: 0.34 + 0.10 * Double(1 - hpF),
            green: 0.56 * Double(hpF),
            blue: 0.20 * Double(hpF)
        )
        let darkC = Color(
            red: 0.24 + 0.10 * Double(1 - hpF),
            green: 0.44 * Double(hpF),
            blue: 0.16 * Double(hpF)
        )
        let shadowC = Color(
            red: 0.20 + 0.10 * Double(1 - hpF),
            green: 0.38 * Double(hpF),
            blue: 0.14 * Double(hpF)
        )

        // Draw tiers bottom to top
        for (i, tier) in tiers.enumerated() {
            guard tier.halfW > 1 else { continue }

            drawTier(
                context: context, cx: cx,
                topY: tier.topY, bottomY: tier.bottomY, halfW: tier.halfW,
                leftColor: lightC, rightColor: midC,
                shadowColor: i == tiers.count - 1 ? darkC : shadowC,
                showShadow: tier.appear > 0.5 && t > 0.6,
                shadowIntensity: min(1, max(0, (t - 0.6) / 0.3))
            )
        }
    }

    // MARK: - Triangle Tier

    private func drawTier(
        context: GraphicsContext, cx: CGFloat,
        topY: CGFloat, bottomY: CGFloat, halfW: CGFloat,
        leftColor: Color, rightColor: Color,
        shadowColor: Color, showShadow: Bool, shadowIntensity: CGFloat
    ) {
        // Full triangle
        var tri = Path()
        tri.move(to: CGPoint(x: cx, y: topY))
        tri.addLine(to: CGPoint(x: cx - halfW, y: bottomY))
        tri.addLine(to: CGPoint(x: cx + halfW, y: bottomY))
        tri.closeSubpath()

        // Left half: lighter green
        context.fill(tri, with: .color(leftColor))

        // Right half: slightly darker green
        var rightCtx = context
        rightCtx.clip(to: tri)
        let rightRect = CGRect(x: cx, y: topY, width: halfW, height: bottomY - topY)
        rightCtx.fill(Rectangle().path(in: rightRect), with: .color(rightColor))

        // Shadow/dark accent shapes on the right side (angular shapes like the reference)
        if showShadow && shadowIntensity > 0 {
            let tierH = bottomY - topY
            let midY = topY + tierH * 0.45

            // Right-side angular shadow: a smaller triangle inset on the right
            var shadowTri = Path()
            shadowTri.move(to: CGPoint(x: cx + halfW * 0.15, y: midY))
            shadowTri.addLine(to: CGPoint(x: cx + halfW * 0.85, y: bottomY - tierH * 0.08))
            shadowTri.addLine(to: CGPoint(x: cx + halfW * 0.35, y: bottomY - tierH * 0.08))
            shadowTri.closeSubpath()

            var shadowCtx = context
            shadowCtx.clip(to: tri)
            shadowCtx.fill(shadowTri, with: .color(shadowColor.opacity(Double(shadowIntensity) * 0.7)))

            // A smaller notch near the top-right
            var notch = Path()
            notch.move(to: CGPoint(x: cx + halfW * 0.05, y: midY - tierH * 0.12))
            notch.addLine(to: CGPoint(x: cx + halfW * 0.50, y: midY + tierH * 0.05))
            notch.addLine(to: CGPoint(x: cx + halfW * 0.15, y: midY + tierH * 0.05))
            notch.closeSubpath()

            shadowCtx.fill(notch, with: .color(shadowColor.opacity(Double(shadowIntensity) * 0.5)))
        }
    }
}
