import SwiftUI

protocol TreeRenderer {
    func draw(in context: GraphicsContext, size: CGSize, growth: Double, health: Double)
}
