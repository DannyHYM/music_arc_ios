# Invention Disclosure — MusicArc Forest

## Section 2: Description of Invention/Work

---

### 7. Summary of the Invention/Work

MusicArc Forest is a gamified rehabilitation application for iOS designed specifically for burn recovery patients at the LA General Hospital Burn Unit Department. The app targets patients recovering from burns to the shoulder and axilla (armpit) region, who must perform repetitive overhead arm-raising and shoulder-extension stretching exercises as part of their recovery protocol. These exercises — traditionally performed with resistance bands, cable rows, or pulley systems — are essential for restoring range of motion and preventing contracture in the shoulder and axilla, but suffer from extremely low at-home adherence due to their repetitive and painful nature.

MusicArc transforms these prescribed stretching exercises into an interactive tree-growing game. Using Apple's Vision framework, the app performs real-time machine-learning-based human body pose detection through the device's front camera, tracking the patient's shoulder extension and arm height as they perform their prescribed range-of-motion exercises. The detected arm height is normalized to a 0–1 scale and serves as the primary gameplay input.

The game is structured around timed rehabilitation sessions consisting of multiple repetitions ("reps"), each comprising an active stretching phase and a rest phase — mirroring the structure of a clinical stretching protocol. During the active phase, the patient raises their arm above a configurable threshold, causing a procedurally rendered tree to grow in real time. During the rest phase, the patient lowers their arm to "water" the tree, accumulating a bonus multiplier that enhances growth in the next rep. A dynamic health system penalizes patients who skip rest periods and rewards consistent recovery compliance, reinforcing the clinically important principle that rest between stretches is not optional but essential for tissue recovery.

All audio feedback is procedurally synthesized in real time using AVAudioEngine — generating sine-wave-based chords, arpeggios, and tones that respond directly to game events such as growth spurts, milestone achievements, phase transitions, and session completion. This responsive audio provides immediate positive reinforcement for exercise effort.

The visual environment features a fully procedural day/night cycle, a multi-stage tree renderer progressing through seven growth stages (seed through fruit-bearing tree), and a particle effects system. All graphics are rendered using SwiftUI Canvas with no external image assets.

Session results — including total growth, tree health, and per-rep compliance data — are persisted locally using SwiftData. A session history view displays all past sessions as a scrollable forest, where each tree's size and health visually reflects the patient's performance in that session. This gives patients and their care team a visual record of rehabilitation adherence and progress over time.

The app supports three input modes: camera-based pose detection (primary clinical use), touch-based input (for patients with limited mobility or device constraints), and a demo mode for clinician demonstrations.

---

### 8. Unmet Need/Problem

Burn patients recovering from injuries to the shoulder and axilla face a critical rehabilitation challenge: they must perform repetitive overhead arm-raising and shoulder-extension stretching exercises consistently over weeks to months to restore range of motion and prevent scar contracture. In clinical settings such as the LA General Burn Unit, these exercises are supervised by physical therapists using resistance bands, cable rows, or pulley systems. However, the majority of recovery must occur at home, where patients are expected to continue these exercises independently.

At-home adherence to burn rehabilitation stretching protocols is extremely poor. The exercises are inherently painful — patients must stretch healing and scarring tissue through its available range of motion — and deeply repetitive. Without the structure, motivation, and accountability of a clinical session, patients frequently reduce their exercise frequency, shorten their sessions, skip rest periods between stretches, or abandon the regimen entirely. This non-adherence directly leads to worse functional outcomes, including permanent loss of shoulder range of motion and axillary contracture.

Current solutions are inadequate for this patient population:

