import Foundation
import Combine

protocol PoseProvider: AnyObject {
    var armHeightPublisher: AnyPublisher<Double, Never> { get }
    func start()
    func stop()
}
