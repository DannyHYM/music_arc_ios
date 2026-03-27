import AVFoundation
import AudioToolbox

final class AudioManager {
    static let shared = AudioManager()

    private init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    // MARK: - Countdown (unchanged)

    func playCountdownTick() {
        AudioServicesPlaySystemSound(1104)
    }

    func playCountdownGo() {
        AudioServicesPlaySystemSound(1025)
    }

    // MARK: - Growth

    func playGrowth() {
        playChord(frequencies: [523.25, 659.25], duration: 0.12, volume: 0.15)
    }

    func playMilestone() {
        playChord(frequencies: [523.25, 659.25, 783.99], duration: 0.35, volume: 0.25)
    }

    // MARK: - Day/Night Transitions

    func playDayTransition() {
        playChord(frequencies: [440, 554.37, 659.25], duration: 0.25, volume: 0.15)
    }

    func playNightTransition() {
        playTone(frequency: 330, duration: 0.3, volume: 0.12)
    }

    // MARK: - Session Complete

    func playTreeComplete() {
        playTone(frequency: 523.25, duration: 0.12, volume: 0.25)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.playTone(frequency: 659.25, duration: 0.12, volume: 0.25)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            self.playChord(frequencies: [783.99, 1046.5], duration: 0.3, volume: 0.25)
        }
    }

    // MARK: - Tone Generation

    private func playTone(frequency: Double, duration: Double, volume: Float = 0.3) {
        playChord(frequencies: [frequency], duration: duration, volume: volume)
    }

    private func playChord(frequencies: [Double], duration: Double, volume: Float = 0.3) {
        let sampleRate: Double = 44100
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let data = buffer.floatChannelData![0]
        let amplitude = volume / Float(frequencies.count)

        for i in 0..<Int(frameCount) {
            let t = Double(i)
            let attackSamples = min(Double(frameCount) * 0.1, 200)
            let releaseSamples = min(Double(frameCount) * 0.4, 800)

            let envelope: Double
            if t < attackSamples {
                envelope = t / attackSamples
            } else if t > Double(frameCount) - releaseSamples {
                envelope = (Double(frameCount) - t) / releaseSamples
            } else {
                envelope = 1.0
            }

            var sample: Float = 0
            for freq in frequencies {
                let angularFreq = 2.0 * Double.pi * freq / sampleRate
                sample += Float(sin(angularFreq * t) * envelope) * amplitude
            }
            data[i] = sample
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
            // Audio is non-critical
        }
    }
}