- **No interactive rehabilitation tools exist for burn recovery stretching**: While general fitness apps offer rep counting or video-guided workouts, none are designed for the specific biomechanics of shoulder and axilla burn recovery, and none provide real-time interactive feedback during the exercise itself.
- **Rest phase neglect**: Rest periods between stretches are clinically essential for tissue recovery in burn patients, yet no existing tool incentivizes or tracks rest compliance. Patients — especially those eager to finish painful exercises quickly — routinely skip or shorten rest periods, undermining therapeutic outcomes.
- **No at-home monitoring**: Clinicians at the Burn Unit have no way to assess whether patients are actually performing their prescribed exercises at home, how frequently, or with what quality. There is no objective record of at-home rehabilitation adherence.
- **Hardware and cost barriers**: Burn patients already face significant financial burden from their treatment. Solutions requiring wearables, specialized sensors, or VR equipment are impractical for this population. An iPhone-based solution using only the front camera removes this barrier entirely.
- **Lack of positive reinforcement**: Burn recovery exercises are associated with pain and discomfort. There is no existing tool that provides immediate, continuous positive feedback (visual and auditory) during the exercise to counteract the negative experience and build intrinsic motivation for continued adherence.

---

### 9. Unique/Novel Features

1. **Purpose-Built for Burn Recovery Rehabilitation**: Unlike general fitness or physical therapy apps, MusicArc is specifically designed around the biomechanics and clinical protocols of shoulder and axilla burn recovery stretching. The exercise motion tracked (overhead arm raising and shoulder extension) directly maps to the prescribed rehabilitation movements for this patient population.

2. **Dual-Phase Gamification with Clinically Meaningful Rest Enforcement**: The game uniquely treats rest periods as an active gameplay mechanic rather than passive downtime. Proper rest compliance during the "watering" phase directly affects the next rep's growth multiplier and overall tree health, creating a risk-reward dynamic that incentivizes the physiologically essential recovery periods between stretches — a critical factor in burn tissue healing that patients are most likely to skip.

3. **Real-Time Procedural Audio Synthesis as Positive Reinforcement**: All audio is generated mathematically at runtime (sine wave oscillators with ADSR envelopes at 44100 Hz) and triggered by game events. This provides immediate positive auditory feedback during exercises that are otherwise associated with pain and discomfort, helping to reframe the rehabilitation experience.

4. **ML-Based Body Pose Tracking Calibrated to Individual Patient Range of Motion**: The app uses Apple's VNDetectHumanBodyPoseRequest to detect shoulder, elbow, and wrist joints, then computes vertical arm extension normalized against the patient's own arm length. A calibration phase records each patient's current maximum and minimum range of motion, so the game adapts to individual recovery progress — a patient with severely limited range of motion early in recovery receives the same gameplay experience as a patient further along in their rehabilitation.

5. **Seven-Stage Procedurally Rendered Tree with Health-Responsive Visuals**: The tree progresses through seed, sprout, stem, trunk, branches, canopy, and fruit/flower stages — all rendered via SwiftUI Canvas. Tree health dynamically reflects rest compliance through canopy color saturation, providing intuitive visual feedback about rehabilitation quality without clinical jargon.

6. **Persistent Session History as a Rehabilitation Adherence Record**: Each completed session is stored locally and rendered as a uniquely sized tree in a scrollable forest. This serves a dual purpose: it provides patients with a growing visual representation of their recovery journey, and it gives clinicians at the Burn Unit an at-a-glance view of exercise adherence, frequency, and quality when patients return for follow-up appointments.

7. **Configurable Session Parameters for Clinical Customization**: Rep count, active phase duration, rest phase duration, and detection thresholds are all configurable, allowing clinicians to prescribe specific exercise protocols and adjust difficulty as the patient progresses through their recovery.

8. **Graceful Multi-Modal Input for Accessibility**: The protocol-based architecture supports seamless fallback from camera-based pose detection to touch-based input to demo mode, ensuring the app remains usable for patients with varying levels of mobility, device access, or comfort with camera-based tracking.

---

### 10. Advantages

