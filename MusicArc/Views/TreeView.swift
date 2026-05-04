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

#Preview("Seed") {
    ZStack {
        Color(red: 0.5, green: 0.75, blue: 1).ignoresSafeArea()
        VStack { Spacer(); Color(red: 0.3, green: 0.55, blue: 0.2).frame(height: 120) }
        TreeView(growth: 0.03, health: 1.0)
            .frame(width: 300, height: 500)
    }
}

#Preview("Sprout") {
    ZStack {
        Color(red: 0.5, green: 0.75, blue: 1).ignoresSafeArea()
        VStack { Spacer(); Color(red: 0.3, green: 0.55, blue: 0.2).frame(height: 120) }
        TreeView(growth: 0.15, health: 1.0)
            .frame(width: 300, height: 500)
    }
}

#Preview("Young") {
    ZStack {
        Color(red: 0.5, green: 0.75, blue: 1).ignoresSafeArea()
        VStack { Spacer(); Color(red: 0.3, green: 0.55, blue: 0.2).frame(height: 120) }
        TreeView(growth: 0.4, health: 1.0)
            .frame(width: 300, height: 500)
    }
}

#Preview("Half Grown") {
    ZStack {
        Color(red: 0.5, green: 0.75, blue: 1).ignoresSafeArea()
        VStack { Spacer(); Color(red: 0.3, green: 0.55, blue: 0.2).frame(height: 120) }
        TreeView(growth: 0.65, health: 1.0)
            .frame(width: 300, height: 500)
    }
}

#Preview("Full Tree") {
    ZStack {
        Color(red: 0.5, green: 0.75, blue: 1).ignoresSafeArea()
        VStack { Spacer(); Color(red: 0.3, green: 0.55, blue: 0.2).frame(height: 120) }
        TreeView(growth: 1.0, health: 1.0)
            .frame(width: 300, height: 500)
    }
}

#Preview("Wilted") {
    ZStack {
        Color(red: 0.5, green: 0.75, blue: 1).ignoresSafeArea()
        VStack { Spacer(); Color(red: 0.3, green: 0.55, blue: 0.2).frame(height: 120) }
        TreeView(growth: 0.8, health: 0.2)
            .frame(width: 300, height: 500)
    }
}

#Preview("Round - Sprout") {
    ZStack {
        Color(red: 0.5, green: 0.75, blue: 1).ignoresSafeArea()
        VStack { Spacer(); Color(red: 0.3, green: 0.55, blue: 0.2).frame(height: 120) }
        TreeView(growth: 0.15, health: 1.0, species: .round)
            .frame(width: 300, height: 500)
    }
}

#Preview("Round - Young") {
    ZStack {
        Color(red: 0.5, green: 0.75, blue: 1).ignoresSafeArea()
        VStack { Spacer(); Color(red: 0.3, green: 0.55, blue: 0.2).frame(height: 120) }
        TreeView(growth: 0.45, health: 1.0, species: .round)
            .frame(width: 300, height: 500)
    }
}

#Preview("Round - Full") {
    ZStack {
        Color(red: 0.5, green: 0.75, blue: 1).ignoresSafeArea()
        VStack { Spacer(); Color(red: 0.3, green: 0.55, blue: 0.2).frame(height: 120) }
        TreeView(growth: 1.0, health: 1.0, species: .round)
            .frame(width: 300, height: 500)
    }
}
