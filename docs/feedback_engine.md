# Feedback Engine

The feedback engine coordinates output cues without knowing clinical meaning. It executes safe instructions from a session conductor. It does not decide whether a session is appropriate.

## Core Abstractions

Use hardware-neutral interfaces:

- `FeedbackEngine`
- `SessionClock`
- `FeedbackChannel`
- `BodyLocation`
- `SensorProvider`
- `DeviceProvider`

Clinical logic must not know whether a cue is delivered through a phone motor, watch haptic, visual animation, headphones, desktop display, or future BLE wristband.

## Body Locations

Supported conceptual locations:

- `LEFT_WRIST`
- `RIGHT_WRIST`
- `LEFT_EAR`
- `RIGHT_EAR`
- `VISUAL_CENTER`
- `PHONE`
- `DESKTOP`

These are routing targets, not medical claims.

## Multimodal Session Conductor

One master session clock coordinates:

- Audio.
- Visual motion.
- Breathing cadence.
- Phone haptics.
- Smartwatch haptics.
- Future BLE wristbands.
- Check-ins.
- Return phase.

The session clock must support cancellation, pause where safe, and mandatory return phases for advanced modules.

## Channel Rules

Feedback channels must be opt-in or user-configured when they can startle, overstimulate, or expose private use.

Examples:

- Haptics must respect haptic sensitivity.
- Audio must respect audio sensitivity and headphone availability.
- Visual motion must respect reduced animation and visual sensitivity.
- Voice must respect screen reader and privacy context.

## No Hidden Stimulation

Audio, haptics, and visual motion must not run unexpectedly. Session start must be explicit. Background cues must be conservative and documented.

## Gateway Audio

Gateway audio must be original and generated locally. It must not use Monroe proprietary frequencies, scripts, exact timing, narration, tape structure, or commercial progression.

Allowed configurable entrainment ranges:

- Delta-style: 1-4 Hz beat target.
- Theta-style: 4-8 Hz beat target.
- Alpha-style: 8-12 Hz beat target.
- Low beta-style: 12-18 Hz beat target.

Default carrier range:

- 100-300 Hz.

Audio types:

- Binaural.
- Monaural.
- Isochronic.
- Pink noise.
- Brown noise.
- Nature noise.
- Silence.

No bundled proprietary audio.
