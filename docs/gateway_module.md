# Gateway Module

Status: documentation only. Do not implement until clinical and security review are complete.

Gateway is an optional advanced focus and altered-attention module inspired by publicly documented Gateway and Focus Level concepts. It must not copy proprietary Monroe Institute tape scripts, exact audio sequences, timing, narration, frequencies, or commercial progression.

Gateway must be original, safety-gated, modular, and clinically conservative.

## Hard Boundaries

Gateway is not therapy.

Gateway is not EMDR.

Gateway is not trauma processing.

Gateway is not diagnosis.

Gateway does not claim objective external realities.

Focus levels are treated as structured subjective attention states.

## Safety Position

Gateway can alter attention, body perception, time perception, emotional salience, and suggestibility. That makes it higher risk than ordinary grounding. It must be gated conservatively.

Required controls:

- Pre-check before every session.
- User-selected session length before starting.
- No endless sessions.
- No autoplay next session.
- No engagement rewards.
- Mandatory return phase.
- Mandatory grounding phase.
- Post-check.
- Clear stop control.
- No hidden persuasion.
- No user-invisible suggestions.

The return phase is mandatory and cannot be skipped.

## Session Phases

1. Pre-check.
2. Regulation.
3. Stabilization.
4. Induction.
5. Focus transition.
6. Exercise.
7. Return.
8. Grounding.
9. Post-check.
10. Optional journal.

## Timer

The user must set session length before starting.

Modes:

- Fixed timer.
- Adaptive timer later.

Default durations:

- Beginner: 10-20 minutes.
- Intermediate: 20-45 minutes.
- Advanced: 45-90 minutes.

No endless sessions. No autoplay next session.

## Audio

Do not use Monroe proprietary frequencies.

Use original configurable entrainment ranges:

- Delta-style: 1-4 Hz beat target.
- Theta-style: 4-8 Hz beat target.
- Alpha-style: 8-12 Hz beat target.
- Low beta-style: 12-18 Hz beat target.

Carrier range:

- 100-300 Hz default.

Audio types:

- Binaural.
- Monaural.
- Isochronic.
- Pink noise.
- Brown noise.
- Nature noise.
- Silence.

All audio must be generated locally. Do not bundle proprietary audio.

## Conductor

Gateway must use the shared multimodal session conductor:

- `FeedbackEngine`
- `SessionClock`
- `FeedbackChannel`
- `BodyLocation`
- `SensorProvider`
- `DeviceProvider`

The intervention logic must not know hardware.

## Review Gate

Clinical review is mandatory before implementation and before any change to:

- Gateway entry gates.
- Focus progression.
- Session duration.
- Audio intensity.
- Suggestion mechanics.
- Return phase.
- Grounding phase.
- Claims or explanatory language.
