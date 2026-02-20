import SwiftUI
import SwiftData

struct SessionSummaryView: View {
    let result: GameResult
    @Binding var navigationPath: NavigationPath
    @Environment(\.modelContext) private var modelContext
    @State private var isSaved = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemBackground), Color.purple.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    header
                    scoreRing
                    statsGrid
                    detailRows
                    actionButtons
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Session Summary")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: gradeIcon)
                .font(.system(size: 48))
                .foregroundStyle(gradeColor)
            Text(gradeLabel)
                .font(.title2.bold())
            if result.inputMode != .camera {
                Label(result.inputMode.rawValue, systemImage: result.inputMode == .touch ? "hand.draw" : "play.rectangle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
    }

    private var scoreRing: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)
            Circle()
                .trim(from: 0, to: result.hitRate)
                .stroke(gradeColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text("\(Int(result.hitRate * 100))%")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text("Hit Rate")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 140, height: 140)
    }

    private var statsGrid: some View {
        HStack(spacing: 16) {
            StatCard(title: "Hits", value: "\(result.hits)", icon: "checkmark.circle.fill", color: .green)
            StatCard(title: "Misses", value: "\(result.misses)", icon: "xmark.circle.fill", color: .red)
            StatCard(title: "Streak", value: "\(result.maxStreak)", icon: "flame.fill", color: .orange)
        }
    }

    private var detailRows: some View {
        VStack(spacing: 12) {
            DetailRow(label: "Duration", value: "\(result.durationSeconds)s")
            DetailRow(label: "Total Notes", value: "\(result.totalNotes)")
            DetailRow(label: "Date", value: result.date.formatted(date: .abbreviated, time: .shortened))
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                saveSession()
            } label: {
                Label(
                    isSaved ? "Saved" : "Save Session",
                    systemImage: isSaved ? "checkmark.circle.fill" : "square.and.arrow.down"
                )
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(isSaved ? .green : .purple)
            .disabled(isSaved)

            Button {
                navigationPath.removeLast(navigationPath.count)
            } label: {
                Text("Back to Home")
                    .font(.body)
            }
        }
    }

    private func saveSession() {
        let session = GameSession(
            date: result.date,
            durationSeconds: result.durationSeconds,
            totalNotes: result.totalNotes,
            hits: result.hits,
            misses: result.misses,
            maxStreak: result.maxStreak,
            hitRate: result.hitRate,
            isDemoMode: result.isDemoMode
        )
        modelContext.insert(session)
        try? modelContext.save()
        isSaved = true
    }

    private var gradeIcon: String {
        if result.hitRate >= 0.9 { return "star.circle.fill" }
        if result.hitRate >= 0.7 { return "hand.thumbsup.circle.fill" }
        if result.hitRate >= 0.5 { return "figure.walk.circle.fill" }
        return "arrow.up.circle.fill"
    }

    private var gradeLabel: String {
        if result.hitRate >= 0.9 { return "Outstanding!" }
        if result.hitRate >= 0.7 { return "Great Job!" }
        if result.hitRate >= 0.5 { return "Good Effort!" }
        return "Keep Practicing!"
    }

    private var gradeColor: Color {
        if result.hitRate >= 0.9 { return .yellow }
        if result.hitRate >= 0.7 { return .green }
        if result.hitRate >= 0.5 { return .blue }
        return .purple
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
