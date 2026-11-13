# THRIVES — Full Claude Code Build Brief

## What is THRIVES?

A biofeedback-assisted, adaptive trauma regulation platform for Android and web (PWA).
Built by someone with lived experience. Clinically informed. Fully open source. Free forever.

**T**apping **H**RV **R**espiration **I**sochronic **V**agal **E**MDR **S**olfeggio

---

## Core Philosophy

- No accounts required
- No data collection
- No ads, ever
- No gamification, no streaks, no guilt
- All data stored locally by default
- Optional encrypted cloud sync (user-controlled)
- Open source on GitHub
- Free core features, always

---

## Tech Stack

- **Flutter** — Android (Google Play) + cross-platform foundation
- **PWA** — hosted on user's own Proxmox server, iPhone/desktop browser access
- **Local storage** — all session data, preferences, journal entries stored on device
- **Optional cloud sync** — user-provided storage (Nextcloud, S3, etc.) via encrypted export
- **Wearable integration** — Google Fit / Health Connect API (WearOS, Fitbit, Garmin, Polar)
- **Camera-based HRV** — photoplethysmography via phone camera for users without wearables

---

## Onboarding Questionnaire

Shown once on first launch. Generates a personal starting profile.

### Questions:

1. **What brings you here?**
   - Sleep difficulties
   - Anxiety and stress
   - Trauma processing
   - General nervous system regulation
   - Curiosity / personal growth
   - Multiple of the above

2. **How familiar are you with these tools?**
   - Complete beginner
   - Some experience with meditation or breathing
   - Familiar with EMDR or somatic therapy
   - Experienced practitioner

3. **Do you have a smartwatch or fitness tracker?**
   - Yes (select: Apple Watch / WearOS / Garmin / Fitbit / Polar / Other)
   - No, I'll use phone camera
   - No biofeedback for now

4. **How do you prefer to work?**
   - Guide me, I'll follow suggestions
   - Give me the tools, I'll explore
   - Mix of both

5. **Sensitivity check:**
   - Flashing or moving visuals — comfortable / sometimes difficult / avoid
   - Audio stimulation — comfortable / prefer low intensity / headphones only
   - Vibration — comfortable / avoid

6. **Safety screen:**
   - Are you currently working with a therapist? (Yes / No / Not currently)
   - Are you in acute crisis right now? (Yes → routes to Regulate immediately with crisis resources)

### Output:
Generates a suggested starting category and tool set. Displayed as:

> *"Based on your responses, we suggest starting in Regulate to build your foundation. Processing tools are ready when you are — there's no rush."*

Profile is editable any time in settings.

---

## Category Structure

### 🌊 Regulate
*Immediate tools. Use when overwhelmed, anxious, or in early warning.*

- Box breathing (4-4-4-4) with animated visual pacer
- 4-7-8 breathing
- Wim Hof guided breathing
- 5-4-3-2-1 grounding protocol (sensory anchoring)
- Cold water/temperature grounding reminder with timer
- Safe place visualisation — guided text prompt with ambient audio
- Vagal nerve activation prompts:
  - Humming/singing guidance
  - Diving reflex (cold water face)
  - Gargling protocol
  - Extended exhale breathing

### 🔄 Process
*Deeper work. Trauma processing tools. Use when regulated and ready.*

- **EMDR Bilateral Stimulation:**
  - Visual — smooth moving dot, left to right
  - Adjustable speed (slow / medium / fast)
  - Adjustable dot size and colour
  - Audio bilateral — alternating tones, left/right channel (headphones)
  - Tactile — alternating phone vibration
  - Combined modes (visual + audio, visual + tactile, all three)
  - Session timer: 5 / 10 / 15 / 20 / 30 minutes
  - Gentle chime at session end
- **EFT Tapping:**
  - Guided tapping sequences with visual body map
  - Standard protocol
  - Trauma-adapted protocol
  - Custom setup phrase entry
- **Somatic Body Scan:**
  - Guided audio/text body awareness sequence
  - Adjustable pace
- **Trauma-informed Journaling:**
  - Structured prompts (optional or blank)
  - Prompt sets: processing, gratitude, window of tolerance check-in, narrative
  - All entries encrypted locally
  - Export to encrypted file

### 🎵 Attune
*Sound and frequency tools. Nervous system entrainment.*

- **Binaural Beats:**
  - Delta (0.5–4 Hz) — deep sleep, recovery
  - Theta (4–8 Hz) — deep relaxation, trauma processing
  - Alpha (8–14 Hz) — calm focus
  - Beta (14–30 Hz) — alert, grounded
  - Adjustable carrier frequency (100–400 Hz)
  - Requires headphones — clear prompt shown
- **Isochronic Tones:**
  - Same frequency bands as binaural
  - Works without headphones
  - Adjustable intensity
- **Solfeggio Frequencies:**
  - 174 Hz — pain reduction, security
  - 285 Hz — tissue healing
  - 396 Hz — releasing fear and guilt
  - 417 Hz — change and transformation
  - 528 Hz — DNA repair, love frequency
  - 639 Hz — relationships, connection
  - 741 Hz — problem solving, expression
  - 852 Hz — intuition
  - 963 Hz — higher consciousness
