# MusicArc — Manual Test Plan

For the user to run on a real iPhone after the Stage 1-4 implementation.

All four stages are code-complete and the project builds + passes the 18-test unit suite on the iOS 18 simulator. The items below cannot be exercised by `xcodebuild test` alone — they need a human + (for some) a real device with a working front camera.

If anything in this list fails, send the failing step and the symptom; do **not** rely on the rest of the list being green just because earlier items passed.

---

## 0. Pre-flight

1. Delete any prior installs of MusicArc from the device and simulator to start with empty `UserDefaults` + empty SwiftData store.
2. Open `MusicArc.xcodeproj` in Xcode 26.x and run on (a) iPhone 16 simulator and (b) a real iPhone with iOS 18+.

---

## 1. Patient flow — Touch mode (works on simulator)

1. **First-launch empty state.** Welcome screen shows "Welcome to MusicArc" title, an emerald "Begin" button is **disabled**, and a card reads "Ask your clinician to set up your exercises" with a "Set Up Now" link. "My Trees" is visible. A faint "I'm a clinician" text is at the bottom.
2. **Wrong PIN.** Tap "I'm a clinician" → PIN screen. Enter `0000`. The dot row shakes, clears, and shows "Incorrect PIN".
3. **Correct PIN.** Enter `1234`. Pushes to Clinician Setup.
4. **Save a prescription.** Defaults are 8 reps / 4s hold / 3s rest / Touch / Right arm. Change Reps to 6. Tap "Save Configuration" — banner reads "Saved — patient can now press Begin."
5. **Back to Welcome.** Pop back. The Begin button is now **enabled** in green.
6. **Begin a touch session.** Tap Begin → CalibrationView intro reads "Touch mode: drag your finger up/down… No calibration needed." Tap **Continue** → game starts with a 3-2-1 countdown.
7. **Touch-drag growth loop.** During active phases drag your finger toward the top of the screen — the sun rises and the tree grows once you cross the orange threshold line. During rest phases drag toward the bottom — rain falls, the water gauge fills, the tree's "health" stays high.
8. **Pause + resume.** Mid-session tap the pause icon (top-left circle). Pause overlay shows Continue / Restart / Go Home. Tap Continue. Game resumes without skipping reps.
9. **Restart from pause.** Pause again → Restart. Engine rewinds to countdown.
10. **Quit confirmation.** Pause → Go Home → "Leave Session?" alert. Cancel returns to pause. Leave pops to Welcome and the session is discarded.
11. **Complete a session.** Finish all 6 reps. "Session Complete!" overlay appears. Tap "View Results" → SessionSummaryView.
12. **Save the tree.** Summary shows grade icon, species-aware label ("Magnificent Oak!" / "Strong Pine Sapling!" depending on randomly-picked species), growth ring, stat cards. Tap "Plant in Forest" — button flips to "Planted!" and is disabled.
13. **Back to Welcome.** Tap "Back to Home" → returns to Welcome (pops to root).
14. **Patient sees their forest.** Tap "My Trees" → SessionHistoryView shows the freshly grown tree. **No Export button** is visible in the toolbar (patient-mode hides it). Tap a tree → detail sheet with stats. "Remove Tree" deletes from the detail sheet.

## 2. Camera flow — Real device only (cannot test on simulator)

