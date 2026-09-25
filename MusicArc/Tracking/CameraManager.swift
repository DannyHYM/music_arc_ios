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
            // videoRotationAngle is relative to the sensor's *native* orientation, which
            // differs between front-camera generations (classic landscape-mounted sensors vs.
            // the iPhone 17 square sensor, and the 2024 iPads whose default is already 180).
            // A hard-coded 90 only produced an upright buffer on the classic sensor; on other
            // hardware Vision received a rotated person and emitted jittery, wrong joints while
            // the preview layer (which rotates independently) still looked correct. Ask the
            // rotation coordinator for the device-specific upright angle instead.
            let defaultAngle = connection.videoRotationAngle
            let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: nil)
            let uprightAngle = coordinator.videoRotationAngleForHorizonLevelCapture
            if connection.isVideoRotationAngleSupported(uprightAngle) {
                connection.videoRotationAngle = uprightAngle
            } else if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }

            // SkeletonOverlayView flips X to line up Vision's coordinates with the mirrored
            // preview, so the buffers Vision analyzes must be unmirrored on every device rather
            // than left to the connection's device-dependent default.
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = false
            }

            NSLog("MusicArc camera: rotation default=%.0f applied=%.0f mirrored=%d",
                  defaultAngle, connection.videoRotationAngle, connection.isVideoMirrored ? 1 : 0)
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