- **Nature Sounds:**
  - Rain, ocean waves, forest, river, thunderstorm, wind
  - Mixable with any other audio tool
- **Combinations:**
  - Binaural + nature sounds
  - Bilateral stimulation + binaural beats
  - User-saved presets

### 📊 Monitor
*Biofeedback and nervous system state tracking.*

- **HRV Monitoring:**
  - Via smartwatch (Health Connect / Google Fit API)
  - Via phone camera (photoplethysmography — finger on camera)
  - Real-time display
  - Trend over session and over time
- **Electrodermal Activity / Skin Resistance:**
  - Via compatible wearables (Garmin, Polar, Empatica where supported)
  - Stress level indicator
- **Respiration Rate:**
  - Via smartwatch or guided self-report
  - Breathing pacer synced to current rate
- **SpO2 / Oxygen Saturation:**
  - Via smartwatch where supported
- **Window of Tolerance Tracker:**
  - Simple check-in: hyperaroused / regulated / hypoaroused
  - Visual window display
  - Historical log
- **Pre-Episode Early Warning System:**
  - Continuously monitors HRV and EDA trends (when wearable connected)
  - Detects nervous system dysregulation patterns before full episode
  - Gentle notification: *"Your nervous system seems activated. Would you like to try a grounding tool?"*
  - User controls sensitivity of alerts
  - Never alarmist — always gentle and optional

### 🌱 Build
*Resilience building. Regular practice tools.*

- **Vagal Toning Programme:**
  - Progressive protocol for building HRV baseline over weeks
  - Daily practice suggestions (5–10 minutes)
