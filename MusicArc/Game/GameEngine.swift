import Foundation
import Combine
import SwiftUI

@Observable
final class GameEngine {
    // Published game state
    var notes: [GameNote] = []
    var currentArmHeight: Double = 0.5
    var elapsedTime: TimeInterval = 0
    var isRunning = false
    var isFinished = false
    var lastHitNoteID: UUID?
    var lastMissNoteID: UUID?
    var countdownValue: Int = 3

    let config: GameConfig
    let calibration: CalibrationData
    let scoreTracker = ScoreTracker()

    private var poseProvider: (any PoseProvider)?
    private var gameTimer: AnyCancellable?
    private var poseCancellable: AnyCancellable?
    private var startTime: Date?

    private let hitWindowDuration: TimeInterval = 0.8
    private let audio = AudioManager.shared
    private var countdownTimer: AnyCancellable?
    var isInCountdown = true

    init(config: GameConfig, calibration: CalibrationData) {
        self.config = config
        self.calibration = calibration
    }

    func start() {
        guard !isRunning else { return }

        notes = NoteScheduler.generate(config: config)
        scoreTracker.reset()
        elapsedTime = 0
        isFinished = false
        lastHitNoteID = nil
        lastMissNoteID = nil
        countdownValue = 3
        isInCountdown = true
        isRunning = true

        startCountdown()
    }

    private func startCountdown() {
        audio.playCountdownTick()
        countdownTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.countdownValue -= 1
                if self.countdownValue > 0 {
                    self.audio.playCountdownTick()
                } else {
                    self.audio.playCountdownGo()
                    self.countdownTimer?.cancel()
                    self.countdownTimer = nil
                    self.isInCountdown = false
                    self.beginGameplay()
                }
            }
    }

    private(set) var touchProvider: TouchPoseProvider?

    private func beginGameplay() {
        let provider: any PoseProvider
        switch config.inputMode {
        case .demo:
            provider = DemoPoseProvider()
        case .touch:
            let tp = TouchPoseProvider()
            self.touchProvider = tp
            provider = tp
        case .camera:
            provider = PoseDetector()
        }
        self.poseProvider = provider

        poseCancellable = provider.armHeightPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rawHeight in
                guard let self else { return }
                self.currentArmHeight = self.calibration.normalize(rawHeight)
            }

        provider.start()
        startTime = Date()

        gameTimer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func stop() {
        gameTimer?.cancel()
        gameTimer = nil
        countdownTimer?.cancel()
        countdownTimer = nil
        poseCancellable?.cancel()
        poseCancellable = nil
        poseProvider?.stop()
        poseProvider = nil
        isRunning = false
    }

    func buildResult() -> GameResult {
        GameResult(
            date: .now,
            durationSeconds: config.durationSeconds,
            totalNotes: notes.count,
            hits: scoreTracker.hits,
            misses: scoreTracker.misses,
            maxStreak: scoreTracker.maxStreak,
            inputMode: config.inputMode
        )
    }

    // MARK: - Game Loop

    private func tick() {
        guard let startTime else { return }
        elapsedTime = Date().timeIntervalSince(startTime)

        judgeNotes()

        if elapsedTime >= TimeInterval(config.durationSeconds) {
            judgeMissedRemaining()
            audio.playSessionComplete()
            stop()
            isFinished = true
        }
    }

    private func judgeNotes() {
        for i in notes.indices {
            guard !notes[i].wasJudged else { continue }

            let noteTime = notes[i].scheduledTime
            let windowStart = noteTime
            let windowEnd = noteTime + hitWindowDuration

            guard elapsedTime >= windowStart else { continue }

            if elapsedTime <= windowEnd {
                let distance = abs(currentArmHeight - notes[i].targetHeight)
                if distance <= config.hitTolerance {
                    notes[i].wasJudged = true
                    notes[i].wasHit = true
                    notes[i].hitTime = elapsedTime
                    scoreTracker.recordHit()
                    audio.playHit()
                    lastHitNoteID = notes[i].id
                }
            } else {
                notes[i].wasJudged = true
                notes[i].wasHit = false
                scoreTracker.recordMiss()
                audio.playMiss()
                lastMissNoteID = notes[i].id
            }
        }
    }

    private func judgeMissedRemaining() {
        for i in notes.indices where !notes[i].wasJudged {
            notes[i].wasJudged = true
            notes[i].wasHit = false
            scoreTracker.recordMiss()
        }
    }
}