15. **Reconfigure to Camera mode.** Clinician PIN → ClinicianConfigView → Input Mode → Camera. (On simulator, this row warns "Camera not available in Simulator" and silently falls back to Touch at session start. On device, the warning is hidden.) Pick Right arm. Save.
16. **First camera-mode session.** Welcome → Begin → CalibrationView intro shows "Stand about an arm's length from the phone…". Tap **Begin Calibration** — iOS should prompt for camera permission (first launch only).
17. **Grant permission.** Camera preview fills the screen, dimmed; a green/orange status badge at the top reads "Tracking your arm" or "Looking for you…". Skeleton overlay (green dots/lines on shoulder-elbow-wrist) draws over your arm. After ~0.5s, the **Raise** phase samples begin.
18. **Raise phase.** Raise your arm as high as you can and hold. Yellow progress bar fills over 4s. Tracking should stay green.
19. **Settle phase.** A 1.5s "Get Set" phase appears, with an hourglass icon, telling you to get ready to lower. **No sampling happens during this phase** (so your still-raised position doesn't get recorded as the min).
20. **Lower phase.** Lower your arm. 4s timer. Then a "Start Growing" button appears.
21. **Camera PiP during gameplay.** After Start Growing, the game starts. **Top-right corner** of the game screen shows a small (~110×150pt) camera preview with the skeleton overlay drawn on top. It updates live.
22. **Tracking-lost banner.** Cover the camera with your hand for ≥1s during gameplay. An orange "Move so the camera can see your arm" banner appears below the timer. Uncover → banner disappears within a frame or two.
23. **Real arm-tracked rep.** Reps complete when you raise your arm above the orange line during active phases and lower below the cyan line during rest. The sun and rain cloud should ride your arm height.
24. **Narrow-range guard.** Restart and re-run calibration, but stay still (or barely move) during the raise phase. After both phases finish, you should see a **"Let's Try Again"** screen ("We didn't see your arm move enough") with a **Try Again** button that re-runs calibration. The session does **not** start until you record a meaningful range.
25. **Camera-denied path.** Settings → Privacy → Camera → toggle MusicArc off. Relaunch app. Welcome → Begin → "Begin Calibration" → "Camera Needed" screen with **Open Settings** and **Back** buttons. Tap Open Settings → iOS Settings.app opens to MusicArc's row.
26. **Camera-denied recovery.** Re-enable camera in Settings. Return to the app. The denial screen is still showing (state is preserved); tap Back to Welcome, then Begin again — calibration starts normally.

## 3. Demo mode (works anywhere)

27. **Demo configuration.** Clinician → set Input Mode to Demo. Change Hold to 6s, Rest to 5s. Tap "Test Run". A "Welcome to MusicArc" → calibration intro → Continue → game starts.
28. **Demo cadence matches config.** The auto-animated arm should reach its peak during the 6-second active window and bottom out during the 5-second rest. (Before the fix it was hardcoded to 4/3 — verify it now syncs to the new values.)

## 4. Background / scene phase

29. **Backgrounding pauses.** Start any session. Press Home (or swipe up) to background the app. Wait 5s. Return to the app — the pause overlay should be visible. The game has **not** auto-resumed (intentional — patient may have set the phone down). Tap Continue to resume.
30. **No silent rep skipping.** Background mid-rep, wait 30s, return. After tapping Continue, the rep should resume where it left off (no fast-forward).

## 5. Audio

31. **Countdown / GO.** "3, 2, 1, Grow!" each triggers a tick sound; GO is a louder system sound (still placeholder).
32. **Growth + milestone tones.** During the active phase, when your arm is above the sunlight line, you should hear a short two-note chord ("growth") several times per rep, plus a brighter three-note chord on each ~10% growth milestone.
33. **Phase transitions.** Each active→rest transition plays a soft low tone; each rest→active plays an ascending day-transition chord.
34. **Session-complete arpeggio.** When the session ends, a 3-note ascending arpeggio plays.
35. **No audio glitches.** Crucially — across the whole session, listen for clicks/pops or audio dropouts between sounds. With the new single-engine audio they should be cleaner than before (no more engine-per-sound spin-up).
36. **Mixes with Music.app.** Start Music.app playing a song, then run a MusicArc session. The music should keep playing under MusicArc's sound effects (`.mixWithOthers`).

## 6. Clinician — patient history view

37. **Clinician-mode history.** Welcome → I'm a clinician → 1234 → ClinicianConfigView → "View Patient History". SessionHistoryView opens and **shows an Export toolbar button** (top-right).
38. **Export consent.** Tap Export → confirmation alert "Export session data?" with a "Only share with your clinician or someone you trust" warning. Cancel → no file written. Export → share sheet opens with `musicarc_forest_<date>.json`. Dismiss the sheet.
39. **Temp file cleanup.** Run Export → AirDrop or save to Files. Then dismiss the share sheet. The temp file should be cleaned up (no easy way to verify directly, but it's gone next launch).
40. **Export error.** (Best-effort) Fill the device until disk-write fails, then Export. You should see an "Export failed" alert with the underlying error, not a silent failure.
41. **Patient cannot see Export.** Quit, relaunch, tap My Trees from Welcome — **no Export button** in the toolbar.

## 7. Accessibility

42. **VoiceOver — Welcome.** Settings → Accessibility → VoiceOver → on. Tab through Welcome: "Welcome to MusicArc, heading. Begin session, button. Starts your exercise session. My Trees, button. See the trees you have grown from past sessions. Clinician access, button. Opens the PIN screen to configure exercises."
43. **VoiceOver — Game HUD.** Start a session. Swipe to the rep counter — reads "Rep 1 of 8" (or whatever the current rep). Pause button reads "Pause session, button". Continue button on the pause overlay reads its label.
44. **VoiceOver — Summary.** Growth ring reads "Tree grew to X percent". Stat cards read their values.
45. **Dynamic Type.** Settings → Display & Brightness → Text Size → set to AX2 or AX3. Open MusicArc. Welcome / SessionSummary / My Trees should grow text without clipping critical buttons. (GameView keeps its numeric sizes for the timer/countdown — that's intentional.)

## 8. Edge cases

46. **No prescription → "Set Up Now".** Fresh install. Welcome empty state. Tap "Set Up Now" link → PIN screen (same path as "I'm a clinician").
47. **Cancel calibration mid-flow.** Start camera calibration, hit Cancel during the Raise phase. Should clean up — back at Welcome, no orphan camera session running.
48. **Re-save same prescription.** Clinician → Save without changing anything. Banner still shows. No crash.
49. **Cycle through tree species.** Run sessions repeatedly — the species `treeSpecies = .random()` should give you a mix over time. Summary's grade label interpolates the species name ("Magnificent Pine!" etc.).
50. **Delete from history.** My Trees → tap a tree → Remove Tree → tree disappears from forest. Save still works for new sessions afterwards.

---

## What's *not* in this build (deferred)

These were noted in `docs/code_review.md` and the plan but were intentionally **not** done in this pass:

- **Real `.m4a` sound assets.** All audio is still procedurally synthesized (per `SOUND_EFFECTS.md`). Quality is the same as before but cleaner now that there's one long-lived engine.
- **Renderer dedup.** All five tree renderers still each carry their own `drawSoilMound` / `drawSprout`. Cleanup deferred — no behavior change so nothing to test.
- **SwiftData migration.** The destructive deletion of the store on schema mismatch is replaced with an **in-memory fallback** that preserves the on-disk data. A real `VersionedSchema` is still TODO — if you ever change the `GameSession` model fields, run a fresh install or sessions won't persist that launch.
- **Color palette migration.** `Color.forestPrimary` etc. exist in `Views/Color+MusicArc.swift` but the rest of the codebase still uses inline `Color(red: 0.25, green: 0.6, blue: 0.25)` literals. Future PRs can migrate incrementally.
- **GameEngine integration tests.** The 18 unit tests cover the pure logic (`RepScheduler`, `ScoreTracker`, `CalibrationData`, `PrescriptionStore`). A `FakePoseProvider` + test clock for the engine itself is deferred — would require dependency injection that we don't need yet.
- **Keychain-backed PIN.** PIN is still hardcoded to `"1234"` in `Models/ClinicianAuth.swift`. Promote to per-device Keychain before any real clinical use.

---

## Reporting back

When you run through this, please flag specifically:
- Anything from §2 (camera) that doesn't behave — I had to verify those by code-read alone.
- Anything audio-related in §5 that sounds *worse* than before (the single-engine rewrite could regress edge cases).
- VoiceOver / Dynamic Type issues in §7 — they're easy to miss and matter for the burn-unit population.
