import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SessionHistoryView: View {
    @Query(sort: \GameSession.date, order: .reverse) private var sessions: [GameSession]
    @Environment(\.modelContext) private var modelContext
    @State private var showingExportSheet = false
    @State private var exportURL: URL?

    var body: some View {
        Group {
            if sessions.isEmpty {
                emptyState
            } else {
                sessionList
            }
        }
        .navigationTitle("Session History")
        .toolbar {
            if !sessions.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        exportAllSessions()
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Sessions Yet",
            systemImage: "waveform.path",
            description: Text("Complete a game session to see it here.")
        )
    }

    private var sessionList: some View {
        List {
            ForEach(sessions) { session in
                SessionRow(session: session)
            }
            .onDelete(perform: deleteSessions)
        }
    }

    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sessions[index])
        }
        try? modelContext.save()
    }

    private func exportAllSessions() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let exportData = sessions.map { session in
            SessionExport(
                date: session.date,
                durationSeconds: session.durationSeconds,
                totalNotes: session.totalNotes,
                hits: session.hits,
                misses: session.misses,
                maxStreak: session.maxStreak,
                hitRate: session.hitRate,
                isDemoMode: session.isDemoMode
            )
        }

        guard let data = try? encoder.encode(exportData) else { return }

        let tempDir = FileManager.default.temporaryDirectory
        let filename = "music_arc_sessions_\(Date.now.formatted(.iso8601.year().month().day())).json"
        let fileURL = tempDir.appendingPathComponent(filename)

        try? data.write(to: fileURL)
        exportURL = fileURL
        showingExportSheet = true
    }
}

struct SessionExport: Codable {
    let date: Date
    let durationSeconds: Int
    let totalNotes: Int
    let hits: Int
    let misses: Int
    let maxStreak: Int
    let hitRate: Double
    let isDemoMode: Bool
}

struct SessionRow: View {
    let session: GameSession

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(rateColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text("\(Int(session.hitRate * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(rateColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline.weight(.medium))
                    if session.isDemoMode {
                        Text("DEMO")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(.purple.opacity(0.2), in: Capsule())
                            .foregroundStyle(.purple)
                    }
                }
                HStack(spacing: 12) {
                    Label("\(session.hits)/\(session.totalNotes)", systemImage: "checkmark.circle")
                    Label("\(session.durationSeconds)s", systemImage: "clock")
                    Label("\(session.maxStreak)", systemImage: "flame")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var rateColor: Color {
        if session.hitRate >= 0.9 { return .yellow }
        if session.hitRate >= 0.7 { return .green }
        if session.hitRate >= 0.5 { return .blue }
        return .purple
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
