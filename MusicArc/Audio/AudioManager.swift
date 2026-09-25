import AVFoundation
import AudioToolbox

/// Every piece of audio work — session activation, engine start-up, buffer synthesis,
/// scheduling, and even the system-sound countdown ticks — runs on `audioQueue`.
///
/// `AVAudioSession.setActive`, `AVAudioEngine.start()`, and the first `AudioServicesPlaySystemSound`
/// are blocking calls that take hundreds of milliseconds (seconds on Bluetooth routes). They used to
/// run synchronously on the main thread from inside the game tick, which froze the UI (countdown
/// stuck, tree not moving) while the camera preview — rendered by the capture pipeline, not the
/// main thread — kept moving. Nothing here may block the caller.
final class AudioManager {
    static let shared = AudioManager()

    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private let format: AVAudioFormat
    private let sampleRate: Double = 44100
    private let audioQueue = DispatchQueue(label: "com.musicarc.audio", qos: .userInitiated)
    private var nextPlayerIndex = 0
    private var isGraphBuilt = false
    private var isSessionConfigured = false

    private init() {
        guard let fmt = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1) else {
            fatalError("Failed to create audio format")
        }
        format = fmt
        // Deliberately no engine-graph work here: `shared` is first touched on the main thread
        // (GameEngine.init) and instantiating the output unit is not cheap. See ensureRunningLocked.
    }

    /// Warms up the audio session and engine in the background. Safe to call repeatedly.
    /// Call it well before the first tone (app launch, session start) so the first in-game
    /// sound doesn't pay the hardware start-up cost at the worst possible moment.
    func prepare() {
        audioQueue.async { self.ensureRunningLocked() }
    }

    // MARK: - Countdown (iOS system sounds — placeholder)

    func playCountdownTick() {
        audioQueue.async { AudioServicesPlaySystemSound(1104) }
    }

    func playCountdownGo() {
        audioQueue.async { AudioServicesPlaySystemSound(1025) }
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
        audioQueue.async {
            guard self.ensureRunningLocked(),
                  let b1 = self.buildBuffer(frequencies: [523.25], duration: 0.12, volume: 0.25),
                  let b2 = self.buildBuffer(frequencies: [659.25], duration: 0.12, volume: 0.25),
                  let b3 = self.buildBuffer(frequencies: [783.99, 1046.5], duration: 0.3, volume: 0.25)
            else { return }
            let player = self.checkoutPlayerLocked()
            player.scheduleBuffer(b1, completionCallbackType: .dataPlayedBack) { _ in }
            player.scheduleBuffer(b2, completionCallbackType: .dataPlayedBack) { _ in }
            player.scheduleBuffer(b3, completionCallbackType: .dataPlayedBack) { _ in }
        }
    }

    // MARK: - Tone Generation

    private func playTone(frequency: Double, duration: Double, volume: Float = 0.3) {
        playChord(frequencies: [frequency], duration: duration, volume: volume)
    }

    private func playChord(frequencies: [Double], duration: Double, volume: Float = 0.3) {
        audioQueue.async {
            guard self.ensureRunningLocked(),
                  let buffer = self.buildBuffer(frequencies: frequencies, duration: duration, volume: volume)
            else { return }
            self.checkoutPlayerLocked()
                .scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { _ in }
        }
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

    // MARK: - Engine lifecycle (audioQueue only)

    /// Must be called on `audioQueue`, after `ensureRunningLocked()` returned true.
    private func checkoutPlayerLocked() -> AVAudioPlayerNode {
        let player = players[nextPlayerIndex]
        nextPlayerIndex = (nextPlayerIndex + 1) % players.count
        return player
    }

    /// Must be called on `audioQueue`. Builds the graph, activates the session and starts the
    /// engine on first use, and restarts the engine after an interruption or route change.
    /// Returns false when the engine couldn't be started; the caller drops that sound and the
    /// next call retries. Audio is non-critical, so failures never surface to the game.
    @discardableResult
    private func ensureRunningLocked() -> Bool {
        if !isGraphBuilt {
            players = (0..<4).map { _ in AVAudioPlayerNode() }
            for player in players {
                engine.attach(player)
                engine.connect(player, to: engine.mainMixerNode, format: format)
            }
            isGraphBuilt = true
        }

        if !isSessionConfigured {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
                try AVAudioSession.sharedInstance().setActive(true)
                isSessionConfigured = true
            } catch {
                // Leave the flag false so the next call retries.
            }
        }

        if !engine.isRunning {
            do {
                try engine.start()
                for player in players {
                    player.play()
                }
            } catch {
                return false
            }
        }
        return true
    }
}
