# THRIVES — Decisions Log

All architectural, technical, and product decisions with reasoning.
Read this before making any new decisions to avoid relitigating old ones.

---

## Flutter for mobile
**Decision:** Use Flutter for Android build
**Date:** Project start
**Reason:** Cross-platform, single codebase, excellent audio control, large community, good health/wearable packages available
**Alternatives considered:** React Native (weaker audio timing), Kotlin native (Android only)
**Status:** Final

---

## PWA for iOS/web instead of App Store
**Decision:** No iOS App Store. iPhone users use PWA via browser.
**Date:** Project start
**Reason:** Apple Developer Account costs $99/year forever. Against principle of free tool. Apple ecosystem is closed and extractive. PWA works fine for our use case.
**Status:** Final — not up for debate

---

## No Firebase / No Google Analytics / No crash reporting
**Decision:** Zero third party telemetry SDKs
**Date:** Project start
**Reason:** Trauma and mental health data is among the most sensitive data that exists. Insurance companies, employers, governments, advertisers want this data. Architecture must make collection impossible, not just against policy.
**Status:** Final — non-negotiable

---

## No Google Play Services dependency
**Decision:** App must function fully without Google Play Services
**Date:** Project start
**Reason:** Target users include de-Googled Android users (GrapheneOS, CalyxOS, Sailfish). These are exactly the privacy-conscious users who need this app most.
**Status:** Final

---

## F-Droid compatible build
**Decision:** Maintain F-Droid compatible build — no proprietary blobs
**Date:** Project start
**Reason:** F-Droid is the trusted app store for privacy-conscious Android users. Being listed there is a credibility signal.
**Status:** Final

---

## Local storage default, optional cloud sync
**Decision:** All data on device by default. Optional sync uses user-provided storage endpoint (Nextcloud, S3-compatible).
**Date:** Project start
**Reason:** We cannot hand over what we do not hold. Server never sees unencrypted data.
**Status:** Final

---

## AES-256 encryption for all user data
**Decision:** All journal entries, session data, biofeedback history encrypted at rest with user-derived key
**Date:** Project start
**Reason:** Device theft, forensic access, legal requests — all neutralised if data is encrypted with a key only the user holds
**Status:** Final

---

## Reproducible builds
**Decision:** Build pipeline must produce reproducible APKs — anyone can verify compiled app matches source
**Date:** Project start
**Reason:** Open source means nothing if the distributed binary could contain hidden code. Reproducible builds close that gap.
**Status:** Final

---

## GPL / dual licence model
**Decision:** Core app GPL open source. Commercial licence for institutional use.
**Date:** Project start
**Reason:** Individuals get it free. Clinics, corporates, governments who want to integrate it without open sourcing their stack pay. Protects the FOSS nature while enabling monetisation from institutions.
**Status:** Draft — confirm licence choice before first public release

---

## No military / intelligence use licence clause
**Decision:** Explicit licence clause prohibiting use by military, intelligence agencies, and government surveillance programmes of any nation
**Date:** Project start
**Reason:** Trauma data must not become a tool of surveillance or warfare. Applies equally to all nations.
**Status:** Superseded on 2026-11-13. LICENSE is the unmodified GNU GPL version 3 only.

---

## GPL-3.0-only
**Decision:** The repository license is the official GNU General Public License version 3, with no added use restrictions.
**Date:** 2026-11-13
**Reason:** F-Droid accepts GPL-3.0-only. A field-of-use ban is a further restriction and is not part of the license. The project is still built for personal nervous system care and healing.
**Status:** Final

---

## Sailfish OS native port
**Decision:** Plan a native Qt/QML Sailfish port after MVP
**Date:** Project start
**Reason:** Sailfish is a genuine Linux-based privacy-respecting mobile OS. Proper native app is better than AlienDalvik compatibility layer. Community may contribute.
**Status:** Planned post-MVP

---

## No toxic positivity / no streaks / no guilt
**Decision:** Zero gamification. No streaks. No push notifications by default. No "you've been away for X days" guilt mechanics.
**Date:** Project start
**Reason:** Trauma users do not need guilt layered on top of everything else. The app serves the user, not engagement metrics.
**Status:** Final — non-negotiable

---

## Dark mode default
**Decision:** Dark mode is the default UI, not light mode
**Date:** Project start
**Reason:** PTSD and trauma users frequently have light sensitivity. App is often used at night. Dark mode is more appropriate for the use case.
**Status:** Final

---

## Psychology advisors as named credits
**Decision:** Recruit psychology professionals as named advisors
**Date:** Project start
**Reason:** Builder has no formal degree. Advisor names with credentials increase credibility with users, app stores, grant bodies, and potential NGO clients. Does not change the builder's ownership or control.
**Status:** In progress — contacts exist, not yet formally approached

---

## NLnet Foundation as primary grant target
**Decision:** Apply to NLnet Foundation as first funding attempt
**Date:** Project start
**Reason:** NLnet specifically funds privacy-preserving open source tools. THRIVES fits their criteria precisely. Based in Netherlands, accessible from Malta. No strings attached funding.
**Status:** Todo — research open calls at nlnet.nl
