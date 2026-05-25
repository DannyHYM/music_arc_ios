# MusicArc Forest — Code Review

Reviewer: Claude (Opus 4.7, 1M context)
Date: 2026-05-22
Scope: full repo (`MusicArc/**/*.swift`, `project.yml`, `MusicArcApp.swift`, etc.), ≈5,250 LOC

This review reads the codebase as a clinical-grade rehab prototype that will eventually be used by real burn-recovery patients (per `INVENTION_DISCLOSURE.md`). That framing raises the bar on correctness, accessibility, and graceful failure beyond what a typical iOS prototype would require. Issues are ordered by severity, not by file. Each finding cites a file and line range and ends with a concrete action.

---

## Executive summary

The project is well-structured for its size: a clean `PoseProvider` protocol with three interchangeable implementations, a `TreeRenderer` protocol with five species, a single `GameEngine` as the source of truth, and zero third-party dependencies. The state machine in `GameEngine` is straightforward to follow and the procedural rendering / audio pipeline is impressive.

However, there are a handful of issues that would surface immediately in a real clinical pilot:

1. **Calibration can silently produce an unusable session.** A patient who fails to move during one of the calibration phases proceeds to a game where their arm height is permanently stuck at 0.5 — they cannot grow the tree, and nothing tells them why.
2. **Pose detection can re-emit stale results indefinitely** if a single Vision request throws.
3. **`AudioManager` allocates a fresh `AVAudioEngine` per sound** (potentially dozens per session), which is wasteful and can cause audio glitches.
4. **In camera mode there is no live preview during gameplay** — the patient gets no feedback that the camera is still tracking them.
5. **Backgrounding the app silently skips reps** (timer keeps `elapsedTime` based on wall-clock).
6. **`DemoPoseProvider` is hard-coded to the default 4s/3s phase pacing** and desyncs if the patient customizes durations.

There is also no test target, no accessibility/Dynamic-Type support, no camera-permission gating, and significant code duplication across the five renderers. Detail below.

---

## 1. Critical issues (correctness / data integrity / clinical safety)

### 1.1 Calibration accepts a degenerate range silently
**File:** `MusicArc/Views/CalibrationView.swift:316-324`, `MusicArc/Models/CalibrationData.swift:7-11`

`finishCalibration()` builds `CalibrationData(minHeight: recordedMin - padding, maxHeight: recordedMax + padding)` without validating that the patient actually moved. `recordedMin` is initialized to `1.0` and `recordedMax` to `0.0`; if the patient stands still during either phase, the resulting `CalibrationData` has `minHeight > maxHeight`. `CalibrationData.normalize` then hits its `guard maxHeight > minHeight` branch and returns `0.5` for every raw reading — the patient is locked at mid-height for the entire session and can never reach the sunlight threshold (default 0.7). There is no warning shown.

For a clinical rehab app this is a worst-case failure: the patient performs their session, sees no growth, blames themselves, and may abandon the app.

**Action:** In `finishCalibration`, require `recordedMax - recordedMin ≥ ~0.15` (a meaningful range). If the gap is too small, surface an error and force the user back to `restartCalibration()`. Show what's wrong (e.g., "We didn't see your arm move enough — try again, raising as high as you can").

### 1.2 `PoseDetector` re-emits stale Vision results on failure
**File:** `MusicArc/Tracking/PoseDetector.swift:57-67`

```swift
let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
try? handler.perform([request])
guard let observation = request.results?.first else { … }
```

`request` is a long-lived `VNDetectHumanBodyPoseRequest` instance. When `perform` throws, `try?` swallows the error and `request.results` still holds the previous frame's observation. The code then happily forwards that stale pose as if it were fresh. For intermittent failures the patient sees a "frozen" arm that doesn't react to their movement.

**Action:** Either (a) create a new request per frame, (b) clear `request.results` on failure, or (c) capture the throw and emit an `isTracking: false` ArmPose explicitly.

### 1.3 `DemoPoseProvider` is hard-coded to the default phase durations
**File:** `MusicArc/Tracking/DemoPoseProvider.swift:32-34`

```swift
let activeDuration = 4.0
let restDuration = 3.0
```

