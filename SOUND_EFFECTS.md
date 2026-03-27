# Music Arc -- Sound Effects Specification

**App**: Music Arc (iOS Rehab Game Prototype)

**Purpose**: This document lists every sound effect needed for the app, organized by screen. Each entry includes where it triggers, what it should feel like, and suggested duration. Items marked **[EXISTS - placeholder]** currently use a programmatic sine-wave tone or system sound and need a real asset. Items marked **[MISSING]** have no sound at all yet.

---

## 1. Home Screen

| # | Sound | Trigger | Status | Notes |
|---|-------|---------|--------|-------|
| 1.1 | **Button tap -- Start Session** | User taps the "Start Session" button | **[MISSING]** | Confident, forward-moving feel. Soft upward musical phrase or a clean "whoosh-click." Should feel like launching into something. ~0.2-0.3s |
| 1.2 | **Segment picker change** | User switches duration (30s/45s/60s/90s) or input mode (Camera/Touch/Demo) | **[MISSING]** | Very subtle click or soft tick. Shouldn't be annoying since user may tap through several options. ~0.05-0.1s |
| 1.3 | **Session History tap** | User taps "Session History" | **[MISSING]** | Soft navigation sound, lighter than Start Session. ~0.1-0.15s |

---

## 2. Calibration Screen (camera mode only)

| # | Sound | Trigger | Status | Notes |
|---|-------|---------|--------|-------|
| 2.1 | **Begin Calibration tap** | User taps "Begin Calibration" or "Continue" | **[MISSING]** | Similar to 1.1 but can be the same asset. ~0.2s |
| 2.2 | **Phase transition -- Raise Arm** | Calibration enters "Raise Your Arm" phase | **[MISSING]** | Ascending chime or gentle upward sweep to reinforce "go up." ~0.3-0.5s |
| 2.3 | **Phase transition -- Lower Arm** | Calibration enters "Lower Your Arm" phase | **[MISSING]** | Descending chime or gentle downward sweep to reinforce "go down." ~0.3-0.5s |
| 2.4 | **Calibration complete** | All phases done, "All Set!" shown | **[MISSING]** | Positive confirmation. Short two-note ascending chime. ~0.3s |
| 2.5 | **Start Game tap** | User taps "Start Game" after calibration | **[MISSING]** | Can reuse 1.1 or a bolder variant. ~0.2s |
| 2.6 | **Cancel tap** | User taps "Cancel" to go back | **[MISSING]** | Soft dismissive sound, gentle backward whoosh. ~0.15s |

---

## 3. Countdown (3... 2... 1... GO!)

| # | Sound | Trigger | Status | Notes |
|---|-------|---------|--------|-------|
| 3.1 | **Countdown tick** | Each second: 3, 2, 1 | **[EXISTS - placeholder]** | Currently uses iOS system sound `1104`. Needs a custom rhythmic tick/metronome tap. Should build anticipation. Each tick identical. ~0.1-0.15s |
| 3.2 | **Countdown GO** | Countdown reaches 0, game begins | **[EXISTS - placeholder]** | Currently uses iOS system sound `1025`. Needs a custom burst/start sound -- higher energy than the ticks. Short ascending fanfare or a punchy "go" stinger. ~0.3-0.5s |

---

## 4. Gameplay (core game loop -- most important sounds)

| # | Sound | Trigger | Status | Notes |
|---|-------|---------|--------|-------|
| 4.1 | **Note hit** | User's arm height matches a note within tolerance | **[EXISTS - placeholder]** | Currently a 880Hz sine tone, 0.15s. **This is the most important sound in the app.** Should feel rewarding, musical, and satisfying. Bright, clean tone -- think xylophone, marimba, or bell hit. Consider 3 pitch variants (low/mid/high) matching the note's target height for a more musical feel. ~0.15-0.25s |
| 4.2 | **Note miss** | A note's hit window expires without a hit | **[EXISTS - placeholder]** | Currently a 220Hz sine tone, 0.1s. Should be clearly different from a hit but NOT punishing (this is rehab -- don't discourage the patient). Soft, muted thud or a gentle "dud." Not harsh. ~0.1-0.15s |
| 4.3 | **Streak milestone** | Player hits 3, 5, or 10 notes in a row | **[MISSING]** | Short celebratory flourish layered on top of the normal hit sound. Gets slightly more impressive at higher streaks. ~0.2-0.4s |
| 4.4 | **Note approaching hit zone** | A note enters the hit zone area (last ~15% of travel) | **[MISSING]** | Very subtle anticipation cue -- soft shimmer or quiet "ready" whisper. Must NOT be distracting. Optional but adds polish. ~0.1s |
| 4.5 | **Timer warning** | 10 seconds remaining in session | **[MISSING]** | Subtle urgency cue. Gentle double-beep or clock tick that plays once. ~0.3s |

