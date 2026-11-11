# Local LLM Design

The LLM is an observer and personalizer. It is never the safety authority.

## Role

The LLM may:

- Summarize patterns.
- Personalize wording.
- Suggest tools that have historically helped the user.
- Help the user reflect.
- Turn local data into user-readable summaries.

The LLM must not:

- Diagnose.
- Infer abuse or misuse labels.
- Recommend medication.
- Tell a user to stop medication.
- Override safety gates.
- Maximize engagement.
- Pressure the user.
- Generate fear-based notifications.
- Decide crisis handling.
- Claim objective truth about subjective or altered states.

## Deterministic Override

Deterministic rules override the LLM every time.

If the LLM suggests something unsafe, unavailable, contraindicated, or outside the user's current gate, the app must discard or constrain that output.

## Local Only

LLM inference must run locally. Prompts, journal text, check-ins, sensor summaries, and generated summaries must not be sent to a hosted model.

## APK Packaging

Release APKs must not bundle LLM model weights. The model must be downloaded only after startup by explicit user action. Wi-Fi should be preferred for model download. The user must see the model size, source, and license constraints before download.

The app must remain usable without the model installed.

## Model Download

Model download requirements:

- Explicit user action.
- Clear size disclosure.
- Clear source disclosure.
- Clear license notice.
- Prefer Wi-Fi.
- No automatic background download.
- No hidden retry loop.
- No mandatory account.
- No analytics around download.

## Guardrails

The LLM system prompt is not sufficient as a safety mechanism. Guardrails must also exist in deterministic application code.

Required constraints:

- No diagnosis.
- No medication advice.
- No coercion.
- No engagement maximization.
- No claims of certainty from noisy sensors.
- No override of clinical gates.
- No pressure after dismissal.

## Summaries

AI summaries are sensitive data. They must be stored locally and encrypted if retained. They must be included in future granular export as a separate selectable category.
