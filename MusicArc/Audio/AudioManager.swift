import AVFoundation
import AudioToolbox

final class AudioManager {
    static let shared = AudioManager()

    private var audioEngine: AVAudioEngine?
    private var tonePlayer: AVAudioPlayerNode?

    private init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func playHit() {
        playTone(frequency: 880, duration: 0.15)
    }

    func playMiss() {
        playTone(frequency: 220, duration: 0.1)
    }

    func playCountdownTick() {
        AudioServicesPlaySystemSound(1104)
    }

    func playCountdownGo() {
        AudioServicesPlaySystemSound(1025)
    }

    func playSessionComplete() {
        playTone(frequency: 660, duration: 0.12)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.playTone(frequency: 880, duration: 0.12)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            self.playTone(frequency: 1100, duration: 0.2)
        }
    }

    private func playTone(frequency: Double, duration: Double) {
        let sampleRate: Double = 44100
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }

        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let data = buffer.floatChannelData![0]
        let angularFreq = 2.0 * Double.pi * frequency / sampleRate

        for i in 0..<Int(frameCount) {
            let t = Double(i)
            let envelope: Double
            let attackSamples = min(Double(frameCount) * 0.1, 200)
            let releaseSamples = min(Double(frameCount) * 0.3, 600)

            if t < attackSamples {
                envelope = t / attackSamples
            } else if t > Double(frameCount) - releaseSamples {
                envelope = (Double(frameCount) - t) / releaseSamples
            } else {
                envelope = 1.0
            }

            data[i] = Float(sin(angularFreq * t) * envelope * 0.3)
        }

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
            player.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { _ in
                engine.stop()
            }
            player.play()
        } catch {
            // Silently fail -- audio is non-critical
        }
    }
}
