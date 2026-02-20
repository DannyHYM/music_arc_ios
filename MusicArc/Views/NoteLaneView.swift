import SwiftUI

struct NoteLaneView: View {
    let notes: [GameNote]
    let currentArmHeight: Double
    let elapsedTime: TimeInterval
    let hitWindowDuration: TimeInterval = 0.8

    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            let width = geo.size.width

            ZStack {
                laneBackground(width: width, height: height)

                // Hit zone column
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 50)
                    .position(x: width * 0.75, y: height / 2)

                // Arm position indicator
                armIndicator(width: width, height: height)

                ForEach(notes) { note in
                    noteView(note: note, width: width, height: height)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func laneBackground(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))

            ForEach([0.2, 0.5, 0.8], id: \.self) { level in
                let y = height * (1.0 - level)
                HStack(spacing: 0) {
                    Path { path in
                        path.move(to: CGPoint(x: 20, y: y))
                        path.addLine(to: CGPoint(x: width - 20, y: y))
                    }
                    .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                }

                Text(heightLabel(level))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.25))
                    .position(x: width - 30, y: y - 10)
            }
        }
    }

    private func armIndicator(width: CGFloat, height: CGFloat) -> some View {
        let armY = height * (1.0 - currentArmHeight)
        return ZStack {
            Capsule()
                .fill(.purple.opacity(0.3))
                .frame(width: width * 0.7, height: 24)
            Capsule()
                .fill(.purple)
                .frame(width: width * 0.7, height: 4)
            Circle()
                .fill(.purple)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.6), lineWidth: 2)
                )
                .shadow(color: .purple.opacity(0.5), radius: 8)
                .offset(x: -width * 0.3)
        }
        .position(x: width * 0.45, y: armY)
        .animation(.easeOut(duration: 0.08), value: currentArmHeight)
    }

    @ViewBuilder
    private func noteView(note: GameNote, width: CGFloat, height: CGFloat) -> some View {
        let y = height * (1.0 - note.targetHeight)
        let timeDelta = note.scheduledTime - elapsedTime
        let approachDuration: TimeInterval = 2.5
        let progress = 1.0 - (timeDelta / approachDuration)

        if note.wasJudged {
            judgedNoteView(note: note, x: width * 0.75, y: y)
        } else if progress > 0 && progress <= 1.3 {
            let x = width * 0.1 + (width * 0.65) * min(progress, 1.0)
            activeNoteView(note: note, x: x, y: y, progress: progress)
        }
    }

    private func activeNoteView(note: GameNote, x: CGFloat, y: CGFloat, progress: Double) -> some View {
        let color = noteColor(for: note.targetHeight)
        let isNearHitZone = progress > 0.85
        let scale = isNearHitZone ? 1.15 : 1.0

        return ZStack {
            if isNearHitZone {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 48, height: 48)
            }
            Circle()
                .fill(color)
                .frame(width: 30, height: 30)
            Circle()
                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                .frame(width: 30, height: 30)
            Image(systemName: "music.note")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
        }
        .scaleEffect(scale)
        .shadow(color: color.opacity(0.6), radius: isNearHitZone ? 12 : 6)
        .position(x: x, y: y)
        .animation(.easeInOut(duration: 0.2), value: isNearHitZone)
    }

    private func judgedNoteView(note: GameNote, x: CGFloat, y: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(note.wasHit ? Color.green.opacity(0.5) : Color.red.opacity(0.3))
                .frame(width: 36, height: 36)
            Image(systemName: note.wasHit ? "checkmark" : "xmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(note.wasHit ? .green : .red)
        }
        .scaleEffect(note.wasHit ? 1.2 : 0.8)
        .opacity(0.6)
        .position(x: x, y: y)
    }

    private func noteColor(for targetHeight: Double) -> Color {
        if targetHeight < 0.35 { return .cyan }
        if targetHeight < 0.65 { return .green }
        return .orange
    }

    private func heightLabel(_ level: Double) -> String {
        if level < 0.35 { return "LOW" }
        if level < 0.65 { return "MID" }
        return "HIGH"
    }
}