- **No additional hardware required**: Works with any iPhone with a front-facing camera running iOS 17+, imposing zero additional cost on burn patients who already face significant financial burden from their treatment and recovery.
- **Clinically grounded rest enforcement**: The gamification of rest compliance directly addresses a documented gap in burn rehabilitation adherence — the system actively shapes recovery behavior by making rest periods mechanically rewarding rather than something to rush through.
- **Personalized to individual recovery progress**: The calibration system adapts to each patient's current range of motion, ensuring the game is equally engaging and achievable whether a patient is in early recovery with limited mobility or in later stages with near-full range of motion.
- **At-home rehabilitation without supervision**: Patients can perform their prescribed exercises independently at home with real-time guidance and feedback, reducing the need for frequent in-person therapy visits while maintaining exercise quality.
- **Objective adherence tracking for clinicians**: The persistent session history provides Burn Unit staff with a visual and data-driven record of patient exercise compliance between clinical visits, enabling more informed care decisions.
- **Positive reinforcement during painful exercises**: Real-time visual growth, procedural audio rewards, and haptic feedback transform a painful, dreaded activity into an engaging experience, directly addressing the psychological barrier that drives non-adherence.
- **Fully offline and private**: All processing occurs entirely on-device with no cloud dependency, ensuring patient health-related data never leaves the device — critical for a healthcare-adjacent application.
- **Zero external dependencies**: Built exclusively on Apple's first-party frameworks (SwiftUI, Vision, AVFoundation, SwiftData, Combine), eliminating third-party licensing concerns and ensuring long-term maintainability within a clinical research context.
- **Scalable across recovery stages**: Configurable session parameters allow clinicians to progressively increase exercise difficulty as patients recover, using a single application throughout the entire rehabilitation timeline.

---

### 12. Does this invention have a software component?

Yes. The invention is entirely software-based. It is an iOS application written in Swift using SwiftUI, targeting iOS 17 and later. The software components include:

- **Pose detection module**: Uses Apple's Vision framework (`VNDetectHumanBodyPoseRequest`) for real-time human body pose estimation via the front camera, specifically tracking shoulder, elbow, and wrist joints to measure arm extension during rehabilitation exercises. Includes a calibration system that records each patient's individual range of motion. Supports camera, touch, and demo input modes via a protocol-based architecture.
- **Game engine**: A state machine running at 30 FPS that manages game phases (countdown, active stretching, rest, complete), calculates growth rates based on arm extension above configurable thresholds, tracks tree health based on rest compliance, and coordinates audio and visual feedback events.
- **Audio synthesis engine**: A custom procedural audio synthesizer built on `AVAudioEngine` and `AVAudioPlayerNode` that generates PCM audio buffers containing sine-wave tones with envelope shaping at 44100 Hz sample rate, providing real-time positive auditory reinforcement during exercises.
- **Procedural graphics renderer**: SwiftUI Canvas-based drawing system that renders a multi-stage tree, dynamic sky environment, ground, and particle effects without any external image assets.
- **Data persistence layer**: SwiftData-based local storage for session history, enabling persistent tracking of rehabilitation adherence across sessions and the forest visualization.
- **Score tracking system**: Algorithms for calculating growth rate, rest compliance, health penalties/bonuses, and bonus multipliers based on real-time pose input, designed to reinforce clinically appropriate exercise and rest behavior.

No hardware components are involved beyond the standard iPhone hardware.

---

### 13. Were any third-party materials or data used?

No. The application uses no third-party libraries, frameworks, packages, or dependencies. There are no CocoaPods, Swift Package Manager packages, or Carthage dependencies. All functionality is implemented using Apple's first-party frameworks: SwiftUI, Vision, AVFoundation, AVAudioEngine, SwiftData, Combine, and AudioToolbox.

No third-party datasets, pre-trained models, or external assets (images, sounds, fonts) are used. All graphics are procedurally generated via code, and all audio is synthesized at runtime from mathematical functions. The machine learning model used for pose detection is Apple's built-in body pose estimation model included in the Vision framework as part of iOS.

