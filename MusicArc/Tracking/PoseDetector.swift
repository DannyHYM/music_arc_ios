import Vision
import AVFoundation
import Combine

final class PoseDetector: PoseProvider {
    var armHeightPublisher: AnyPublisher<Double, Never> {
        armHeightSubject.eraseToAnyPublisher()
    }

    private let armHeightSubject = PassthroughSubject<Double, Never>()
    private let cameraManager = CameraManager()
    private var cancellables = Set<AnyCancellable>()
    private let request = VNDetectHumanBodyPoseRequest()

    func start() {
        cameraManager.configure()

        cameraManager.framePublisher
            .receive(on: DispatchQueue(label: "com.musicarc.pose", qos: .userInteractive))
            .sink { [weak self] buffer in
                self?.processFrame(buffer)
            }
            .store(in: &cancellables)

        cameraManager.startRunning()
    }

    func stop() {
        cancellables.removeAll()
        cameraManager.stopRunning()
    }

    private func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])

        guard
            let observation = request.results?.first
        else { return }

        // Try right wrist first, fall back to right elbow
        let point: VNRecognizedPoint? = {
            if let wrist = try? observation.recognizedPoint(.rightWrist), wrist.confidence > 0.3 {
                return wrist
            }
            if let elbow = try? observation.recognizedPoint(.rightElbow), elbow.confidence > 0.3 {
                return elbow
            }
            return nil
        }()

        guard let tracked = point else { return }

        // Vision coordinates: (0,0) is bottom-left, y increases upward -- already normalized 0..1
        armHeightSubject.send(tracked.location.y)
    }
}
