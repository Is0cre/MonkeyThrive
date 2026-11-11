# THRIVES

**T**apping · **H**RV · **R**espiration · **I**sochronic · **V**agal · **E**MDR · **S**olfeggio

A privacy-first, open source nervous system regulation platform for Android and web.  
Built from lived experience. For everyone who is still here.

---

## What it is

THRIVES is a trauma regulation toolkit — not a wellness startup, not a data business.  
It exists because the person building it needed it, and couldn't find anything that respected their privacy.

**No data collected. No ads. No accounts required. No gamification. Free forever.**

---

## Features (v0.1)

### 🌊 Regulate
Immediate tools for when you are overwhelmed, anxious, or activated.

- Box Breathing (3/4/5 count, animated circle, haptic)
- 4-7-8 Breathing
- Wim Hof guided rounds with Window of Tolerance lock and per-session safety confirmations
- 5-4-3-2-1 Sensory Grounding
- Cold Water / Diving Reflex (30s timer)
- Safe Place Visualisation (locally stored, 5/10 min guided)
- Vagal Nerve Activation (humming, gargling, extended exhale, diving reflex)

### 🔄 Process
Deeper work — use when regulated and ready.

- Bilateral Stimulation
  - Visual (smooth animated dot with easing)
  - Tactile (alternating vibration)
  - Audio (bilateral — wired, audio assets TBD)
  - Speed, dot size, and colour controls
  - Session timer (5–30 min or open)

### 🎵 Attune
Sound and frequency entrainment.

- Binaural Beats — generated in Dart, no files needed (requires headphones)
  - Delta 2 Hz · Theta 6 Hz · Alpha 10 Hz · Beta 20 Hz
  - Carrier frequency 100–400 Hz
- Isochronic Tones — generated in Dart, works on speakers
- Nature Sounds — add your own files to `assets/audio/nature/` (see below)

### 📊 Monitor
- Window of Tolerance check-in (hyperarousal / regulated / hypoarousal)
- Session and check-in history, stored locally

---

## Privacy

```
Zero analytics. Zero crash reporting. Zero network requests from the core app.
No Firebase. No Google Analytics. No third-party SDKs that phone home.
```

Everything lives on your device. We cannot hand over data we do not hold.  
This is verifiable — the source is here.

Works without Google Play Services (GrapheneOS, CalyxOS, SailfishOS compatible).

Baseline check-ins are local prompts driven by future local sensor decisions.
They ask only whether you feel okay and store encrypted feedback for personal
baseline modelling. They do not diagnose, warn, score, or remind.

---

## Tech stack

- **Flutter 3.27** — Android + PWA from a single codebase
- **just_audio** — audio playback and tone generation
- **shared_preferences** — local storage for preferences and history
- **crypto** — authenticated local encryption for baseline feedback records
- **vibration** — tactile bilateral stimulation

---

## Building

```bash
# Install Flutter 3.27+
# https://docs.flutter.dev/get-started/install

# Clone
git clone https://github.com/Is0cre/THRIVE.git
cd THRIVE

# Install dependencies
flutter pub get

# Run (connected device or emulator)
flutter run

# Build Android APK
flutter build apk --release

# Build web (PWA)
flutter build web --no-web-resources-cdn
```

---

## Adding nature sounds

Nature sounds are loaded from `assets/audio/nature/`. The app looks for:

```
assets/audio/nature/rain.mp3
assets/audio/nature/ocean.mp3
assets/audio/nature/forest.mp3
assets/audio/nature/river.mp3
assets/audio/nature/thunder.mp3
assets/audio/nature/wind.mp3
```

Good sources for Creative Commons audio:
- [freesound.org](https://freesound.org) — filter by CC0 licence
- [soundsnap.com](https://soundsnap.com)

After adding files, declare them in `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/audio/
    - assets/audio/nature/
```

---

## PWA deployment (self-hosted / Proxmox)

```bash
flutter build web --no-web-resources-cdn

# Serve the build/web/ directory with any static file server
# nginx example: set root to build/web/
# Recommended: add a strict Content-Security-Policy header
```

The PWA installs on iPhone via Safari → Share → Add to Home Screen.

---

## Licence

GPL-3.0 for individuals and open source projects.  
Commercial licence required for institutional or corporate use — contact via GitHub.

**Military and intelligence use prohibited — all nations, without exception.**

---

## Contributing

Issues and PRs welcome. Please read the privacy constraints before adding dependencies — every package must be audited for telemetry before inclusion.

Core rule: **no code that phones home, ever.**

---

*Built from lived experience. For everyone who is still here.*
