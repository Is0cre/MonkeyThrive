# THRIVES — Flutter Packages

All packages must be audited before inclusion.
Check for: hidden telemetry, Google dependencies, network calls, proprietary components.

---

## Approved Packages

| Package | Purpose | Audited | Notes |
|---------|---------|---------|-------|
| just_audio | All audio playback — binaural, bilateral, nature sounds | Pending | Background audio support, low latency |
| flutter_animate | Breathing pacers, bilateral dot animation | Pending | Pure Flutter, no network |
| health | Health Connect / wearable integration | Pending | Check for Google dependency |
| camera | PPG heart rate via camera | Pending | Local only, no upload |
| flutter_secure_storage | Encrypted local storage | Pending | AES-256 |
| hive / isar | Local database | Pending | Prefer isar for performance |
| vibration | Tactile bilateral stimulation | Pending | Simple, likely clean |
| file_selector | System file dialog for an expansion zip already on the device | 2026-11-15 | Flutter team package. Android uses `ACTION_OPEN_DOCUMENT` and adds no permission. The app manifest still removes `INTERNET` and storage. No network calls in the plugin. |

---

## Packages to Avoid

| Package | Reason |
|---------|--------|
| firebase_* | Everything Firebase — phones home, Google |
| google_mobile_ads | Obviously not |
| sentry_flutter | Crash reporting leaves device |
| amplitude_flutter | Analytics |
| mixpanel_flutter | Analytics |
| appsflyer_sdk | Attribution tracking |
| Any ML Kit package | Google dependency |

---

## Audit Process for Each Package
1. Check pub.dev for permissions requested
2. Review package source on GitHub
3. Search for network calls in source
4. Check dependencies of dependencies
5. Test with network monitor — verify zero external calls
6. Document result here

---

## Package Audit Log

### just_audio
- Status: Pending
- Checked by: —
- Network calls found: —
- Decision: —

### file_selector
- Status: Accepted for expansion packs
- Checked by: review of `file_selector` 1.1.0 and `file_selector_android` 0.5.2+11
- Network calls found: none. The Android manifest is empty. The dialog is `ACTION_OPEN_DOCUMENT`.
- Decision: Use it so a person can hand the app a zip they already saved. Do not use it to browse the network.

### flutter_secure_storage
- Status: Pending
- Checked by: —
- Network calls found: —
- Decision: —

*(Add entry for each package before including in build)*