These constants duplicate `GameConfig` defaults. If a clinician customizes the session (HomeView allows 2…20s active / 2…30s rest), demo mode keeps its 4/3 cycle while `GameEngine` advances through the configured phases — demo arm goes "down" during what `GameEngine` thinks is still the active phase, and vice versa. Demo runs look broken on any non-default config.

**Action:** Inject `(activeDuration:restDuration:)` via initializer (or pass `GameConfig`) and use those in `syntheticHeight`.

### 1.4 `AudioManager.playChord` creates a new `AVAudioEngine` for every sound
**File:** `MusicArc/Audio/AudioManager.swift:97-111`

Each call to `playGrowth()`, `playMilestone()`, `playDayTransition()`, etc., instantiates a fresh `AVAudioEngine`, attaches a player, starts the engine, schedules a buffer, and `engine.stop()`s in the completion. In a default 8-rep session, `playGrowth` fires up to ~32 times (4 spurts per rep) plus 10 milestones plus phase-transition sounds — well over 50 engine setup/teardown cycles per session. Engine startup is expensive on iOS, can produce audible clicks, and risks the player not being ready when `scheduleBuffer` runs.

**Action:** Maintain one long-lived `AVAudioEngine` plus a small pool of `AVAudioPlayerNode`s (or a single node with multiple `scheduleBuffer` calls). Start the engine once in `init`, never stop it during a session.

### 1.5 `CameraManager.isConfigured` race condition
**File:** `MusicArc/Tracking/CameraManager.swift:11-15, 62-64`

`isConfigured` is read on the caller's thread (the guard in `configure()`) but only written on `sessionQueue` (after `setupSession` completes). Two near-simultaneous `configure()` calls can both pass the guard before the queue runs `setupSession`, causing the session to be configured twice (which then logs an error and may produce a broken capture pipeline). The only thing preventing this today is that `configure()` happens to be called from a single site (`PoseDetector.start`).

**Action:** Either set `isConfigured = true` synchronously before dispatching, or guard via `sessionQueue.sync`, or use a single `DispatchOnce`-style token.

### 1.6 Game timer survives app backgrounding but `elapsedTime` does not
**File:** `MusicArc/Game/GameEngine.swift:210-264`

`GameEngine.tick()` reads `elapsedTime = Date().timeIntervalSince(startTime)`. When the app moves to background, the timer stops firing but wall-clock keeps advancing. On return, the next `tick()` may compute an `elapsedTime` that has jumped multiple phases past the current one — the patient's reps complete with `currentRepGrowth == 0`, no phase transitions or audio fire, and `scoreTracker` records zero growth for whatever reps were missed.

**Action:** Observe `@Environment(\.scenePhase)` in `GameView` and call `engine.pause()` / `engine.resume()` on background/active transitions. Optionally abort the session if the background period exceeds a threshold.

---

## 2. Important issues (broken UX, resource leaks, wrong assumptions)

### 2.1 No camera preview during gameplay in camera mode
**File:** `MusicArc/Views/GameView.swift:13-86`

`GameView` only renders `TreeGrowthView` — no `CameraPreviewView`, no `SkeletonOverlayView`, no tracking-status badge. A burn patient using camera input has no visual confirmation that they are framed correctly or that the system is currently tracking them. If they drift out of frame mid-session the tree just stops growing with no explanation.

`GameEngine.poseProvider` is `private`, so `GameView` can't easily reach the `PoseDetector.captureSession` or `armPosePublisher` either.

**Action:** Expose the pose provider (or at least the capture session + pose publisher) from `GameEngine` in camera mode. In `GameView`, overlay a small picture-in-picture camera preview + skeleton in a corner, plus the same "Tracking your arm" badge from `CalibrationView`.

### 2.2 `pause()` leaves the camera and pose pipeline running
**File:** `MusicArc/Game/GameEngine.swift:150-158`

`pause()` cancels `gameTimer` and `countdownTimer` but does not stop `poseProvider`. The camera stays running and Vision keeps inferring poses on every frame — significant battery drain on a paused screen. Also: `currentArmHeight` keeps mutating via the Combine subscription, so a patient who pauses and moves their arm will resume at a fresh height that the engine then reacts to immediately.

