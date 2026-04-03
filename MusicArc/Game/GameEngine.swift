import Foundation
import Combine
import SwiftUI

enum GamePhase: Equatable {
    case countdown
    case active
    case rest
    case complete
}

@Observable
final class GameEngine {
    var reps: [Rep] = []
    var currentArmHeight: Double = 0.0
    var elapsedTime: TimeInterval = 0
    var isRunning = false
    var isFinished = false
    var isPaused = false
    var countdownValue: Int = 3
    var isInCountdown = true

    var currentPhase: GamePhase = .countdown
    var currentRepIndex: Int = 0
    var phaseTimeRemaining: TimeInterval = 0
    var treeGrowth: Double = 0.0
    var treeHealth: Double = 1.0
    var isRestingProperly: Bool = true
    var currentRepGrowth: Double = 0.0

    var phasePrompt: String? = nil
    var waterLevel: Double = 0.0
    var isInSunlightZone: Bool = false
    var growthSpurtCount: Int = 0

    let config: GameConfig
    let calibration: CalibrationData
    let scoreTracker = ScoreTracker()

    private var poseProvider: (any PoseProvider)?
    private var gameTimer: AnyCancellable?
    private var poseCancellable: AnyCancellable?
    private var startTime: Date?

    private let audio = AudioManager.shared
    private var countdownTimer: AnyCancellable?

    private var lastTickTime: Date?
    private var pausedAt: Date?
    private var currentRepRestAccumulator: TimeInterval = 0
    private var currentRepRestTotal: TimeInterval = 0
    private var lastGrowthMilestone: Int = 0
    private var growthSpurtAccumulator: Double = 0.0
    private var restBonusMultiplier: Double = 1.0
    private var phasePromptShowTime: Date?

    private(set) var touchProvider: TouchPoseProvider?

    init(config: GameConfig, calibration: CalibrationData) {
        self.config = config
        self.calibration = calibration
    }

