# MonkeyThrive

**Offline Wellness · Natural Calm · Autonomous Regulation**

A privacy-first, open-source nervous system regulation toolkit for trauma survivors and anyone reclaiming self-regulation.  
Built from lived experience. For everyone who is still here.

---

## What it is

**MonkeyThrive** is a collection of evidence-informed tools for nervous system regulation — breathing techniques, grounding protocols, vagal nerve activation, and bilateral stimulation. It runs natively on Android, works as a zero-telemetry PWA across desktop and mobile, and is architected to operate entirely without Google Play Services or network connectivity.

It is not a wellness startup. It is not a data business. It does not track engagement or optimize for retention. It succeeds when the person using it needs it less.

---

## Who it is for

- Trauma survivors, PTSD, and CPTSD individuals
- People who cannot access or afford therapy
- People in environments where mental health support is stigmatized or unavailable
- Privacy-conscious users on de-Googled Android (GrapheneOS, CalyxOS, SailfishOS)
- Anyone seeking uncompromised, offline self-regulation tools

---

## What makes it different

- **Privacy by Architecture, Not Policy:** Zero network requests from the core app. Network permissions (`INTERNET`, `ACCESS_NETWORK_STATE`) are stripped from the Android manifest. No Firebase, no analytics SDKs, no crash trackers. Verified via open source.
- **Clinically Informed:** Designed with clinical safety constraints. Safety-critical functions include documented rationales. Safety gates are mandatory.
- **Google-Independent:** Zero dependency on Google Play Services. Distributed as a standalone APK and deployable via static hosting.
- **No Guilt Mechanics:** No streaks. No daily goals. No "you've been away" prompts. The app holds no memory of absence.
- **Adaptive Baseline Modeling:** Local, user-consented check-ins to monitor regulation over time. Data stays strictly on-device.

---

## Features

### Regulate (Tier 1 — Always Available)
- **Box Breathing:** 3/4/5 count, visual pacing, tactile haptics.
- **Physiological Sigh:** Double inhale + extended exhale (rapid acute autonomic stabilization).
- **4-7-8 Breathing:** Parasympathetic pacing.
- **Wim Hof Guided Rounds:** Structured rounds with strict physiological gating (see Clinical Safety).
- **5-4-3-2-1 Sensory Grounding:** Guided orienting protocol.
- **Cold Water / Diving Reflex:** 30-second somatic reset timer.
- **Safe Place Visualization:** Stored locally on-device.
- **Vagal Nerve Activation:** Humming, gargling, extended exhale cues.
- **Panic Button:** Prominent, instant-access anchor triggering a physiological sigh.

### Process (Tier 2 — Requires Regulated Baseline)
- **Bilateral Stimulation (BLS):** Visual and tactile modes for between-session grounding.
- Explicitly not marketed or labeled as full EMDR in UI (see Clinical Safety).
- Session prerequisite disclaimer: *"MonkeyThrive is a supportive self-regulation tool. It does not replace professional therapy."*

### Attune (Audio Synthesis — In Development)
- **Status:** *Currently gated behind calibration.* Pure Dart/synthesized binaural beats, isochronic pacing, and acoustic layers are undergoing deterministic testing to eliminate sudden acoustic triggers before public release.

### Monitor
- **Window of Tolerance Check-in:** Routes available tools based on somatic state (Hyperarousal, Regulated, Hypoarousal).
- **Local History:** Encrypted, on-device session records.

---

## Clinical Safety

MonkeyThrive is open source. Contributors and forkers must understand the clinical reasoning behind state gates prior to modifying code.

### Window of Tolerance Gating
Before sensitive exercises, users evaluate their state: **Overwhelmed (Hyperaroused)**, **Present (Regulated)**, or **Flat / Numb (Hypoaroused)**.

| State | Gated / Locked Modules | Clinical Rationale |
| :--- | :--- | :--- |
| **Overwhelmed** *(Hyperarousal)* | 4-7-8, Wim Hof, Safe Place, Bilateral Processing | Acute panic requires immediate physiological down-regulation, not cognitive or trauma processing. |
| **Present** *(Regulated)* | None (All modules accessible) | Nervous system is resilient enough for processing and expansion. |
| **Flat / Numb** *(Hypoarousal / Freeze)* | 4-7-8, Wim Hof, Safe Place, Bilateral Processing | Deep freeze states require gentle somatic sensory orienting, not sedative breathwork or cognitive imagery. |

### Wim Hof Safety Gating
Before every breathwork round involving hyperventilation, the user must explicitly confirm:
- Not currently overwhelmed or in freeze
- Not pregnant
- No history of cardiovascular conditions, epilepsy, seizures, or respiratory distress
- Positioned in a physically safe environment (lying down, away from water)

### Bilateral Stimulation Rules
- Labeled clearly as bilateral stimulation for grounding, never full clinical EMDR.
- Strictly gated to users currently in a regulated state.
- Always displays clinical disclaimers regarding professional care.

### Codebase Comment Blocks
Safety-critical functions contain explicit safety documentation:
```dart
// CLINICAL SAFETY — [function name]
// What this does: [plain description]
// Why it exists: [clinical reasoning]
// What happens if removed or modified: [consequence]
// Informed by: [source]
Do not alter safety-critical paths without addressing and preserving these safety blocks.Privacy ArchitectureZero Network Permissions: INTERNET and network state queries removed.Local Storage Only: Data is written locally using encrypted preferences and secure storage.Reproducible & Verifiable: Auditable codebase with clear package constraints.Permissive Open Source: Licensed under GPL-3.0 with ethical safety boundaries.Tech StackFlutter 3.27+: Unified mobile and web codebase.vibration: Tactile haptic feedback for bilateral stimulation and breath pacing.shared_preferences: Encrypted local state and settings persistence.PWA Deployment: Static export deployed to GitHub Pages (monkeythrive.app).Build & RunAndroid APKBashcd thrives_app
flutter build apk --release
The output APK is generated at build/app/outputs/flutter-apk/app-release.apk.Progressive Web App (PWA)Bashcd thrives_app
flutter build web --release --no-web-resources-cdn --base-href "/"
Platform AvailabilityPlatformDistribution ChannelStatusWeb / PWAHosted at monkeythrive.appLive / DeployableAndroid (Standalone)Direct APK release / GitHub ReleasesWorkingAndroid (De-Googled)F-Droid inclusionPlannediOSPWA via Safari ("Add to Home Screen")SupportedContributingReview CONTRIBUTING.md before submitting pull requests.Dependencies must be verified zero-telemetry, offline-first, and leak-free.Safety blocks (// CLINICAL SAFETY) cannot be removed or weakened.PRs altering somatic pacing or state routing require clinical rationale review.LicenseGPL-3.0. See LICENSE for details.Built from lived experience. For everyone who is still here.