---

## 5. Session Complete

| # | Sound | Trigger | Status | Notes |
|---|-------|---------|--------|-------|
| 5.1 | **Session complete fanfare** | Timer hits zero, game ends | **[EXISTS - placeholder]** | Currently a 3-note ascending sine sequence (660/880/1100Hz). Needs a polished completion jingle. Should feel accomplished regardless of score. Ascending 3-4 note musical phrase. ~0.5-0.8s |
| 5.2 | **View Results tap** | User taps "View Results" button | **[MISSING]** | Soft transition sound. ~0.15s |

---

## 6. Session Summary Screen

| # | Sound | Trigger | Status | Notes |
|---|-------|---------|--------|-------|
| 6.1 | **Score reveal** | Summary screen appears, stats animate in | **[MISSING]** | Gentle "score reveal" flourish as the hit-rate ring fills. Think game show result sound but softer. ~0.5-0.8s |
| 6.2 | **Grade-specific stinger** | After score reveal, based on performance tier | **[MISSING]** | 4 variants matching the grade: **Outstanding (90%+)**: triumphant sparkle/cheer. **Great (70%+)**: warm positive chime. **Good (50%+)**: encouraging gentle tone. **Keep Practicing (<50%)**: still positive, soft and supportive. ~0.3-0.5s each |
| 6.3 | **Save Session tap** | User taps "Save Session" | **[MISSING]** | Satisfying confirmation "ding" or soft click-and-swoosh. The "I saved your progress" sound. ~0.2s |
| 6.4 | **Back to Home tap** | User taps "Back to Home" | **[MISSING]** | Same as cancel/back navigation sound (2.6). ~0.15s |

---

## 7. Session History Screen

| # | Sound | Trigger | Status | Notes |
|---|-------|---------|--------|-------|
| 7.1 | **Export tap** | User taps the Export button | **[MISSING]** | Soft "share" whoosh. ~0.15s |
| 7.2 | **Delete swipe** | User swipe-deletes a session | **[MISSING]** | Soft destructive sound -- gentle "poof" or paper crumple. ~0.15s |

---

## Summary Table

| Category | Total sounds | Currently have (placeholder) | Need new assets |
|----------|-------------|------------------------------|-----------------|
| Home Screen | 3 | 0 | 3 |
| Calibration | 6 | 0 | 6 |
| Countdown | 2 | 2 (system sounds) | 2 |
| Gameplay | 5 | 2 (sine tones) | 5 |
| Session Complete | 2 | 1 (sine tones) | 2 |
| Summary | 4 | 0 | 4 |
| History | 2 | 0 | 2 |
| **TOTAL** | **24** | **5 placeholders** | **24 unique assets** |

---

## Delivery Specs

- **Format**: `.m4a` (AAC) or `.wav` -- either works, `.m4a` preferred for smaller file size
- **Sample rate**: 44.1kHz
- **Channels**: Mono is fine (stereo not needed for phone speaker)
- **Loudness**: Normalize all to approximately -14 LUFS; gameplay sounds (4.1, 4.2) should be the loudest; UI sounds (1.2, 1.3) should be the quietest
- **Naming convention**: `SFX_[category]_[name].m4a` -- e.g., `SFX_gameplay_note_hit_high.m4a`

---

## Priority Order

If budget/time is limited, the most impactful sounds to get right first:

1. **4.1 Note hit** (the core experience -- consider 3 pitch variants for low/mid/high)
2. **4.2 Note miss**
3. **5.1 Session complete fanfare**
4. **3.1 + 3.2 Countdown tick & GO**
5. **6.2 Grade stingers**
6. Everything else

---

## Tone / Vibe

This is a **rehab game for patients recovering arm mobility**. The overall audio vibe should be:

- **Encouraging, never punishing** -- misses should be neutral/soft, not harsh buzzers
- **Musical and warm** -- xylophone, marimba, bell-like timbres fit well
- **Clean and simple** -- no complex sound design, just clear tonal feedback
- **Consistent volume** -- patients may be in a clinic environment; nothing should be startlingly loud
