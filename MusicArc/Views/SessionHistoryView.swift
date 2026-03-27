import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SessionHistoryView: View {
    @Query(sort: \GameSession.date, order: .forward) private var sessions: [GameSession]
    @Environment(\.modelContext) private var modelContext
    @State private var showingExportSheet = false
    @State private var exportURL: URL?
    @State private var selectedSession: GameSession?

    var body: some View {
        Group {
            if sessions.isEmpty {
                emptyState
            } else {
                forestScene
            }
        }
        .navigationTitle("My Forest")
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
        .sheet(item: $selectedSession) { session in
            sessionDetailSheet(session: session)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView(
            "No Trees Yet",
            systemImage: "tree.fill",
            description: Text("Complete a session to plant your first tree!")
        )
    }

    // MARK: - Forest Scene

    private var forestScene: some View {
        GeometryReader { geo in
            ZStack {
                forestBackground(size: geo.size)

                ScrollView(.horizontal, showsIndicators: false) {
                    forestContent(viewportHeight: geo.size.height)
                }
            }
        }
    }

    private func forestBackground(size: CGSize) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.5, green: 0.75, blue: 1.0),
                    Color(red: 0.7, green: 0.88, blue: 1.0),
                    Color(red: 0.9, green: 0.95, blue: 0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.35, green: 0.6, blue: 0.25),
                                Color(red: 0.25, green: 0.45, blue: 0.18),
                                Color(red: 0.2, green: 0.35, blue: 0.12)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: size.height * 0.2)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private func forestContent(viewportHeight: CGFloat) -> some View {
        let treeSpacing: CGFloat = 100
        let totalWidth = CGFloat(sessions.count) * treeSpacing + 80

        return ZStack(alignment: .bottom) {
            Color.clear.frame(width: totalWidth, height: viewportHeight)

            HStack(alignment: .bottom, spacing: 20) {
                ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                    forestTree(session: session, index: index, viewportHeight: viewportHeight)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, viewportHeight * 0.18)
        }
    }

    private func forestTree(session: GameSession, index: Int, viewportHeight: CGFloat) -> some View {
        let treeHeight = 80 + 140 * session.treeGrowth

        return VStack(spacing: 4) {
            TreeView(growth: session.treeGrowth, health: session.treeHealth)
                .frame(width: 80, height: treeHeight)

            Text(session.date.formatted(.dateTime.month(.abbreviated).day()))
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.3), in: Capsule())
        }
        .onTapGesture {
            selectedSession = session
        }
    }

    // MARK: - Session Detail Sheet

    private func sessionDetailSheet(session: GameSession) -> some View {
        NavigationStack {
            VStack(spacing: 20) {
                TreeView(growth: session.treeGrowth, health: session.treeHealth)
                    .frame(width: 160, height: 200)
                    .padding(.top, 20)

                VStack(spacing: 4) {
                    Text("\(Int(session.treeGrowth * 100))% Growth")
                        .font(.title2.bold())
                    Text(session.date.formatted(date: .long, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    DetailRow(label: "Reps Completed", value: "\(session.completedReps)/\(session.totalReps)")
                    DetailRow(label: "Tree Health", value: "\(Int(session.treeHealth * 100))%")
                    DetailRow(label: "Rest Compliance", value: "\(Int(session.avgRestCompliance * 100))%")
                    DetailRow(label: "Duration", value: "\(session.durationSeconds)s")
                    if session.isDemoMode {
                        DetailRow(label: "Mode", value: "Demo")
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                Button(role: .destructive) {
                    modelContext.delete(session)
                    try? modelContext.save()
                    selectedSession = nil
                } label: {
                    Label("Remove Tree", systemImage: "trash")
                        .font(.body)
                }
                .padding(.top, 8)

                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationTitle("Tree Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { selectedSession = nil }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Export

    private func exportAllSessions() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let exportData = sessions.map { session in
            SessionExport(
                date: session.date,
                durationSeconds: session.durationSeconds,
                totalReps: session.totalReps,
                completedReps: session.completedReps,
                treeGrowth: session.treeGrowth,
                treeHealth: session.treeHealth,
                avgRestCompliance: session.avgRestCompliance,
                isDemoMode: session.isDemoMode
            )
        }

        guard let data = try? encoder.encode(exportData) else { return }

        let tempDir = FileManager.default.temporaryDirectory
        let filename = "musicarc_forest_\(Date.now.formatted(.iso8601.year().month().day())).json"
        let fileURL = tempDir.appendingPathComponent(filename)

        try? data.write(to: fileURL)
        exportURL = fileURL
        showingExportSheet = true
    }
}

// MARK: - Export Model

struct SessionExport: Codable {
    let date: Date
    let durationSeconds: Int
    let totalReps: Int
    let completedReps: Int
    let treeGrowth: Double
    let treeHealth: Double
    let avgRestCompliance: Double
    let isDemoMode: Bool
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        SessionHistoryView()
    }
    .modelContainer(for: GameSession.self, inMemory: true)
}