- **Breathwork Protocols:**
  - Coherent breathing (5.5 breaths/minute — optimal HRV)
  - Extended exhale series
  - Resonance frequency breathing (personalised to user's HRV)
- **Mandala / Visual Focus:**
  - Concentration anchoring visuals
  - Customisable complexity
- **Affirmations:**
  - Default set (trauma-informed, non-toxic-positivity)
  - Fully customisable
  - Optional scheduled gentle reminders
- **Photobiomodulation Guidance:**
  - Information and timing guidance for red light exposure
  - Morning light protocol for circadian regulation

### ☁️ Reflect
*Integration and insight.*

- **Session History:**
  - Tools used, duration, biofeedback data
  - All stored locally
- **Mood and State Tracking:**
  - Simple post-session check-in
  - Visual trends over time
- **Journal Review:**
  - Encrypted local entries
  - Search and filter
- **Progress Insights:**
  - HRV baseline trend
  - Most used tools
  - No judgement, no streaks, no guilt about gaps

---

## Adaptive Intelligence

- App learns which tools the user actually opens and uses
- Suggests combinations based on biofeedback patterns
- Notices time patterns — frequently opened at 2am → suggests sleep protocol
- After 2 weeks, offers personalised *"your toolkit"* based on usage
- Never pushy — suggestions are gentle, dismissible, never repeated immediately

---

## UI/UX Design Principles

- **Dark mode default** — important for trauma users, night use, PTSD light sensitivity
- **Minimal and calm** — nothing clinical, cold, or corporate
- **Colour palette** — deep navy, soft teal, warm amber accents, muted not neon
- **Typography** — clean, readable, generous spacing
- **No notifications by default** — user explicitly opts in to any alerts
- **No streaks** — no guilt mechanics whatsoever
- **No onboarding account** — straight to questionnaire, straight to tools
- **Emergency grounding button** — always accessible from any screen, one tap
- **Crisis resources** — available in settings and via distress button, never intrusive

---

## Safety & Disclaimers

- First launch disclaimer — wellness tool, not therapy replacement
- Recommendation to use with professional support where possible
- Distress button on every screen — routes to Regulate + shows local crisis line
- Questionnaire safety screen routes acute crisis users to immediate grounding
- No clinical claims anywhere in UI or marketing
- No diagnosis, no AI assessment of mental state

---

## Privacy & Security — Hardened

### Absolute rules — no exceptions:
- **Zero analytics** — no Firebase, no Google Analytics, no Crashlytics, no Sentry, nothing
- **Zero third party SDKs that phone home** — every dependency audited before inclusion
- **Zero network requests from core app** — verified by network monitoring in CI/CD pipeline
- **No Google Play Services dependency** — app must function fully without Google Play Services installed (important for de-Googled Android like GrapheneOS, CalyxOS)
- **F-Droid compatible build** — no proprietary blobs, listed on F-Droid for users who avoid Google Play entirely
- **No crash reporting that leaves device** — crashes logged locally only, user can optionally export anonymised report manually
- **No advertising ID access** — explicitly opt out in AndroidManifest
- **No READ_CONTACTS, no location, no unnecessary permissions** — minimal permission manifest, every permission justified

### Data encryption:
- All user data AES-256 encrypted at rest
- Journal entries encrypted with user-derived key (not app-generated)
- Biofeedback session data encrypted locally
- Encryption keys never leave the device
- No key escrow — if user loses key, data is unrecoverable (by design)

### Network hardening:
- **Certificate pinning** for any optional cloud sync connections
- **No CDN dependencies** for core functionality — no Google Fonts, no external JS
- **Content Security Policy** hardened on PWA build
- All PWA assets served from user's own Proxmox — no third party hosting
- Optional cloud sync uses **end-to-end encryption** — server (even user's own) sees only encrypted blobs

### Anti-surveillance build practices:
- **Reproducible builds** — anyone can verify the compiled APK matches the source code
- **No proprietary analytics replaced with open source alternatives** — just nothing at all
- **Dependency audit** — all Flutter packages reviewed for hidden telemetry before inclusion
- **No ML Kit or Google AI APIs** — any on-device intelligence uses open models only
- **Health Connect data** — read only what is needed per session, never stored beyond session unless user explicitly saves

### For de-Googled Android users:
- Full functionality without Google Play Services
- APK available direct from GitHub releases
- F-Droid repository maintained
- Health data via open alternatives where possible (e.g. Gadgetbridge for wearables)

### PWA hardening:
- **No Google Fonts** — fonts bundled locally
- **No external scripts** — everything self-hosted
- **No tracking pixels**
- **Strict Content Security Policy** header
- **No cookies** except essential session (and only if user logs into optional sync)
- Passes **Blacklight privacy inspection**

### Legal:
- **No data broker agreements** — ever
- **No government backdoors** — open source ensures this is verifiable
- **GDPR compliant by architecture** — can't violate what you don't collect
- **Privacy policy written in plain language** — no legal obfuscation
- Explicit statement: *"We cannot provide your data to third parties, law enforcement, or intelligence agencies because we do not have it. Your data lives on your device."*

### The one sentence version:
**Big tech, advertisers, insurance companies, employers, and intelligence agencies get nothing. By design. Verifiably.**

---

## Cloud Sync (Optional)

- User provides their own storage (Nextcloud, S3-compatible, Dropbox via API)
- All data encrypted before leaving device
- Sync is opt-in, not default
- No THRIVES servers ever hold user data

---

## Wearable Integration

- **Android Health Connect** — unified API for WearOS, Fitbit, Garmin, Polar, Samsung
- **Camera PPG** — HRV via phone camera for users without wearables
- Graceful degradation — all features work without wearable, biofeedback features enhanced with one
- Supported data: HRV, heart rate, SpO2, EDA (where available), respiration rate

---

## Advisory Credits Screen

- Named psychology advisors with credentials and speciality
- Clean, professional layout
- Links to advisor profiles/institutions where permitted
- Clear statement of advisory role vs clinical endorsement

---

## Open Source

- Full codebase on GitHub under MIT or GPL licence (decide before launch)
- Contributing guidelines
- Issue tracker open to community
- No proprietary components in core features
- Community can self-host PWA version

---

## Monetisation

- **Core app: completely free, forever**
- No ads, ever
- No paywalled crisis tools
- Optional future: premium presets pack, one-time purchase, no subscription
- Tips via GitHub Sponsors or Open Collective
- No VC funding — independence is the point

---

## Deployment

- **Android:** Flutter build → Google Play ($25 one-time)
- **PWA:** Hosted on user's Proxmox server, accessible via browser on any device including iPhone
- **Self-hosted:** Docker container available for anyone to run their own instance
- **GitHub:** Full source, releases, documentation

---

## MVP Scope (Build First)

Focus on this for v0.1:

1. Onboarding questionnaire → profile
2. Regulate category — breathing tools + 5-4-3-2-1 + vagal prompts
3. Process category — EMDR bilateral stimulation (visual + audio)
4. Attune category — binaural beats + isochronic tones + nature sounds
5. Basic Monitor — camera PPG heart rate, window of tolerance manual check-in
6. Dark UI with category home screen
7. Emergency grounding button on all screens
8. Local storage for preferences
9. PWA manifest for web deployment
10. Advisory credits screen

**Leave for v0.2+:**
- Wearable API integration
- Pre-episode early warning
- EFT tapping
- Journaling
- Solfeggio
- Cloud sync
- Adaptive suggestions

---

## Notes for Claude Code

- Use **just_audio** Flutter package for all audio (supports background play, low latency)
- Use **flutter_animate** for breathing visual pacers and bilateral dot animation
- Use **health** Flutter package for Health Connect / wearable integration
- Use **camera** package for PPG heart rate via camera
- Use **flutter_secure_storage** for encrypted local data
- Use **hive** or **isar** for local database
- PWA: ensure Flutter web build includes correct manifest.json and service worker for offline use
- Test bilateral stimulation timing precision carefully — timing matters clinically
- Audio must continue when screen locks (background audio mode)
- All animations must respect system reduce-motion accessibility setting

---

*Built from lived experience. For everyone who is still here.*
