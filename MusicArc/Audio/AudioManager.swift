import AVFoundation
import AudioToolbox

final class AudioManager {
    static let shared = AudioManager()

    private let engine = AVAudioEngine()
    private let players: [AVAudioPlayerNode]
    private let format: AVAudioFormat
    private let sampleRate: Double = 44100
    private let serialQueue = DispatchQueue(label: "com.musicarc.audio")
    private var nextPlayerIndex = 0
    private var sessionConfigured = false

    private init() {
        guard let fmt = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1) else {
            fatalError("Failed to create audio format")
        }
        format = fmt
        players = (0..<4).map { _ in AVAudioPlayerNode() }
        for player in players {
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
        }
    }

    // MARK: - Countdown (iOS system sounds — placeholder)

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
        guard let b1 = buildBuffer(frequencies: [523.25], duration: 0.12, volume: 0.25),
              let b2 = buildBuffer(frequencies: [659.25], duration: 0.12, volume: 0.25),
              let b3 = buildBuffer(frequencies: [783.99, 1046.5], duration: 0.3, volume: 0.25)
        else { return }
        ensureRunning()
        let player = checkoutPlayer()
        player.scheduleBuffer(b1, completionCallbackType: .dataPlayedBack) { _ in }
        player.scheduleBuffer(b2, completionCallbackType: .dataPlayedBack) { _ in }
        player.scheduleBuffer(b3, completionCallbackType: .dataPlayedBack) { _ in }
    }

    // MARK: - Tone Generation

    private func playTone(frequency: Double, duration: Double, volume: Float = 0.3) {
        playChord(frequencies: [frequency], duration: duration, volume: volume)
    }

    private func playChord(frequencies: [Double], duration: Double, volume: Float = 0.3) {
        guard let buffer = buildBuffer(frequencies: frequencies, duration: duration, volume: volume) else { return }
        ensureRunning()
        let player = checkoutPlayer()
        player.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { _ in }
    }

    private func buildBuffer(frequencies: [Double], duration: Double, volume: Float) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount

        guard let data = buffer.floatChannelData?[0] else { return nil }
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

        return buffer
    }

    private func checkoutPlayer() -> AVAudioPlayerNode {
        serialQueue.sync {
            let player = players[nextPlayerIndex]
            nextPlayerIndex = (nextPlayerIndex + 1) % players.count
            return player
        }
    }

    private func ensureRunning() {
        serialQueue.sync {
            if !sessionConfigured {
                try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
                try? AVAudioSession.sharedInstance().setActive(true)
                sessionConfigured = true
            }
            if !engine.isRunning {
                do {
                    try engine.start()
                    for player in players {
                        player.play()
                    }
                } catch {
                    // Audio is non-critical; subsequent calls will retry.
                }
            }
        }
    }
}
