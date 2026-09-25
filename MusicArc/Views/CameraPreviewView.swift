import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.videoGravity = .resizeAspectFill
        attach(session, to: view.previewLayer)
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        if uiView.previewLayer.session !== session {
            attach(session, to: uiView.previewLayer)
        }
    }

    /// Attaching a session takes the session's internal lock. On the main thread that means
    /// waiting out whatever startRunning()/configuration is in progress on the session queue —
    /// a lengthy operation when the data output physically rotates buffers — so the UI froze
    /// at the exact moment the preview appeared. CALayer properties are thread-safe, so do the
    /// attach off the main thread and let the layer pick the session up whenever it's ready.
    private func attach(_ session: AVCaptureSession, to layer: AVCaptureVideoPreviewLayer) {
        DispatchQueue.global(qos: .userInitiated).async {
            layer.session = session
        }
    }

    class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

/// Draws shoulder-elbow-wrist joints and connecting lines over the camera feed.
/// Vision coordinates are (0,0) bottom-left with y-up; front camera preview is mirrored,
/// so X is flipped to align the overlay with what the user sees.
struct SkeletonOverlayView: View {
    let pose: ArmPose

    var body: some View {
        Canvas { context, size in
            let joints: [(CGPoint, Bool)] = [
                (pose.shoulder, false),
                (pose.elbow, false),
                (pose.wrist, true)
            ].compactMap { pt, isEnd -> (CGPoint, Bool)? in
                guard let pt else { return nil }
                let viewPt = CGPoint(
                    x: (1.0 - pt.x) * size.width,
                    y: (1.0 - pt.y) * size.height
                )
                return (viewPt, isEnd)
            }

            if joints.count >= 2 {
                var path = Path()
                path.move(to: joints[0].0)
                for i in 1..<joints.count {
                    path.addLine(to: joints[i].0)
                }
                context.stroke(path, with: .color(.green.opacity(0.9)), lineWidth: 4)
            }

            for (point, isEndpoint) in joints {
                let radius: CGFloat = isEndpoint ? 14 : 10
                let color: Color = isEndpoint ? .yellow : .green
                let rect = CGRect(
                    x: point.x - radius, y: point.y - radius,
                    width: radius * 2, height: radius * 2
                )
                context.fill(Circle().path(in: rect), with: .color(color))
                context.stroke(
                    Circle().path(in: rect),
                    with: .color(.white.opacity(0.8)),
                    lineWidth: 2
                )
            }
        }
        .allowsHitTesting(false)
    }
}
