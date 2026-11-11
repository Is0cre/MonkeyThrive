# Wearables

Wearables are architecture-only for now.

A watch is not a mini phone. It is a discreet, low-cognitive-load support surface.

## Watch Functions

Allowed functions:

- Discreet check-in.
- One-tap "okay / not okay".
- Breathing haptic cadence.
- Panic support.
- Bilateral haptic cue.
- Minimal display.

Not allowed:

- Graph-heavy dashboards.
- Scrolling-heavy UI.
- Engagement prompts.
- Streaks.
- Guilt notifications.
- Diagnostic labels.
- Hidden monitoring without consent.

## Interaction Rules

Wearable interactions must be:

- Large target.
- One-handed.
- Low text.
- Low cognitive load.
- Dismissible.
- Respectful of quiet hours.
- Safe during panic, freeze, dissociation, or overwhelm.

## Onboarding Questions

Onboarding should ask how THRIVES should communicate:

- Visual.
- Audio.
- Haptic.
- Voice.
- Screen reader.
- Reduced animation.
- High contrast.
- Large controls.

Onboarding should also ask:

- Dominant hand.
- Watch wrist.
- Phone hand.
- Headphones available.
- Haptic sensitivity.
- Audio sensitivity.
- Visual sensitivity.

## Feedback Routing

Wearables must use the shared feedback abstractions:

- `FeedbackEngine`
- `SessionClock`
- `FeedbackChannel`
- `BodyLocation`
- `SensorProvider`
- `DeviceProvider`

The clinical module asks for a cue at a conceptual location. The device layer decides whether a watch, phone, earbud, screen, or future BLE device can deliver it.

## Privacy

Wearable data is sensitive. It must remain local unless the user explicitly exports it. No wearable telemetry, analytics, or cloud sync may be added by default.

## Baseline Use

Wearable sensors may contribute to the user's own baseline when confidence is available. They must not produce mental health scores or compare the user to other users.
