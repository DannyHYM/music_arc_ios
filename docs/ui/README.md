# UI Screenshots

Every product screen, rendered by the real SwiftUI views with fixed fake data on an
iPhone 17 Pro simulator, stored at 2× (804 × 1748) to keep the repo small
(`SCREENSHOT_WIDTH=0` keeps the native 3× capture). Camera screens use a placeholder
silhouette in place of the live feed; the skeleton overlay drawn on it is the real one.

Regenerate after any UI change:

```sh
scripts/capture_ui_screenshots.sh
```

The script builds the app, launches the `DEBUG`-only screenshot gallery
(`MusicArc/App/ScreenshotGallery.swift`) once per screen via the `MUSICARC_SCREENSHOT`
environment variable, and captures with `simctl`. `SKIP_BUILD=1` reuses the last build;
`SIM_DEVICE="iPhone 17 Pro Max"` targets a different simulator. Before committing
regenerated images, run with `OPTIMIZE_PNG=1` (needs `zopflipng`; slow, but it halves
the file sizes losslessly).

## Patient flow

| Screen | File | Notes |
|---|---|---|
| Welcome (prescription set) | `welcome.png` | Begin, My Trees, clinician link |
| Welcome (no prescription) | `welcome-empty.png` | "Ask your clinician" empty state |
| Calibration – intro | `calibration-intro.png` | Before tapping Begin Calibration |
| Calibration – raise arm | `calibration-raise.png` | Tracking badge, skeleton, progress and height bars |
| Calibration – done | `calibration-done.png` | Start Growing / Re-calibrate |
| Game – countdown | `game-countdown.png` | "3" with instructions; no camera PiP yet |
| Game – active (day) | `game-active.png` | Rep 4 of 8, sun above the line, camera PiP with pull tab |
| Game – rest (night) | `game-rest.png` | Rain, water level, "Rest & water your tree" prompt |
| Game – paused | `game-paused.png` | Continue / Restart / Go Home |
| Game – finished | `game-finished.png` | Session Complete overlay |
| Session summary | `summary.png` | 87% growth, 8/8 reps, Plant in Forest below the fold |
| My Forest | `history.png` | Five dated trees; scrolls horizontally |

## Clinician flow

| Screen | File | Notes |
|---|---|---|
| Clinician PIN | `clinician-pin.png` | The number pad is up on a device; the simulator had a hardware keyboard attached |
| Clinician Setup | `clinician-setup.png` | 10 reps × 5s / 4s, camera, right arm. Save / Test Run / History buttons are below the fold |

## Trees

`tree-oak.png`, `tree-round.png`, `tree-bushy.png`, `tree-pine.png`, `tree-acacia.png` —
each species' preview page at 100% growth.
