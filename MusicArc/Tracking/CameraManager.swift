import AVFoundation
import Combine

final class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    let framePublisher = PassthroughSubject<CMSampleBuffer, Never>()

    private let sessionQueue = DispatchQueue(label: "com.musicarc.camera")
    private var isConfigured = false

    func configure() {
        guard !isConfigured else { return }
        sessionQueue.async { [weak self] in
            self?.setupSession()
        }
    }

    func startRunning() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stopRunning() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .medium

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }

        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.musicarc.videoOutput"))

        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            return
        }

        session.addOutput(output)

        if let connection = output.connection(with: .video) {
            connection.videoRotationAngle = 90
        }

        session.commitConfiguration()
        isConfigured = true
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        framePublisher.send(sampleBuffer)
    }
}
