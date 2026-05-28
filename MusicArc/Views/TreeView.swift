import SwiftUI

struct TreeView: View {
    let growth: Double
    let health: Double
    var species: TreeSpecies = .oak

    var body: some View {
        Canvas { context, size in
            species.renderer.draw(in: context, size: size, growth: growth, health: health)
        }
    }
}

// MARK: - Previews

private struct PreviewScene: View {
    let growth: Double
    let health: Double
    var species: TreeSpecies = .oak

    var body: some View {
        ZStack {
            Color(red: 0.5, green: 0.75, blue: 1).ignoresSafeArea()
            VStack { Spacer(); Color(red: 0.3, green: 0.55, blue: 0.2).frame(height: 120) }
            TreeView(growth: growth, health: health, species: species)
                .frame(width: 300, height: 500)
        }
    }
}

#Preview("Seed") { PreviewScene(growth: 0.03, health: 1.0) }
#Preview("Sprout") { PreviewScene(growth: 0.15, health: 1.0) }
#Preview("Young") { PreviewScene(growth: 0.4, health: 1.0) }
#Preview("Half Grown") { PreviewScene(growth: 0.65, health: 1.0) }
#Preview("Full Tree") { PreviewScene(growth: 1.0, health: 1.0) }
#Preview("Wilted") { PreviewScene(growth: 0.8, health: 0.2) }
#Preview("Round - Sprout") { PreviewScene(growth: 0.15, health: 1.0, species: .round) }
#Preview("Round - Young") { PreviewScene(growth: 0.45, health: 1.0, species: .round) }
#Preview("Round - Full") { PreviewScene(growth: 1.0, health: 1.0, species: .round) }
