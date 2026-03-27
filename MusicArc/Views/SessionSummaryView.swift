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
                colors: [
                    Color(red: 0.85, green: 0.95, blue: 0.85),
                    Color(red: 0.7, green: 0.88, blue: 0.7),
                    Color(red: 0.5, green: 0.75, blue: 0.45)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header
                    treeDisplay
                    growthRing
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

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: gradeIcon)
                .font(.system(size: 48))
                .foregroundStyle(gradeColor)
            Text(gradeLabel)
                .font(.title2.bold())
                .foregroundStyle(Color(red: 0.15, green: 0.35, blue: 0.15))
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

    // MARK: - Tree Display

    private var treeDisplay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)

            TreeView(growth: result.treeGrowth, health: result.treeHealth)
                .padding(20)
        }
        .frame(height: 220)
    }

    // MARK: - Growth Ring

    private var growthRing: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)
            Circle()
                .trim(from: 0, to: result.treeGrowth)
                .stroke(gradeColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text("\(result.growthPercentage)%")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.15, green: 0.4, blue: 0.15))
                Text("Growth")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 140, height: 140)
    }

    // MARK: - Stats

    private var statsGrid: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Reps",
                value: "\(result.completedReps)/\(result.totalReps)",
                icon: "repeat",
                color: .green
            )
            StatCard(
                title: "Health",
                value: "\(Int(result.treeHealth * 100))%",
                icon: "heart.fill",
                color: result.treeHealth > 0.7 ? .pink : .orange
            )
            StatCard(
                title: "Rest",
                value: "\(Int(result.avgRestCompliance * 100))%",
                icon: "moon.fill",
                color: .cyan
            )
        }
    }

    private var detailRows: some View {
        VStack(spacing: 12) {
            DetailRow(label: "Duration", value: "\(result.durationSeconds)s")
            DetailRow(label: "Total Reps", value: "\(result.totalReps)")
            DetailRow(label: "Date", value: result.date.formatted(date: .abbreviated, time: .shortened))
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                saveSession()
            } label: {
                Label(
                    isSaved ? "Planted!" : "Plant in Forest",
                    systemImage: isSaved ? "checkmark.circle.fill" : "leaf.fill"
                )
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(isSaved ? .green : Color(red: 0.25, green: 0.6, blue: 0.25))
            .disabled(isSaved)

            Button {
                navigationPath.removeLast(navigationPath.count)
            } label: {
                Text("Back to Home")
                    .font(.body)
            }
            .foregroundStyle(Color(red: 0.2, green: 0.45, blue: 0.2))
        }
    }

    // MARK: - Helpers

    private func saveSession() {
        let session = GameSession(
            date: result.date,
            durationSeconds: result.durationSeconds,
            totalReps: result.totalReps,
            completedReps: result.completedReps,
            treeGrowth: result.treeGrowth,
            treeHealth: result.treeHealth,
            avgRestCompliance: result.avgRestCompliance,
            isDemoMode: result.isDemoMode
        )
        modelContext.insert(session)
        try? modelContext.save()
        isSaved = true
    }

    private var gradeIcon: String {
        if result.treeGrowth >= 0.9 { return "tree.fill" }
        if result.treeGrowth >= 0.7 { return "leaf.fill" }
        if result.treeGrowth >= 0.5 { return "camera.macro" }
        return "leaf.arrow.triangle.circlepath"
    }

    private var gradeLabel: String {
        if result.treeGrowth >= 0.9 { return "Magnificent Oak!" }
        if result.treeGrowth >= 0.7 { return "Strong Sapling!" }
        if result.treeGrowth >= 0.5 { return "Growing Nicely!" }
        return "Keep Planting!"
    }

    private var gradeColor: Color {
        if result.treeGrowth >= 0.9 { return Color(red: 0.2, green: 0.7, blue: 0.2) }
        if result.treeGrowth >= 0.7 { return Color(red: 0.3, green: 0.65, blue: 0.3) }
        if result.treeGrowth >= 0.5 { return Color(red: 0.4, green: 0.6, blue: 0.3) }
        return Color(red: 0.5, green: 0.55, blue: 0.3)
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

#Preview {
    NavigationStack {
        SessionSummaryView(
            result: GameResult(
                date: .now,
                durationSeconds: 61,
                totalReps: 8,
                completedReps: 8,
                treeGrowth: 0.85,
                treeHealth: 0.9,
                avgRestCompliance: 0.88,
                inputMode: .touch
            ),
            navigationPath: .constant(NavigationPath())
        )
    }
    .modelContainer(for: GameSession.self, inMemory: true)
}
