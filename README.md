# MonkeyThrive

**Offline Wellness · Natural Calm · Autonomous Regulation**

A privacy-first, open-source nervous system regulation toolkit for trauma survivors and anyone reclaiming self-regulation.  
Built from lived experience. For everyone who is still here.

Site: [monkeythrive.app](https://monkeythrive.app) · Source: [github.com/Is0cre/MonkeyThrive](https://github.com/Is0cre/MonkeyThrive)

---

## What it is

**MonkeyThrive** is a collection of evidence-informed tools for nervous system regulation: breathing, grounding, vagal cues, and bilateral stimulation. It runs as a standalone Android APK and as a zero-telemetry PWA. The release app is built to work with no network permission and no Google Play Services.

It is not a wellness startup. It is not a data business. It does not track engagement or optimize for retention. It succeeds when the person using it needs it less.

MonkeyThrive is a supportive self-regulation tool. It does not replace professional therapy, and it does not diagnose, assess, or treat any condition.

---

## Taming the Storm

The first open is a two-page introduction, then the body.

1. **Tame the Storm.** The nervous system can feel like weather you did not choose. Taming it means learning the shape of that weather: when to slow down, when to stay, and when a tool stays closed. Like Sun Wukong learning to hold his own chaos, this is practice in self-regulation.
2. **Zero Tracking. Zero Guilt.** Check-ins, journal entries, and sensor readings stay on this device. There is no account, no streak, and no score for the days you were away.

**Anchor your baseline** leaves the introduction and opens the Somatic Body Map. There is no questionnaire.

---

## Who it is for

- Trauma survivors, including people living with PTSD or CPTSD
- People who cannot access or afford therapy
- People in places where mental health support is stigmatized or unavailable
- Privacy-conscious users on de-Googled Android (GrapheneOS, CalyxOS, SailfishOS)
- Anyone who wants offline self-regulation tools

---

## What makes it different

- **Privacy by architecture.** The release manifest removes `INTERNET` and `ACCESS_NETWORK_STATE`. No Firebase, no analytics SDK, no crash tracker. The core app makes no network request.
- **Clinically gated.** Window of Tolerance rules decide which tools open. The gates are fixed. They are not a score.
- **Google-independent.** No Play Services. Install the APK, or use the PWA.
- **No guilt mechanics.** No streaks, no daily goals, no “you have been away” prompts.
- **You can leave with your data.** A passphrase-sealed file can move a history between devices. Nothing is uploaded.

A call or text from the offline crisis directory opens the phone dialer or messages app. That route uses the carrier. The app itself still has no network stack.

---

## Somatic Body Map

The check-in is interoceptive. Four zones can be marked: **head, throat, chest, stomach**. Each tap moves a zone through unmarked, tight, and heavy.

The map produces one Window of Tolerance reading. The person sees “this reads as …” and continues only after that reading is on screen. This is not a diagnosis.

| Marks | Reading | What opens |
| :--- | :--- | :--- |
| Tightness in any marked zone, including a tie with heaviness | Overwhelmed | Down-regulation tools. Processing tools stay closed. |
| Heaviness in more zones than tightness | Flat or numb | Orienting tools. Processing tools stay closed. |
| **Nothing stands out**, chosen explicitly | Present | The full set, still subject to each tool’s own safety screen. |
| Empty map | No reading | Continue stays closed. An unmarked body is not treated as present. |

The same three states can be corrected later from Monitor. That correction uses the same locks.

---

## Tools

### Regulate and Attune (Tier 1, always on the bar)

- **Box breathing.** A 3, 4, or 5 count, with a visual pace and haptics.
- **Physiological sigh.** Double inhale, long exhale.
- **4-7-8 breathing.** Available when the reading is present.
- **Wim Hof rounds.** Available when the reading is present, and only after the per-session confirmations.
- **5-4-3-2-1 grounding.**
- **Cold water / diving reflex.** A 30-second timer.
- **Safe place.** Stored on the device. Available when the reading is present.
- **Vagal cues.** Humming, gargling, extended exhale.
- **Anchor.** The panic path, docked in the bottom bar. See below.

Attune’s synthesized tones, binaural beats, and isochronic layers stay behind calibration so a session cannot open on an untested acoustic trigger.

### Monitor, Build, and Reflect (Tier 2)

These unlock after at least three completed Regulate or Attune sessions. Once open, they stay open.

- Monitor holds the Window of Tolerance history and a later state correction.
- Build is the on-device journal.
- Reflect is the local record of sessions and check-ins, and one place to export or import that record.

### Process (Tier 3)

Process unlocks after Tier 2, and after either three journal sessions or five Window of Tolerance check-ins. Once open, it stays open.

- **Bilateral stimulation** for between-session grounding. Visual and tactile modes run today. Acoustic modes stay behind the same calibration gate as Attune.
- The screen states that this is bilateral stimulation, and that MonkeyThrive does not replace professional therapy.

---

## Hardware panic trigger

The Anchor sits in the center of the bottom bar, in the safe area, on the shell and on tool screens. It does not float over the page.

On Android, **Volume Up** or **Volume Down** opens the same path. The activity gives the key to Flutter, then consumes it so the ringer does not change. A key that is held down does not stack another screen. The web build registers the same listener and does nothing harmful when a browser never delivers those keys.

What happens next:

1. Active audio, vibration, and timers stop.
2. A fullscreen route covers every card, menu, and choice.
3. The screen is OLED black (`#000000`). For three physiological sighs the only figure is a dim amber circle. It grows on the double inhale and shrinks on the long exhale. A short haptic marks the start of each breath phase when the device can vibrate.
4. Words stay off until the three cycles finish. Then the screen offers time, a way back to Regulate, and the offline crisis directory.

Pacing for each cycle: 3.0s first inhale, 1.2s second inhale, 6.0s exhale, 0.8s between cycles.

---

## Local data portability

Settings → Your data, and Reflect, both have **Export** and **Import**.

Export asks for a passphrase of at least 8 characters, entered twice. The passphrase is not saved. The sealed token looks like this:

- Prefix `MT1.`
- AES-256-CBC ciphertext
- HMAC-SHA256 over the IV and ciphertext (encrypt-then-MAC)
- Key from PBKDF2-HMAC-SHA256, 120,000 iterations, 16-byte salt, 16-byte IV

**Save file and copy** writes `monkeythrive-backup.mtbackup` to the app documents directory on Android, or downloads it in the browser, and puts the same token on the clipboard.

Import restores that token onto this device and replaces the local journal, check-ins, session log, and preferences. The per-install device secret is not inside the file, so a restore does not depend on the old installation. A wrong passphrase does not open the copy. Nothing is uploaded.

---

## Clinical safety

Read [docs/clinical_governance.md](docs/clinical_governance.md) before changing a gate. The person using the app is the authority on their internal experience. The app must not infer anxiety, depression, panic, dissociation, trauma, or suicidal intent. The reading on the body map is a routing label for tool access.

### Window of Tolerance

| State | Closed until the reading is present | Why |
| :--- | :--- | :--- |
| Overwhelmed | 4-7-8, Wim Hof, Safe place, Bilateral stimulation | Acute charge needs a down-shift. Processing and long holds wait. |
| Present | None of those four, beyond each tool’s own screen | The nervous system can hold a wider toolset. |
| Flat or numb | 4-7-8, Wim Hof, Safe place, Bilateral stimulation | Freeze needs orienting. Sedating breath-holds and imagery wait. |

Box breathing, the physiological sigh, 5-4-3-2-1, cold water, and vagal cues stay available in every state. The Anchor stays available in every state.

### Wim Hof

Every round starts from a present reading and these confirmations:

- I am not in water, driving, or standing.
- I am lying down or seated somewhere safe.
- I do not have a seizure disorder.
- I do not have a serious heart, blood pressure, or respiratory condition.
- I am not pregnant.
- If this is my first time, another person is nearby.
- I will stop immediately if I feel unwell.

### Bilateral stimulation

Labeled as bilateral stimulation for grounding. It is not offered as a full EMDR protocol. It opens only from a present reading, and the clinical disclaimer stays on screen.

### Safety comments

Safety-critical code carries a block in this shape. Leave it in place when you change the code around it.

```dart
// CLINICAL SAFETY — [function name]
// What this does: [plain description]
// Why it exists: [clinical reasoning]
// What happens if removed or modified: [consequence]
// Informed by: [source]
```

---

## Privacy architecture

- Release Android builds strip `INTERNET` and `ACCESS_NETWORK_STATE`. Debug and profile manifests may still allow a development connection.
- Records stay in on-device storage. There is no account and no sync server.
- The portable file is the AES layer described above. Moving it is a deliberate act by the person who knows the passphrase.
- The offline crisis directory is stored in the app. Country choice is a local preference. Links are `tel:` and `sms:` only.

---

## Tech stack

- Flutter 3.44.4. One codebase for Android and web.
- `vibration` for haptics on the sigh, breath pacing, and bilateral tactile mode.
- `shared_preferences` for on-device settings and logs.
- `encrypt` for the passphrase seal only. It does not add a network client.
- PWA assets are bundled in the build (`--no-web-resources-cdn`). The app is served at `/app/`. The static landing page is served at `/`.

---

## Build and run

Run these from `thrives_app`. A build started at the repository root fails because that directory has no `pubspec.yaml`.

### Android APK, for a handset

```bash
cd thrives_app
flutter pub get
flutter build apk --release
```

The APK is written to:

```text
thrives_app/build/app/outputs/flutter-apk/app-release.apk
```

Side-load it, with the device in the `adb devices` list:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

On the handset, press Volume Up or Volume Down from any screen and confirm the black sigh opens and the ringer does not change. The web build cannot verify that hardware path.

### PWA, for GitHub Pages

```bash
cd thrives_app
flutter pub get
flutter build web --release --no-web-resources-cdn --base-href "/app/"
```

Output: `thrives_app/build/web/`.

The base href is `/app/` with both slashes. The landing page in `web_landing/` occupies the domain root, and the Flutter app occupies `/app/`. Publishing `build/web` as the site root will break asset paths. [`.github/workflows/deploy_pwa.yml`](.github/workflows/deploy_pwa.yml) performs this build, copies the landing page to the publish root, and deploys on push to `main`.

| Platform | How to install | Status |
| :--- | :--- | :--- |
| Web / PWA | [monkeythrive.app/app/](https://monkeythrive.app/app/) | Deployed from `main` |
| Android | GitHub Release APK, or the command above | Release builds from this tree |
| De-Googled Android | Same APK | F-Droid listing is planned |
| iOS | PWA via Safari, Add to Home Screen | Supported as a PWA |

---

## Contributing

There is no separate contributing guide yet. Before a pull request:

- Dependencies stay offline and free of telemetry.
- `// CLINICAL SAFETY` blocks stay, and a change to a gate needs a clinical reason. Start at [docs/clinical_governance.md](docs/clinical_governance.md).
- New code should build on Flutter 3.44.4.

---

## License

[GPL-3.0-only](LICENSE).

MonkeyThrive is built for personal nervous system care and healing.

Built from lived experience. For everyone who is still here.
