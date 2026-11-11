# Sensor Framework

The sensor framework prepares THRIVES for local, confidence-aware observations. It does not diagnose. It does not score mental health. It does not compare users against other users.

## Sensor Types

Prepare interfaces for:

- Heart rate.
- HRV.
- Respiration.
- Skin temperature.
- Sleep.
- Movement.
- Medication events.
- Self check-ins.

Every sensor value must include confidence.

## Observation Shape

Each observation should include:

- Sensor type.
- Timestamp.
- Value.
- Unit.
- Confidence.
- Source device or source type.
- Optional quality flags.
- Optional user-entered context.

Confidence is required because consumer sensors are noisy. Missing confidence should fail closed or be treated as low confidence.

## Baseline Engine

The baseline engine compares the user only against their own historical baseline.

Never:

- Compare against other users.
- Produce mental health scores.
- Diagnose.
- Tell the user they are anxious, depressed, dysregulated, or in panic.
- Trigger fear-based notifications.

Allowed:

- Quietly detect that current values differ from the user's usual pattern.
- Ask the user how they are doing.
- Store encrypted local feedback.
- Improve future local personalization.

## Notification Constraints

Baseline prompts may be shown only when:

- Sensor values deviate significantly from the user's learned baseline.
- Confidence is sufficiently high.
- The user has not recently been prompted.
- Quiet hours are respected.
- The user is not inside another THRIVES session.

Do not hardcode clinical thresholds in UI code. Future local AI may implement `shouldNotify()`, but deterministic privacy and safety constraints still apply.

If ignored, assume intentional dismissal. Do not repeat, nag, or optimize for engagement.

## Medication Events

Medication timeline support is optional and user-entered. The system may store neutral timing data and show neutral pattern observations.

The system must not:

- Recommend medication.
- Tell a user to stop medication.
- Label misuse.
- Infer addiction.
- Alert third parties.

Allowed wording:

> Your recorded use of rescue medication is higher than your usual pattern.
