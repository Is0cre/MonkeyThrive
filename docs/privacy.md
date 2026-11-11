# Privacy Architecture

THRIVES is private by default and offline-first by design. Privacy is not a settings toggle. It is a system constraint.

## Hard Requirements

- No analytics.
- No telemetry.
- No Firebase.
- No crash reporting.
- No mandatory cloud.
- No hidden network calls.
- No automatic upload.
- No third-party behavior tracking.
- No remote user profiling.
- Local AI only.
- User owns all data.
- Sensitive data is encrypted at rest.
- Deletion must delete user data, not merely hide it.

## Local Data

Sensitive local data includes:

- Journal entries.
- Self check-ins.
- Baseline feedback.
- Sensor trends.
- Sleep data.
- HRV data.
- Medication events.
- Intervention history.
- AI summaries.
- Safety check responses where clinically relevant.

Sensitive data must be stored in encrypted local storage. Plain SharedPreferences is acceptable only for non-sensitive UI preferences and low-risk operational state.

## Network Policy

Network access must be treated as exceptional. Any feature that makes a network request must be documented, user-visible, and optional.

Allowed network use:

- Explicit user-initiated local LLM model download.
- Explicit user-initiated encrypted export to a destination the user chooses.

Not allowed:

- Analytics beacons.
- Crash reporting.
- Remote config.
- A/B testing.
- Push-driven engagement loops.
- Background model download without user confirmation.
- Silent clinical data upload.

## LLM Packaging And Download

Release APKs must not include LLM model weights. Model files must be acquired after app startup through an explicit user action. The app should prefer Wi-Fi download and must show size, source, and license constraints before download.

If the user declines model download, the app must remain usable. The LLM is optional. Core regulation and safety features must not require a model.

## Baseline Data

Baseline data exists to compare a user against their own historical pattern. It must never compare the user against other users. It must never produce mental health scores. It must never diagnose.

## Medication Timeline

Medication events are optional and user-entered. THRIVES must never recommend medication, tell a user to stop medication, or label misuse.

Allowed neutral observation:

> Your recorded use of rescue medication is higher than your usual pattern.

Disallowed:

- "You are misusing medication."
- "You should take medication."
- "You should stop medication."
- "This looks like addiction."

## Clinical Export

Future export must be:

- Explicit.
- Granular.
- Encrypted.
- User-controlled.
- Reversible before final confirmation.

Export categories must be selectable:

- Sensor trends.
- Sleep.
- HRV.
- Medication timeline.
- Intervention history.
- Self check-ins.
- Journal.
- AI summaries.

Nothing is exported by default.
