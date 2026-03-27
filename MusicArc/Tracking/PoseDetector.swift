import Vision
import AVFoundation
import Combine

final class PoseDetector: PoseProvider {
    var armHeightPublisher: AnyPublisher<Double, Never> {
        armHeightSubject.eraseToAnyPublisher()
    }

    var armPosePublisher: AnyPublisher<ArmPose, Never>? {
        armPoseSubject.eraseToAnyPublisher()
    }

    var captureSession: AVCaptureSession { cameraManager.session }

    let cameraManager = CameraManager()

    private let armHeightSubject = PassthroughSubject<Double, Never>()
    private let armPoseSubject = PassthroughSubject<ArmPose, Never>()
    private var cancellables = Set<AnyCancellable>()
    private let request = VNDetectHumanBodyPoseRequest()
    private let minConfidence: Float = 0.3

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

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        try? handler.perform([request])

        guard let observation = request.results?.first else {
            armPoseSubject.send(ArmPose(
                shoulder: nil, elbow: nil, wrist: nil,
                normalizedHeight: 0.5, isTracking: false
            ))
            return
        }

        let shoulder = try? observation.recognizedPoint(.rightShoulder)
        let elbow = try? observation.recognizedPoint(.rightElbow)
        let wrist = try? observation.recognizedPoint(.rightWrist)

        let shoulderPt = (shoulder?.confidence ?? 0) > minConfidence ? shoulder?.location : nil
        let elbowPt = (elbow?.confidence ?? 0) > minConfidence ? elbow?.location : nil
        let wristPt = (wrist?.confidence ?? 0) > minConfidence ? wrist?.location : nil

        let height: Double
        let tracking: Bool

        if let s = shoulderPt, let e = elbowPt, let w = wristPt {
            height = relativeArmHeight(shoulder: s, elbow: e, wrist: w)
            tracking = true
        } else if let s = shoulderPt, let w = wristPt {
            let dist = hypot(w.x - s.x, w.y - s.y)
            let verticalExt = w.y - s.y
            height = dist > 0.01 ? (verticalExt / dist + 1.0) / 2.0 : 0.5
            tracking = true
        } else if let s = shoulderPt, let e = elbowPt {
            let dist = hypot(e.x - s.x, e.y - s.y)
            let verticalExt = e.y - s.y
            height = dist > 0.01 ? (verticalExt / dist + 1.0) / 2.0 : 0.5
            tracking = true
        } else {
            height = 0.5
            tracking = false
        }

        let pose = ArmPose(
            shoulder: shoulderPt, elbow: elbowPt, wrist: wristPt,
            normalizedHeight: min(1.0, max(0.0, height)),
            isTracking: tracking
        )

        armPoseSubject.send(pose)
        armHeightSubject.send(pose.normalizedHeight)
    }

    /// Arm height from the full shoulder-elbow-wrist chain.
    /// Returns 0 (arm fully down) to 1 (arm fully raised above head).
    private func relativeArmHeight(shoulder: CGPoint, elbow: CGPoint, wrist: CGPoint) -> Double {
        let upperArm = hypot(elbow.x - shoulder.x, elbow.y - shoulder.y)
        let forearm = hypot(wrist.x - elbow.x, wrist.y - elbow.y)
        let armLength = upperArm + forearm

        guard armLength > 0.01 else { return 0.5 }

        let verticalExtension = wrist.y - shoulder.y
        let ratio = verticalExtension / armLength
        return (ratio + 1.0) / 2.0
    }
}
