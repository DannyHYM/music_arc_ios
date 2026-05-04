import SwiftUI

struct RoundTreeRenderer: TreeRenderer {
    // Flat design palette
    private let trunkColor = Color(red: 0.55, green: 0.40, blue: 0.26)
    private let darkGreenL = Color(red: 0.24, green: 0.48, blue: 0.24)
    private let darkGreenR = Color(red: 0.32, green: 0.56, blue: 0.30)
    private let lightGreenL = Color(red: 0.46, green: 0.68, blue: 0.22)
    private let lightGreenR = Color(red: 0.56, green: 0.78, blue: 0.30)
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
            drawTrunk(context: context, cx: cx, baseY: baseY, w: w, h: h, g: g)
            drawCanopies(context: context, cx: cx, baseY: baseY, w: w, h: h, g: g, hp: hp)
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

        // Straight stem
        var stem = Path()
        stem.move(to: CGPoint(x: cx, y: baseY))
        stem.addLine(to: CGPoint(x: cx, y: baseY - stemH))
        context.stroke(stem, with: .color(sproutGreen),
                       style: StrokeStyle(lineWidth: stemW, lineCap: .round))

        let tipY = baseY - stemH

        // Two leaves forming Y shape
        if t > 0.1 {
            let leafT = min(1, (t - 0.1) / 0.5)
            let leafLen: CGFloat = 16 * leafT
            let leafW: CGFloat = 10 * leafT

            // Left leaf
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

            // Right leaf
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

    // MARK: - Trunk with Y-Fork (0.25+)

    // Branch geometry shared between trunk and canopy drawing
    private struct BranchLayout {
        let forkY: CGFloat
        let forkT: CGFloat
        let trunkH: CGFloat
        let trunkW: CGFloat
        // Branch 1: up-left to large canopy
        let mainEndX: CGFloat
        let mainEndY: CGFloat
        // Branch 2: up-right to medium canopy
        let rightEndX: CGFloat
        let rightEndY: CGFloat
        // Branch 3: down-left to small canopy
        let leftSmallEndX: CGFloat
        let leftSmallEndY: CGFloat
    }

    private func branchLayout(cx: CGFloat, baseY: CGFloat, w: CGFloat, h: CGFloat, g: Double) -> BranchLayout {
        let t = CGFloat((g - 0.25) / 0.75)
        let trunkH = h * (0.15 + 0.30 * t)
        let trunkW = w * (0.04 + 0.04 * t)
        let forkY = baseY - trunkH * 0.50
        let forkT = min(1, max(0, (t - 0.25) / 0.40))
        let branchLen = trunkH * 0.50 * forkT

        let mainAngle: CGFloat = 12 * .pi / 180
        let rightAngle: CGFloat = 28 * .pi / 180
        let leftSmallAngle: CGFloat = 40 * .pi / 180

        return BranchLayout(
            forkY: forkY,
            forkT: forkT,
            trunkH: trunkH,
            trunkW: trunkW,
            mainEndX: cx - sin(mainAngle) * branchLen,
            mainEndY: forkY - cos(mainAngle) * branchLen,
            rightEndX: cx + sin(rightAngle) * branchLen * 0.85,
            rightEndY: forkY - cos(rightAngle) * branchLen * 0.75,
            leftSmallEndX: cx - sin(leftSmallAngle) * branchLen * 0.55,
            leftSmallEndY: forkY - cos(leftSmallAngle) * branchLen * 0.35
        )
    }

    private func drawTrunk(context: GraphicsContext, cx: CGFloat, baseY: CGFloat, w: CGFloat, h: CGFloat, g: Double) {
        let bl = branchLayout(cx: cx, baseY: baseY, w: w, h: h, g: g)
        let t = CGFloat((g - 0.25) / 0.75)

        let trunkTopY = bl.forkY * bl.forkT + (baseY - bl.trunkH) * (1 - bl.forkT)

        var mainTrunk = Path()
        mainTrunk.addRect(CGRect(
            x: cx - bl.trunkW / 2,
            y: trunkTopY,
            width: bl.trunkW,
            height: baseY - trunkTopY
        ))
        context.fill(mainTrunk, with: .color(trunkColor))

        if bl.forkT > 0 {
            let branchW = bl.trunkW * 0.70

            // Branch 1: up-left (main canopy)
            var b1 = Path()
            b1.move(to: CGPoint(x: cx - branchW / 2, y: bl.forkY))
            b1.addLine(to: CGPoint(x: bl.mainEndX - branchW / 2, y: bl.mainEndY))
            b1.addLine(to: CGPoint(x: bl.mainEndX + branchW / 2, y: bl.mainEndY))
            b1.addLine(to: CGPoint(x: cx + branchW / 2, y: bl.forkY))
            b1.closeSubpath()
            context.fill(b1, with: .color(trunkColor))

            // Branch 2: up-right (medium canopy)
            var b2 = Path()
            b2.move(to: CGPoint(x: cx, y: bl.forkY + bl.trunkH * 0.03))
            b2.addLine(to: CGPoint(x: bl.rightEndX - branchW * 0.35, y: bl.rightEndY))
            b2.addLine(to: CGPoint(x: bl.rightEndX + branchW * 0.35, y: bl.rightEndY))
            b2.addLine(to: CGPoint(x: cx + branchW / 2, y: bl.forkY + bl.trunkH * 0.03))
            b2.closeSubpath()
            context.fill(b2, with: .color(trunkColor))

            // Branch 3: down-left (small canopy) -- appears later
            let thirdBranchT = min(1, max(0, (t - 0.55) / 0.30))
            if thirdBranchT > 0 {
                let sbEndX = cx + (bl.leftSmallEndX - cx) * thirdBranchT
                let sbEndY = bl.forkY + (bl.leftSmallEndY - bl.forkY) * thirdBranchT
                var b3 = Path()
                b3.move(to: CGPoint(x: cx - branchW * 0.3, y: bl.forkY + bl.trunkH * 0.08))
                b3.addLine(to: CGPoint(x: sbEndX - branchW * 0.25, y: sbEndY))
                b3.addLine(to: CGPoint(x: sbEndX + branchW * 0.25, y: sbEndY))
                b3.addLine(to: CGPoint(x: cx, y: bl.forkY + bl.trunkH * 0.08))
                b3.closeSubpath()
                context.fill(b3, with: .color(trunkColor))
            }
        }
    }

    // MARK: - Canopies (split circles)

    private func drawCanopies(context: GraphicsContext, cx: CGFloat, baseY: CGFloat, w: CGFloat, h: CGFloat, g: Double, hp: Double) {
        let t = CGFloat((g - 0.25) / 0.75)
        let bl = branchLayout(cx: cx, baseY: baseY, w: w, h: h, g: g)

        // Health-adjusted colors
        let hpF = CGFloat(hp)
        let dkL = Color(
            red: 0.24 + 0.15 * Double(1 - hpF),
            green: 0.48 * Double(hpF),
            blue: 0.24 * Double(hpF)
        )
        let dkR = Color(
            red: 0.32 + 0.12 * Double(1 - hpF),
            green: 0.56 * Double(hpF),
            blue: 0.30 * Double(hpF)
        )
        let ltL = Color(
            red: 0.46 + 0.10 * Double(1 - hpF),
            green: 0.68 * Double(hpF),
            blue: 0.22 * Double(hpF)
        )
        let ltR = Color(
            red: 0.56 + 0.08 * Double(1 - hpF),
            green: 0.78 * Double(hpF),
            blue: 0.30 * Double(hpF)
        )
        let mdL = Color(
            red: 0.38 + 0.10 * Double(1 - hpF),
            green: 0.58 * Double(hpF),
            blue: 0.22 * Double(hpF)
        )
        let mdR = Color(
            red: 0.45 + 0.08 * Double(1 - hpF),
            green: 0.65 * Double(hpF),
            blue: 0.28 * Double(hpF)
        )

        // 1) Main large canopy (dark green, top-left)
        let mainCanopyT = min(1, t / 0.45)
        if mainCanopyT > 0 {
            let mainR = w * 0.28 * mainCanopyT
            let noForkTopY = baseY - bl.trunkH
            let noForkX = cx
            let noForkY = noForkTopY - mainR * 0.5
            let onBranchX = bl.mainEndX
            let onBranchY = bl.mainEndY - mainR * 0.55

            let mainCX = noForkX + (onBranchX - noForkX) * bl.forkT
            let mainCY = noForkY + (onBranchY - noForkY) * bl.forkT

            drawSplitCircle(context: context, cx: mainCX, cy: mainCY, r: mainR,
                           leftColor: dkL, rightColor: dkR)
        }

        // 2) Medium canopy (medium green, right side)
        let secondT = min(1, max(0, (t - 0.35) / 0.35))
        if secondT > 0 {
            let secR = w * 0.19 * secondT
            let secCX = bl.rightEndX + secR * 0.1
            let secCY = bl.rightEndY - secR * 0.45
            drawSplitCircle(context: context, cx: secCX, cy: secCY, r: secR,
                           leftColor: mdL, rightColor: mdR)
        }

        // 3) Small canopy (bright/light green, bottom-left)
        // Track the branch tip so the canopy never floats ahead of the branch
        let thirdBranchT = min(1, max(0, (t - 0.55) / 0.30))
        let thirdT = min(1, max(0, (t - 0.65) / 0.35))
        if thirdT > 0 {
            let thirdR = w * 0.11 * thirdT
            let curTipX = cx + (bl.leftSmallEndX - cx) * thirdBranchT
            let curTipY = bl.forkY + (bl.leftSmallEndY - bl.forkY) * thirdBranchT
            let thirdCX = curTipX
            let thirdCY = curTipY - thirdR * 0.5
            drawSplitCircle(context: context, cx: thirdCX, cy: thirdCY, r: thirdR,
                           leftColor: ltL, rightColor: ltR)
        }
    }

    // MARK: - Split Circle Helper

    private func drawSplitCircle(context: GraphicsContext, cx: CGFloat, cy: CGFloat, r: CGFloat, leftColor: Color, rightColor: Color) {
        guard r > 0.5 else { return }

        // Left half
        var leftHalf = Path()
        leftHalf.move(to: CGPoint(x: cx, y: cy - r))
        leftHalf.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                        startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: true)
        leftHalf.closeSubpath()
        context.fill(leftHalf, with: .color(leftColor))

        // Right half
        var rightHalf = Path()
        rightHalf.move(to: CGPoint(x: cx, y: cy - r))
        rightHalf.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                        startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
        rightHalf.closeSubpath()
        context.fill(rightHalf, with: .color(rightColor))
    }
}