**Action:** Call `poseProvider?.stop()` in `pause()` and `start()` in `resume()`. Add `pause()` / `resume()` to the `PoseProvider` protocol so providers can implement this efficiently (e.g., a touch provider doesn't need camera teardown).

### 2.3 `TouchPoseProvider`'s 30 Hz timer is dead weight
**File:** `MusicArc/Tracking/TouchPoseProvider.swift:12-19`

The timer re-publishes `armHeightSubject.value` 30 times per second even when nothing has changed. `updateHeight(_:)` already publishes on every gesture change, and `GameEngine` reads its own `currentArmHeight` from the subscription, not by polling.

**Action:** Delete the timer. `armHeightSubject` is already a `CurrentValueSubject`; subscribers get the latest value automatically.

### 2.4 `SkyView` re-randomizes stars on every render
**File:** `MusicArc/Views/SkyView.swift:199-206`

```swift
ForEach(0..<20, id: \.self) { i in
    let starX = CGFloat.random(in: 0...1)
    let starY = CGFloat.random(in: 0...0.5)
    Circle().fill(Color.white.opacity(Double.random(in: 0.3...0.8)))
        .frame(width: CGFloat.random(in: 1.5...3.5), height: CGFloat.random(in: 1.5...3.5))
        .position(x: w * starX, y: h * starY)
}
```

`nightElements(in:)` is called inside `body`, which re-runs whenever any of SkyView's props (`handHeight`, `waterLevel`, etc.) change — up to 30 times per second during rest. The stars flicker chaotically.

**Action:** Compute the star positions once with a fixed seed (or `@State private var stars: [Star]` initialized in `.onAppear`) and reuse.

### 2.5 `SessionSummaryView.saveSession` silently swallows save errors
**File:** `MusicArc/Views/SessionSummaryView.swift:164-179`

```swift
modelContext.insert(session)
try? modelContext.save()
isSaved = true
```

If the SwiftData save fails (disk full, schema mismatch, …), the UI says "Planted!" but no data was persisted. The patient's session is lost without any indication.

**Action:** `do/catch` and surface the error (an alert or banner) before flipping `isSaved`.

### 2.6 `SessionHistoryView.exportAllSessions` silently fails
**File:** `MusicArc/Views/SessionHistoryView.swift:209-218`

Both `try? encoder.encode(...)` and `try? data.write(to:)` swallow errors, but `exportURL` and `showingExportSheet` are set unconditionally afterward. If the encode succeeds but the write fails (e.g., out of disk), the share sheet opens with a URL pointing to a non-existent file. If the encode fails, `exportData` is never written and the share sheet still opens (the sheet body guards `exportURL != nil` — but the `URL` variable holds a stale value from a previous export).

**Action:** Use `do/catch`, only set `exportURL` and `showingExportSheet = true` after a successful write, and reset `exportURL` to nil on the share sheet's `onDismiss` (also clean up the temp file).

### 2.7 `HomeView` always pushes calibration, even for touch/demo
**File:** `MusicArc/Views/HomeView.swift:217-241`, `CalibrationView.swift:97-113, 311-314`

The start button always appends `.calibration(config)`. For non-camera modes, `CalibrationView` shows an intro screen with a "Continue" button that immediately calls `skipCalibration()` → `.game(...)`. This is a dead screen tap.

**Action:** In `HomeView.startButton`, branch on `effectiveMode`: push `.calibration` only when `effectiveMode == .camera`, otherwise push `.game` directly with a default `CalibrationData(minHeight: 0, maxHeight: 1)`.

### 2.8 Demo arm-height is still passed through `CalibrationData.normalize`
**File:** `MusicArc/Game/GameEngine.swift:128-133`

`DemoPoseProvider` emits values in the conceptual range [0, 1] (already "calibrated"). They are then normalized through `calibration.normalize(rawHeight)`. If a real calibration somehow ran (which it doesn't for demo today, but could) the demo wave would be distorted. More immediately: `skipCalibration` sets `CalibrationData(minHeight: 0, maxHeight: 1)`, so the identity normalization is fine — but the coupling is fragile.

**Action:** In `GameEngine`, skip normalization when `config.inputMode == .demo` (or wrap demo's output in `CalibrationData(0, 1)` explicitly to make the contract clear).

### 2.9 Calibration phases have no settle/transition pause
**File:** `MusicArc/Views/CalibrationView.swift:280-294`

`beginRaisePhase` immediately starts a 4-second timer; when it expires, `beginLowerPhase` fires with no pause. The patient cannot lower their arm in time, and the first ~1 second of the "lower" phase will record their still-raised arm as the new `recordedMin` (since `min(recordedMin, height)` — the initial 1.0 ratchets down to that "raised" height before they get their arm down). Result: `recordedMin` ends up higher than it should, narrowing the usable range.

**Action:** Insert a "Get ready to lower your arm" countdown (1.5–2s) between phases. Also: only start sampling for `recordedMin` after a small grace period (e.g., 0.5s) into the lower phase.

### 2.10 `PoseDetector` orientation may be wrong
**File:** `MusicArc/Tracking/PoseDetector.swift:58`, `MusicArc/Tracking/CameraManager.swift:58-60`

Vision is told `orientation: .up` but the capture connection has `videoRotationAngle = 90`. For a portrait-locked app reading the front camera, Vision's expected orientation is typically `.right` (or `.leftMirrored`, depending on how you handle mirroring). With the current setup, the y-axis convention used in `relativeArmHeight` (`wrist.y - shoulder.y`) may not point the direction the code assumes — this could mean arm-up gives lower values than arm-down, and the team has been compensating with calibration.

**Action:** On device, log raw `wrist.y` and `shoulder.y` for arm-up vs. arm-down and verify. Pass the correct `CGImagePropertyOrientation` based on device orientation, or remove the `videoRotationAngle` override and stick with Vision's expected `.right`.

### 2.11 No camera permission gating
**File:** `MusicArc/Tracking/CameraManager.swift:32-63`

`setupSession` calls `AVCaptureDevice.default(...)` without first checking `AVCaptureDevice.authorizationStatus(for: .video)` or requesting access. On first launch the system prompt fires asynchronously when the camera is first accessed; meanwhile `session.addInput` may silently fail (the guard at line 39 falls through to a no-op `commitConfiguration`), and the user sees a black screen with no error.

**Action:** Before starting calibration in camera mode, explicitly request authorization with `AVCaptureDevice.requestAccess(for: .video)`. If denied or restricted, show an actionable screen ("Camera access is required for pose tracking — open Settings") and fall back to touch mode.

### 2.12 `GameView.Restart` does not reset `TreeGrowthView` animation state
**File:** `MusicArc/Views/GameView.swift:286-294`, `TreeGrowthView.swift:16`

The pause-menu "Restart" creates a new `GameEngine` and assigns it to `@State engine`. SwiftUI reuses the same `TreeGrowthView` instance because the identity didn't change — but `TreeGrowthView`'s `@State private var treeScale` and any in-flight animations carry over. Visually, the tree may "pop" or briefly retain the previous growth animation on restart.

**Action:** Give the `TreeGrowthView` an `.id(engine.sessionId)` so SwiftUI rebuilds it fresh on restart.

---

## 3. Architecture / code quality

### 3.1 Significant code duplication across the five tree renderers
**Files:** `MusicArc/Rendering/{Oak,Round,Bushy,Pine,Acacia}TreeRenderer.swift`

Every renderer has its own private `drawSoilMound`, `drawSprout`, and roughly the same growth-stage dispatch logic. Bodies differ only in colors and a few magic numbers. ~5,250 LOC total, of which the rendering layer is ~1,610; a meaningful chunk of that is duplicated boilerplate.

**Action:** Extract shared helpers into a `TreeRenderer` protocol extension parameterized by `colors: TreeColors` (where `TreeColors` is a small struct with `trunk`, `sprout`, `foliage*` fields). The `draw(...)` dispatch (soil → sprout → tree) is the same across all five renderers and can live on the protocol.

### 3.2 `TreeSpecies.renderer` allocates a fresh renderer per access
**File:** `MusicArc/Models/TreeSpecies.swift:20-28`

Each `species.renderer` returns `OakTreeRenderer()` etc. — a new instance per call. `TreeView.body` (TreeView.swift:9-11) accesses `species.renderer` inside the Canvas closure, which runs on every redraw. With the tree growing at 30 Hz, that's 30 renderer allocations per second per visible tree. Renderers are stateless structs so this is cheap, but pointless.

**Action:** Make the renderers a singleton: e.g., `private static let oak = OakTreeRenderer()` … and switch to those instances.

### 3.3 Clinical constants are scattered through `GameEngine`
**File:** `MusicArc/Game/GameEngine.swift` (multiple)

Magic numbers that are clinical knobs:
- `0.7` rest-compliance threshold (line 312)
- `0.05` health-restore amount (line 313)
- `0.02` per-dt health penalty (line 303)
- `0.3` rest-bonus multiplier scale (line 231)
- `1.0 / 4.0` spurt threshold (line 281)
- 30 Hz tick rate (lines 143, 173)

These are exactly the kinds of values a clinician will eventually want to tune. They are currently inaccessible without editing the engine.

**Action:** Move them into `GameConfig` (or a new `ScoringConfig` struct) with sensible defaults preserved. Document each in a brief comment.

### 3.4 `GameEngine.beginGameplay` doesn't stop a prior provider
**File:** `MusicArc/Game/GameEngine.swift:114-148`

`start()` is guarded against double-start, but if `beginGameplay` were ever invoked twice (future change, or via timer racing) it would create a second provider without stopping the first. The current code path is safe; flagging it as a brittle invariant.

**Action:** Defensively call `poseProvider?.stop()` and `poseCancellable?.cancel()` at the top of `beginGameplay`.

### 3.5 `GameEngine.touchProvider` is public to let `GameView` wire gestures
**File:** `MusicArc/Game/GameEngine.swift:58`, `GameView.swift:124-137`

`private(set) var touchProvider: TouchPoseProvider?` leaks an implementation detail of input mode. The view shouldn't need to know which kind of provider the engine uses.

**Action:** Expose a single `engine.setTouchHeight(_:)` method that internally routes to the touch provider, or move the touch-gesture handling into a small view that takes `(Double) -> Void` as a callback.

### 3.6 Color palette is duplicated across views
**Files:** `HomeView.swift`, `SessionSummaryView.swift`, `SessionHistoryView.swift`, `CalibrationView.swift`, …

The same forest palette — `Color(red: 0.25, green: 0.6, blue: 0.25)`, `Color(red: 0.2, green: 0.4, blue: 0.2)`, etc. — appears literally in many files. If the team ever rebrands, every file needs editing.

**Action:** Add a `Color+MusicArc.swift` with `Color.forestPrimary`, `Color.forestSecondary`, `Color.skyDay`, etc. — even a 10-color palette would dedupe most of this.

### 3.7 `treeSpecies` randomized in `GameView`, no user choice
**File:** `MusicArc/Views/GameView.swift:102`, `HomeView.swift:187-213`

`HomeView`'s "View Animation" section lets you tap a species to open `TreePreviewView`, but the actual game uses `TreeSpecies.random()`. The preview suggests user choice but offers none. Either the preview is misleading or the random selection is unintentional.

**Action:** Either (a) let the user select a species in HomeView and pass it through `GameConfig` / `AppRoute.game`, or (b) rename the preview section to "Try a Species" and explain that gameplay picks randomly so each session is a surprise.

### 3.8 `UIImpactFeedbackGenerator` instantiated per haptic event
**File:** `MusicArc/Views/GameView.swift:111-118`

Each growth spurt and water milestone allocates a new feedback generator and immediately calls `impactOccurred`. Apple's docs recommend keeping a long-lived generator and calling `prepare()` ahead of expected use for the lowest-latency haptic.

**Action:** Hold `@State` generators (`light`, `soft`) at view-level, call `prepare()` when the engine starts, and reuse on each event.

### 3.9 `GameSession` destructive fallback is shipping-risk
**File:** `MusicArc/App/MusicArcApp.swift:13-34`

If schema initialization throws, the store + WAL files are deleted and recreated. Acceptable in prototyping (CLAUDE.md notes this), but it means the very first post-launch schema change will wipe every patient's session history. For a clinical adherence-tracking app this is unacceptable.

**Action:** Before the first clinical pilot, replace the destructive fallback with a real `VersionedSchema` + `SchemaMigrationPlan`. At minimum, surface a "couldn't open your history" alert with a "restart fresh" button rather than silently nuking data.

### 3.10 No test target
There's no `MusicArcTests` target and no `xcodebuild test` workflow. Logic that is straightforward to unit-test sits unprotected:

- `RepScheduler.generate(config:)` — pure function, easy
- `ScoreTracker` add/penalize/restore arithmetic
- `CalibrationData.normalize` clamp behavior + degenerate range
- `GameConfig.totalSessionDuration` arithmetic
- `GameEngine`'s rep-advancement logic (with a fake `PoseProvider`)

**Action:** Add a `MusicArcTests` target in `project.yml`, write ~10-20 focused unit tests for the above, and wire a `MusicArcTests` scheme into the default workflow. Even a small suite catches future regressions.

### 3.11 `GameEngine` is not main-actor-isolated
**File:** `MusicArc/Game/GameEngine.swift`

`@Observable final class GameEngine` mutates properties read by SwiftUI views, and is touched from Combine sinks that explicitly `.receive(on: DispatchQueue.main)`. The invariant "always on main" is documented only by convention.

**Action:** Annotate the class `@MainActor`. The compiler will then enforce the assumption and catch any future off-main mutation.

---

## 4. Privacy & security

### 4.1 No camera-permission flow
(Covered in 2.11.) For a healthcare-adjacent app, the camera-denied path must be explicit and recoverable.

### 4.2 Health-data export has no consent gating or cleanup
**File:** `MusicArc/Views/SessionHistoryView.swift:190-218`

`exportAllSessions` writes all session data (timestamps, rep counts, growth/health metrics) to a temp file and presents `UIActivityViewController`. Per `INVENTION_DISCLOSURE.md`, this is patient rehabilitation data. The export:

- Asks no consent ("This will share all your session data; continue?").
- Leaves the file in `temporaryDirectory` indefinitely; multiple exports stack up.
- Has no option to share a single session vs. all sessions.

**Action:** Confirm intent before export, delete the temp file after the share sheet dismisses, and consider offering single-session export from the detail sheet.

### 4.3 `AVAudioSession.setActive(true)` runs in `AudioManager.init`
**File:** `MusicArc/Audio/AudioManager.swift:11-14`

Activating the audio session at first access of `AudioManager.shared` is OK in practice (it's lazy), but it'll briefly duck other audio apps on first launch even before any sound plays.

**Action:** Defer `setActive(true)` until the first `playX` call, or activate it only when the game starts.

---

## 5. UX / accessibility / clinical fidelity

### 5.1 No accessibility labels or VoiceOver hints
None of the SwiftUI screens add `.accessibilityLabel`, `.accessibilityValue`, `.accessibilityHint`. The rep counter, timer, growth ring, and tree are all decorative-only from VoiceOver's perspective.

**Action:** At minimum, add labels to:
- `repCounter` ("rep 3 of 8")
- `growthRing` ("growth 65 percent")
- pause / resume / restart buttons
- the touch-capture layer ("drag up and down to grow the tree")

### 5.2 No Dynamic Type support
**Files:** `HomeView.swift`, `GameView.swift`, `SessionSummaryView.swift`, `CalibrationView.swift` (and others)

Font sizes are hard-coded numerically: `.font(.system(size: 32))`, `.font(.system(size: 80))`, `.font(.system(size: 96))`. Patients with low vision who increase their text size in Settings see no change.

**Action:** Prefer `.font(.largeTitle)`, `.font(.title2)`, etc., or apply `.dynamicTypeSize(.medium...accessibility3)` to allow at least a usable scale range.

### 5.3 Calibration UI never tells the user how to position themselves
The instructional text says "Position yourself so the camera can see your upper body" but doesn't say at what distance, whether they should be standing or sitting, or which way they should face. The clinical context (burn rehab) likely has a recommended posture.

**Action:** Add a brief illustrated guidance step (or even just text) — distance, posture, and the importance of stable framing.

### 5.4 No "session abandoned" handling
If the user backgrounds the app or quits during a session, `GameEngine.stop()` is called via `.onDisappear` but the session is never persisted. There's no concept of a partial-session record. For adherence tracking this matters: a clinician would want to see *attempts*, not just completions.

**Action:** Consider persisting an "incomplete" `GameSession` flag when the user quits via the confirmation dialog.

### 5.5 Hardcoded "Magnificent Oak!" grade labels don't reflect the picked species
**File:** `MusicArc/Views/SessionSummaryView.swift:188-193`

`gradeLabel` says "Magnificent Oak!" / "Strong Sapling!" regardless of `result.treeSpecies`. A patient who grew a "Pine" will see "Magnificent Oak!" — minor but jarring.

**Action:** Either drop the species-specific label or interpolate `result.treeSpecies.displayName`.

---

## 6. Performance

### 6.1 `TreeGrowthView`'s entire SwiftUI subtree re-renders on every `handHeight` change
`TreeGrowthView` is not `Equatable` and takes ~10 separate props. Any 30 Hz `handHeight` update invalidates the whole view body, including the `TreeView` Canvas (which redraws even when `treeGrowth` hasn't materially changed — `treeGrowth` only ticks up when in the sunlight zone). SwiftUI's structural diffing will skip child redraws cheaply, but the Canvas-based species renderer still runs.

**Action:** Make `TreeGrowthView` conform to `Equatable` and short-circuit redraws when `treeGrowth`/`treeHealth`/`phase` are unchanged. Alternatively, split the view: a "sky/particles" branch driven by `handHeight`, a "tree" branch driven only by `treeGrowth`/`treeHealth`.

### 6.2 `ParticleOverlay` redraws sparkles every frame even when `intensity` is tiny
**File:** `MusicArc/Views/TreeGrowthView.swift:140-169`

The TimelineView ticks at 15 Hz and `drawSparkles` always runs at least 4 sparkles regardless of `intensity` (line 145 floors at 4). When the patient is below the sunlight threshold but `isInSunlightZone` was once true, sparkles continue at minimum count.

**Action:** Early-return when `intensity < 0.05`. Skipping the draw is fine because they're decorative.

### 6.3 Tree species renderers re-instantiated 30/sec
Covered in 3.2.

---

## 7. Minor / polish

| # | File:line | Issue | Action |
|---|---|---|---|
| 7.1 | `Tracking/PoseProvider.swift:20-22` | `armPosePublisher` default-nil makes call sites use awkward `?.` chaining | Always publish a synthetic `ArmPose` (touch/demo can emit `isTracking: false`) |
| 7.2 | `Views/GameView.swift:109-119` | `.onChange(of: engine?.x ?? 0)` may miss change from `nil → 0` at startup | Acceptable but explicit `if let engine` outer guard would read clearer |
| 7.3 | `Views/TreePreviewView.swift:9` | `@GestureState private var isHolding` is declared but never used | Delete |
| 7.4 | `Views/TreePreviewView.swift:91-96` | Uses a continuously-running `Timer.publish` instead of `TimelineView` | Switch to `TimelineView(.animation)` for proper run-loop coupling |
| 7.5 | `Models/GameSession.swift:14-19` | `treeSpeciesRaw: String` with a computed enum accessor — works, but a `Codable` species would be cleaner now that SwiftData supports it | Optional refactor |
| 7.6 | `Views/SkyView.swift:376-433` | `GroundView` lives in `SkyView.swift` despite being a separate concept | Move to its own file (small) |
| 7.7 | `Views/GameView.swift:369-386` | `PhasePromptOverlay` is `private struct` declared at file scope | Fine as-is; mention for organization |
| 7.8 | `MusicArc/.DS_Store` is checked in | macOS metadata in source tree | Add `**/.DS_Store` to `.gitignore` and `git rm --cached MusicArc/.DS_Store` |
| 7.9 | `Audio/AudioManager.swift:48-56` | `playTreeComplete` uses `DispatchQueue.main.asyncAfter` chains for a 3-note arpeggio — fragile and won't be cancelled if the engine stops | Schedule all three buffers up front at offsets |
| 7.10 | `Game/GameEngine.swift:236-239` | Both branches of the ternary return the same string ("Raise the sun over the line!") — leftover from an earlier variant | Simplify to a single literal |
| 7.11 | `SOUND_EFFECTS.md` claims 24 sound assets needed, but `Resources/Sounds/` is empty | Doc and reality match, but the audio system is all placeholder | Track the placeholder→asset migration as its own work item |
| 7.12 | `Models/CalibrationData.swift:10` | When degenerate, returns `0.5` silently — see 1.1 | Pair with the calibration fix; consider making `normalize` return `nil` on degenerate range |
| 7.13 | `Game/GameEngine.swift:65-93` | `start()` initializes ~20 properties manually — easy to miss one when adding state | Consider factoring into a `resetState()` method that mirrors `init` |
| 7.14 | All renderers re-clamp `g` and `hp` at the top of `draw` | Caller in `TreeView.body` already passes in valid values | Move clamp to `TreeView` or a single helper; remove from each renderer |
| 7.15 | `Views/HomeView.swift:171-174` | `Picker` for `TrackingArm` uses the same SF Symbol for both options | Use `hand.point.left.fill` vs `hand.point.right.fill` (or any pair) for visual distinction |

---

## 8. Recommended priority order

If acting on this report, work in this sequence:

**Sprint 1 — block before any clinical use (critical bugs):**
1. Fix calibration degeneracy (§1.1)
2. Fix stale Vision-results emission (§1.2)
3. Couple `DemoPoseProvider` to `GameConfig` (§1.3)
4. Add scenePhase pause/resume to `GameView` (§1.6, §2.2)
5. Add camera-permission flow (§2.11)

**Sprint 2 — UX correctness before pilot:**
6. Add camera preview + skeleton during gameplay (§2.1)
7. Add calibration phase-transition pause and sampling grace period (§2.9)
8. Fix `SessionSummary` / `History` silent-failure paths (§2.5, §2.6)
9. Skip calibration screen for touch/demo (§2.7)
10. Add accessibility labels and Dynamic Type (§5.1, §5.2)

**Sprint 3 — performance & architecture:**
11. Rework `AudioManager` to a single long-lived engine (§1.4)
12. Cache star positions + early-return sparkles (§2.4, §6.2)
13. Cache `TreeSpecies.renderer` instances (§3.2)
14. Lift shared renderer helpers to `TreeRenderer` extension (§3.1)
15. Pull clinical constants into `GameConfig` (§3.3)

**Sprint 4 — pre-ship hardening:**
16. Real SwiftData migration plan (§3.9)
17. Test target with focused unit tests (§3.10)
18. `@MainActor` annotations on `GameEngine` (§3.11)
19. Color palette extraction (§3.6)
20. Polish items in §7

---

## Appendix — files reviewed

All 34 Swift sources under `MusicArc/`:

- `App/`: `MusicArcApp.swift`, `ContentView.swift`
- `Audio/`: `AudioManager.swift`
- `Game/`: `GameEngine.swift`, `RepScheduler.swift`, `ScoreTracker.swift`
- `Models/`: `GameConfig.swift`, `CalibrationData.swift`, `GameResult.swift`, `GameSession.swift`, `Rep.swift`, `TreeSpecies.swift`
- `Rendering/`: `TreeRenderer.swift`, `OakTreeRenderer.swift`, `RoundTreeRenderer.swift`, `BushyTreeRenderer.swift`, `PineTreeRenderer.swift`, `AcaciaTreeRenderer.swift`
- `Tracking/`: `PoseProvider.swift`, `PoseDetector.swift`, `CameraManager.swift`, `TouchPoseProvider.swift`, `DemoPoseProvider.swift`
- `Views/`: `HomeView.swift`, `CalibrationView.swift`, `GameView.swift`, `TreeGrowthView.swift`, `SkyView.swift`, `TreeView.swift`, `SessionSummaryView.swift`, `SessionHistoryView.swift`, `TreePreviewView.swift`, `AmbientBlobBackground.swift`, `CameraPreviewView.swift`

Plus `project.yml`, `INVENTION_DISCLOSURE.md`, `SOUND_EFFECTS.md`, `CLAUDE.md`.

Renderers `BushyTreeRenderer`, `RoundTreeRenderer`, and the latter portions of `PineTreeRenderer` and `AcaciaTreeRenderer` were scanned but not read in full; observations about them in §3.1 are based on signature-level pattern matching across the directory.
