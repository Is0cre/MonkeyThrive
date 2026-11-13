# THRIVES — Privacy Architecture

## The One Sentence Version
Big tech, advertisers, insurance companies, employers, and intelligence agencies get nothing. By design. Verifiably.

---

## Why This Matters More Than Usual
Trauma and mental health data is among the most sensitive data that exists.
- Insurance companies use it to deny coverage
- Employers use it in hiring decisions
- Governments use it for surveillance and control
- Advertisers exploit it for targeting vulnerable people
- Intelligence agencies harvest it for profiling

THRIVES must make collection architecturally impossible — not just against policy.

---

## Hard Rules — Never Violate

| Rule | Detail |
|------|--------|
| No Firebase | No analytics, no Crashlytics, no Auth, nothing |
| No Google Analytics | Nothing from Google that phones home |
| No Sentry / Bugsnag | No crash reporting that leaves device |
| No advertising ID | Explicitly opted out in AndroidManifest |
| No unnecessary permissions | Every permission justified and minimal |
| No CDN dependencies | No Google Fonts, no external JS in PWA |
| No cookies (core app) | PWA session only if user uses optional sync |

---

## Encryption Standards
- All user data: AES-256 at rest
- Journal entries: encrypted with user-derived key
- Cloud sync: end-to-end encrypted before leaving device
- Keys: never leave device, no key escrow
- If user loses key: data unrecoverable — this is correct behaviour

---

## Build Integrity
- Reproducible builds — compiled APK verifiably matches source
- All Flutter packages audited before inclusion — see stack/flutter_packages.md
- No proprietary components in core features
- CI/CD pipeline includes network monitoring to verify zero external calls

---

## For De-Googled Android Users
- Full functionality without Google Play Services
- APK available direct from GitHub releases
- F-Droid repository maintained
- Wearable data via Gadgetbridge where possible

---

## PWA Hardening
- All assets self-hosted on user's Proxmox
- Strict Content Security Policy headers
- No external scripts
- No tracking pixels
- Passes Blacklight privacy inspection (verify before launch)
- HTTPS enforced

---

## Legal Statement (In-App)
"We cannot provide your data to third parties, law enforcement, or intelligence agencies because we do not have it. Your data lives on your device."

---

## Licence
GPL-3.0-only. See [LICENSE](LICENSE). MonkeyThrive is built for personal nervous system care and healing.

---

## Threat Model
| Threat | Mitigation |
|--------|-----------|
| Google data harvesting | No Play Services dependency, no Firebase |
| App store surveillance | F-Droid + direct APK available |
| Device seizure/forensics | AES-256 encryption with user key |
| Legal requests to developer | Nothing to hand over — we hold no data |
| Malicious dependency | Package audit, reproducible builds |
| Network interception | Certificate pinning on sync, HTTPS enforced |
| State-level surveillance | Open source verifiability, no backdoors possible |