---

### 14. Have any human materials or data been used?

No. The application does not use any pre-collected human data, biological samples, or datasets containing human subject information. The app processes the patient's camera feed in real time for pose detection, but this data is processed entirely on-device, is not stored or transmitted, and is used only to extract arm position during active rehabilitation sessions. No human subjects research was conducted in the development of this application.

---

### 15. Were any external computing resources used?

No. All development was performed on local machines. The application itself performs all computation on-device (iPhone) with no cloud services, external APIs, remote servers, or external computing infrastructure. Pose detection inference, audio synthesis, graphics rendering, and data storage all occur locally on the patient's device.

---

### 20. Have you done any research on similar patents, publications, or technologies?

Yes. A review of existing literature and technologies confirms that while adjacent work exists in gamified rehabilitation and exergames, no existing solution combines smartphone-based pose estimation with gamified burn rehabilitation for at-home shoulder and axilla recovery.

**Gamified Exergames in Burn Rehabilitation**

A 2025 systematic review on exergames in burn patient rehabilitation (published in MDPI) found that integrating exergames into rehabilitation programs enhances functional gains and treatment adherence, with remarkable and sustained adherence across all included studies and no adverse events. However, the exergame systems studied relied on specialized hardware such as the Nintendo Wii, Microsoft Kinect, or VR headsets — all of which impose cost, setup, and accessibility barriers unsuitable for unsupervised at-home use by burn patients. MusicArc eliminates this hardware requirement entirely by using only the iPhone's front-facing camera.

**VR-Based Home Rehabilitation for Burns**

A 2024 randomized controlled trial from the University of Washington evaluated home-based virtual rehabilitation (HBVR) for burn patients over 5 years. The study found overall adherence was low — only 37.2% in the VR group — with patients citing lack of time, lack of engagement, and the burden of specialized equipment as reasons for nonadherence. This directly validates MusicArc's design decision to use a device patients already own (iPhone) and to focus on intrinsic engagement through a nature-growth metaphor rather than relying on VR novelty alone.

**VR for Pain and Anxiety in Burns**

A 2022 systematic review in the Archives of Physical Medicine and Rehabilitation found that VR reduces anxiety and depressive symptoms and improves treatment adherence in burn patients. While this supports the broader principle of interactive technology in burn care, these VR interventions focus on pain distraction during wound care rather than long-term exercise adherence at home — a fundamentally different use case that MusicArc addresses.

**Gamification in Musculoskeletal Rehabilitation**

Broader literature on gamification in musculoskeletal rehabilitation (2023, PMC) demonstrates improvements in motivation, adherence, and quality of life. However, these studies focus on general musculoskeletal conditions and do not address the unique challenges of burn rehabilitation — specifically the painful stretching of healing scar tissue in the shoulder and axilla region, where the psychological barrier to exercise is substantially higher than in typical musculoskeletal rehab.

**Smartphone Pose Estimation for Rehabilitation**

While smartphone camera-based pose estimation using frameworks like Apple's Vision or Google's MediaPipe has been explored in general physical therapy contexts, no existing application or patent applies this technology specifically to burn rehabilitation exercise tracking. Existing pose-estimation rehab apps focus on general joint angle measurement or post-surgical recovery and do not incorporate gamification, procedural audio feedback, or the dual-phase active/rest mechanics that are clinically essential for burn recovery protocols.

**Key Differentiators from Existing Work**

No existing patent, publication, or technology combines all of the following in a single system:
1. Smartphone-only camera-based pose tracking (no additional hardware)
2. Gamification specifically designed for burn recovery stretching exercises
3. Mechanical enforcement of rest periods between stretches
4. Procedural audio synthesis as real-time positive reinforcement
5. Persistent session tracking for clinician review of at-home adherence
6. Individual calibration to the patient's current range of motion

---

### 16. Were generative AI tools used?

No.
