# THRIVES

**Tapping · HRV · Respiration · Isochronic · Vagal · Bilateral Stimulation · Solfeggio**

A privacy-first, open source nervous system regulation platform for trauma survivors and anyone who needs it.

*Built from lived experience. For everyone who is still here.*

---

## What it is

THRIVES is a collection of evidence-informed tools for nervous system regulation — breathing techniques, grounding protocols, vagal nerve activation, bilateral stimulation, and brainwave entrainment. It runs on Android, works as a PWA on iPhone and desktop, and is designed to work without Google Play Services.

It is not a wellness startup. It is not a data business. It does not track engagement or optimise for retention. It succeeds when the person using it needs it less.

## Who it is for

- Trauma survivors, PTSD and CPTSD sufferers
- People who cannot access therapy, or cannot afford it
- People in countries where mental health support is stigmatised or unavailable
- Privacy-conscious users on de-Googled Android (GrapheneOS, CalyxOS, SailfishOS)
- Anyone who has very good reasons not to trust systems that collect sensitive data

## What makes it different

**Privacy by architecture, not policy.** Zero network requests from the core app. No analytics SDK. No crash reporting. No Firebase. Nothing to subpoena. Verified via open source.

**Clinically informed.** Built with input from practicing psychologists. Every safety-critical function has a documented clinical rationale. Safety gates are not optional.

**Works without Google.** No dependency on Google Play Services. APK available directly and via F-Droid.

**No guilt mechanics.** No streaks. No daily goals. No "you've been away for X days." The app has no memory of absence. A person who hasn't opened it in three weeks is welcomed back the same as someone who opened it this morning.

**Adaptive baseline feedback.** Future local sensor decisions can trigger a quiet check-in asking whether the user feels okay. Feedback is stored locally and encrypted for personal baseline modelling only; it is not a mood tracker or diagnostic feature.

---

## Features

### Regulate (Tier 1 — always available)
- Box breathing (3/4/5 count, animated, haptic)
- Physiological sigh (double inhale + long exhale — fastest known acute stress reset)
- 4-7-8 breathing
- Wim Hof guided rounds (with mandatory safety gates — see Clinical Safety below)
- 5-4-3-2-1 sensory grounding
- Cold water / diving reflex (30s timer)
- Safe place visualisation (locally stored description)
- Vagal nerve activation (humming, gargling, extended exhale)
- Panic button — always visible, one tap, auto-plays physiological sigh immediately

### Process (Tier 2 — requires regulated state)
- Bilateral stimulation — visual, audio, and tactile modes
- Not labelled as EMDR anywhere in the UI (see Clinical Safety)
- Session always opens with: "This is a support tool. It does not replace therapy."

### Attune
- Binaural beats (Delta / Theta / Alpha / Beta)
- Isochronic tones
- Nature sounds (layerable with tones)
- All tones generated in Dart — no audio asset files required

### Monitor
- Window of Tolerance check-in — gates tool availability by current state
- Check-in history
- Session history

---

## Clinical Safety

This section exists because THRIVES is open source. Contributors and forkers must understand what they are changing and why before they change it.

### Window of Tolerance gating

Before each session, the user checks in: overwhelmed / present / flat or numb. The app routes accordingly. This is not a UX choice — it is the clinical intervention.

| State | Locked tools |
|-------|-------------|
| Overwhelmed (hyperaroused) | 4-7-8, Wim Hof, Safe place, Bilateral stimulation |
| Present (regulated) | None (all available) |
| Flat or numb (hypoaroused) | 4-7-8, Wim Hof, Safe place, Bilateral stimulation |

Wrong tool in wrong state deepens dysregulation. A person in freeze does not need more calming. A person in panic does not need processing tools.

### Wim Hof safety gates

Every single session, without exception, the user must confirm:
- Not currently overwhelmed or flat/numb
- Not pregnant
- No cardiovascular conditions
- No epilepsy or seizure history
- No respiratory conditions
- Lying down in a safe environment
- Not near water
- Not alone for the first time

This cannot be bypassed. Wim Hof involves deliberate hyperventilation and breath retention. SpO2 can drop to dangerous levels. Fainting is not uncommon.

### Bilateral stimulation

- Never labelled as EMDR anywhere in the UI
- Always labelled: "bilateral stimulation — between-session support, not therapy"
- Only available in regulated state
- Session always opens with: "This is a support tool. It does not replace therapy."
- Full EMDR requires a trained therapist. This tool does not replicate that.

### Clinical comment blocks

Every safety-critical function in the codebase includes:

```dart
// CLINICAL SAFETY — [function name]
// What this does: [plain description]
// Why it exists: [clinical reasoning]
// What happens if removed or modified: [consequence]
// Informed by: [source]
```

Do not remove these. Do not modify safety-critical behaviour without understanding these blocks.

---

## Privacy architecture

- Zero network requests from the core app. Ever.
- No Firebase. No Google Analytics. No crash reporting. No third-party SDKs.
- All user data stored on-device only
- AES-256 encryption for sensitive data (vault, when built)
- Optional sync uses user-provided endpoint (Nextcloud, S3-compatible) — server never sees unencrypted data
- Reproducible builds — anyone can verify the compiled APK matches this source
- GPL licence — forks must remain open source

We cannot hand over what we do not hold.

---

## Tech stack

- Flutter 3.27+ — Android and PWA from a single codebase
- `just_audio` — audio playback and tone generation
- `shared_preferences` — local storage
- `vibration` — tactile bilateral stimulation
- Audio tones generated in Dart — no bundled audio assets required

No package is added without auditing for telemetry. See [CLAUDE.md](CLAUDE.md) for the dependency rule.

## Build

```bash
# Install Flutter 3.27+
# https://flutter.dev/docs/get-started/install

# Android APK
flutter build apk --release

# PWA (deploy build/web/ to any static host)
flutter build web --no-web-resources-cdn
```

## Platform targets

| Platform | Method | Status |
|----------|--------|--------|
| Android | Flutter + APK / Google Play | In development |
| Android (de-Googled) | APK direct + F-Droid | Planned |
| iPhone / iOS | PWA via Safari | Working |
| Desktop browser | PWA | Working |
| SailfishOS | Native Qt/QML port | Planned post-MVP |

---

## Contributing

Read [CLAUDE.md](CLAUDE.md) before touching anything clinical.

Before adding a dependency:
1. State what it does
2. Confirm it has no telemetry, no analytics, no network calls
3. Link to source or explain how you verified this

Before modifying any function with a `// CLINICAL SAFETY` block: read the block, understand the consequence, and flag it for clinical review if you are unsure.

Clinical questions → open an issue tagged `clinical-review`.

## Prohibited uses

Military and intelligence use is prohibited. See [LICENSE](LICENSE).

---

## Funding

THRIVES is seeking funding via:
- [NLnet Foundation](https://nlnet.nl) — privacy-preserving open source tools
- [Mozilla Foundation](https://foundation.mozilla.org)
- [Open Technology Fund](https://www.opentech.fund)
- EU Horizon / Wellcome Trust (longer term)

No VC funding. No exit strategy. No data harvesting endgame.

---

## Clinical advisor

Psychology advisory board in formation. Advisory credits will appear here once confirmed.

---

## Licence

GPL-3.0 with additional prohibited use clauses for military and intelligence applications. See [LICENSE](LICENSE).

Commercial licensing for institutional use (clinics, NGOs, employers) is available — contact via GitHub issues.

---

*Built from lived experience. For everyone who is still here.*
