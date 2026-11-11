# THRIVES Architecture

Core motto:

> Assist. Never persuade.  
> Observe. Never judge.  
> Adapt. Never manipulate.

THRIVES is a privacy-first, offline-first nervous system regulation platform. The app must remain useful without a server, without analytics, without telemetry, and without mandatory cloud services.

## Non-Negotiables

- No analytics.
- No telemetry.
- No Firebase.
- No crash reporting.
- No mandatory cloud.
- Local AI only.
- User owns all data.
- Sensitive local data is encrypted at rest.
- Export is optional, encrypted, granular, and triggered only by explicit user action.
- The app succeeds when the user needs it less.
- Safety rules are deterministic, not LLM-decided.

## Architectural Boundaries

The app is organized around deterministic safety gates, local storage, local AI, sensor inputs, feedback outputs, and user-controlled export. These boundaries must stay separate.

- Safety gates decide whether a tool or session is allowed.
- The LLM observes and personalizes. It does not authorize unsafe flows.
- Sensors report values with confidence. They do not diagnose.
- The baseline engine compares a user only to their own historical baseline.
- Feedback channels execute cues. They do not decide therapeutic meaning.
- Export code packages user-selected data. It does not upload automatically.

## Primary Modules

- Clinical safety layer: deterministic gates for Window of Tolerance, Wim Hof, bilateral stimulation, Gateway, crisis support, and other high-risk flows.
- Privacy layer: local-only storage, encryption, deletion, export, and network constraints.
- Baseline engine: user-specific historical comparison with confidence-aware inputs.
- Sensor framework: normalized local sensor providers for heart rate, HRV, respiration, skin temperature, sleep, movement, medication events, and self check-ins.
- Feedback engine: hardware-agnostic output routing for audio, visual motion, haptics, watch cues, BLE devices, and future channels.
- Local LLM layer: optional model download, local inference, pattern summaries, and user-controlled reflection support.
- Gateway module: optional advanced focus and altered-attention module, documented separately and not implemented yet.
- Wearables layer: minimal companion surfaces, not miniature dashboards.

## Data Flow

1. A sensor or self-report produces an observation with confidence.
2. The baseline engine compares the observation against the user's own historical baseline.
3. Deterministic safety rules decide what, if anything, may be offered.
4. If the user chooses an action, the session clock coordinates allowed feedback channels.
5. Session events are stored locally and encrypted where sensitive.
6. The LLM may summarize local patterns only after deterministic rules have already constrained the available action space.
7. Export occurs only when the user explicitly selects categories and confirms encrypted export.

## APK Packaging Rule

Release APKs must not bundle LLM model weights. Models are large, license-sensitive, and privacy-sensitive operational dependencies. The app may offer an explicit in-app model download after startup, preferably Wi-Fi only, with clear size and license information before download.

Model download must not be hidden inside first launch. The user must remain in control.

## Related Documents

- [Developer philosophy](developer_philosophy.md)
- [Privacy](privacy.md)
- [Clinical governance](clinical_governance.md)
- [Feedback engine](feedback_engine.md)
- [Sensor framework](sensor_framework.md)
- [LLM design](llm_design.md)
- [Gateway module](gateway_module.md)
- [Focus model](focus_model.md)
- [Wearables](wearables.md)