    func start() {
        guard !isRunning else { return }

        reps = RepScheduler.generate(config: config)
        scoreTracker.reset()
        elapsedTime = 0
        isFinished = false
        countdownValue = 3
        isInCountdown = true
        currentPhase = .countdown
        currentRepIndex = 0
        treeGrowth = 0.0
        treeHealth = 1.0
        isRestingProperly = true
        currentRepGrowth = 0.0
        phasePrompt = nil
        waterLevel = 0.0
        isInSunlightZone = false
        growthSpurtCount = 0
        growthSpurtAccumulator = 0.0
        restBonusMultiplier = 1.0
        currentRepRestAccumulator = 0
        currentRepRestTotal = 0
        lastGrowthMilestone = 0
        phasePromptShowTime = nil
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
            provider = PoseDetector(trackingArm: config.trackingArm)
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
        lastTickTime = Date()

        currentPhase = .active
        audio.playDayTransition()
        showPhasePrompt("Raise the sun over the line!")

        gameTimer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func pause() {
        guard isRunning, !isPaused, !isFinished else { return }
        isPaused = true
        pausedAt = Date()
        gameTimer?.cancel()
        gameTimer = nil
        countdownTimer?.cancel()
        countdownTimer = nil
    }

    func resume() {
        guard isPaused, !isFinished else { return }
        if let pausedAt, let startTime {
            let pauseDuration = Date().timeIntervalSince(pausedAt)
            self.startTime = startTime.addingTimeInterval(pauseDuration)
            self.lastTickTime = Date()
        }
        pausedAt = nil
        isPaused = false

        if isInCountdown {
            startCountdown()
        } else {
            gameTimer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    self?.tick()
                }
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
        isPaused = false
    }

    func buildResult() -> GameResult {
        GameResult(
            date: .now,
            durationSeconds: config.totalSessionSeconds,
            totalReps: config.repCount,
            completedReps: scoreTracker.completedReps,
            treeGrowth: scoreTracker.growthPercentage,
            treeHealth: scoreTracker.treeHealth,
            avgRestCompliance: scoreTracker.averageRestCompliance,
            inputMode: config.inputMode
        )
    }

    // MARK: - Game Loop

    private func tick() {
        guard let startTime else { return }
        let now = Date()
        let dt = lastTickTime.map { now.timeIntervalSince($0) } ?? (1.0 / 30.0)
        lastTickTime = now
        elapsedTime = now.timeIntervalSince(startTime)

        if let showTime = phasePromptShowTime, now.timeIntervalSince(showTime) > 2.0 {
            phasePrompt = nil
            phasePromptShowTime = nil
        }

        guard currentRepIndex < reps.count else {
            finishSession()
            return
        }

        let rep = reps[currentRepIndex]

        if elapsedTime >= rep.activeStartTime && elapsedTime < rep.activeEndTime {
            if currentPhase != .active {
                restBonusMultiplier = 1.0 + 0.3 * waterLevel
                currentPhase = .active
                currentRepGrowth = 0.0
                growthSpurtAccumulator = 0.0
                audio.playDayTransition()
                showPhasePrompt(currentRepIndex == 0
                    ? "Raise the sun over the line!"
                    : "Raise the sun over the line!")
            }
            phaseTimeRemaining = rep.activeEndTime - elapsedTime
            updateGrowth(dt: dt)
        } else if elapsedTime >= rep.restStartTime && elapsedTime < rep.restEndTime {
            if currentPhase != .rest {
                currentPhase = .rest
                isInSunlightZone = false
                currentRepRestAccumulator = 0
                currentRepRestTotal = 0
                waterLevel = 0.0
                audio.playNightTransition()
                showPhasePrompt(currentRepIndex == 0
                    ? "Lower your hand \u{2014} let it rain!"
                    : "Rest & water your tree")
            }
            phaseTimeRemaining = rep.restEndTime - elapsedTime
            updateRest(dt: dt)
        } else if elapsedTime >= rep.restEndTime {
            applyRestBonus()
            finishCurrentRep()
            currentRepIndex += 1
            if currentRepIndex >= reps.count {
                finishSession()
            }
        }
    }

    private func updateGrowth(dt: TimeInterval) {
        let height = currentArmHeight
        isInSunlightZone = height >= config.sunlightThreshold
        guard isInSunlightZone else { return }

        let growthRate = (height - config.sunlightThreshold) / (1.0 - config.sunlightThreshold)
        let maxGrowthPerRep = 1.0 / Double(config.repCount)
        let increment = growthRate * maxGrowthPerRep * (dt / config.activeDuration) * restBonusMultiplier

        currentRepGrowth += increment
        scoreTracker.addGrowth(increment)
        treeGrowth = scoreTracker.growthPercentage

        growthSpurtAccumulator += increment
        let spurtThreshold = 1.0 / (Double(config.repCount) * 4.0)
        if growthSpurtAccumulator >= spurtThreshold {
            growthSpurtAccumulator -= spurtThreshold
            growthSpurtCount += 1
            audio.playGrowth()
        }

        let milestone = Int(treeGrowth * 10)
        if milestone > lastGrowthMilestone {
            lastGrowthMilestone = milestone
            audio.playMilestone()
        }
    }

    private func updateRest(dt: TimeInterval) {
        currentRepRestTotal += dt
        if currentArmHeight <= config.restThreshold {
            isRestingProperly = true
            currentRepRestAccumulator += dt
            waterLevel = min(1.0, currentRepRestAccumulator / config.restDuration)
        } else {
            isRestingProperly = false
            let penalty = 0.02 * dt
            scoreTracker.penalizeHealth(penalty)
            treeHealth = scoreTracker.treeHealth
        }
    }

    private func applyRestBonus() {
        guard currentRepRestTotal > 0 else { return }
        let compliance = currentRepRestAccumulator / currentRepRestTotal
        if compliance > 0.7 {
            let healthRestore = 0.05 * compliance
            scoreTracker.restoreHealth(healthRestore)
            treeHealth = scoreTracker.treeHealth
        }
    }

    private func showPhasePrompt(_ text: String) {
        phasePrompt = text
        phasePromptShowTime = Date()
    }

    private func finishCurrentRep() {
        let restCompliance: Double
        if currentRepRestTotal > 0 {
            restCompliance = currentRepRestAccumulator / currentRepRestTotal
        } else {
            restCompliance = 1.0
        }
        scoreTracker.finishRep(growth: currentRepGrowth, restCompliance: restCompliance)
        if currentRepIndex < reps.count {
            reps[currentRepIndex].growthEarned = currentRepGrowth
            reps[currentRepIndex].restCompliance = restCompliance
            reps[currentRepIndex].isComplete = true
        }
    }

    private func finishSession() {
        guard !isFinished else { return }
        if currentRepIndex < reps.count && !reps[currentRepIndex].isComplete {
            applyRestBonus()
            finishCurrentRep()
        }
        currentPhase = .complete
        isInSunlightZone = false
        audio.playTreeComplete()
        stop()
        isFinished = true
    }
}
