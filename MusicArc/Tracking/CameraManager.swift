import AVFoundation
import Combine

final class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    let framePublisher = PassthroughSubject<CVPixelBuffer, Never>()

    private let sessionQueue = DispatchQueue(label: "com.musicarc.camera")
    private let configLock = NSLock()
    private var isConfigured = false

    func configure() {
        configLock.lock()
        if isConfigured {
            configLock.unlock()
            return
        }
        isConfigured = true  // Claim the slot before dispatching to prevent a race.
        configLock.unlock()

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
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            session.commitConfiguration()
            // Couldn't configure — allow another attempt next time configure() is called.
            configLock.lock()
            isConfigured = false
            configLock.unlock()
            return
        }

        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.musicarc.videoOutput"))

        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            configLock.lock()
            isConfigured = false
            configLock.unlock()
            return
        }

        session.addOutput(output)

        if let connection = output.connection(with: .video) {
            connection.videoRotationAngle = 90
        }

        session.commitConfiguration()
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        framePublisher.send(pixelBuffer)
    }
}
