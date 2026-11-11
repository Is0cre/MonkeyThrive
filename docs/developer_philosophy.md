# Developer Philosophy

Core motto:

> Assist. Never persuade.  
> Observe. Never judge.  
> Adapt. Never manipulate.

THRIVES is not an engagement product. It is not a funnel. It is not a habit-maximization system. The app succeeds when the user needs it less.

## Product Standard

Build the minimum useful intervention, then stop. Do not add loops that increase dependency. Do not add streaks, shame, urgency, fear, or artificial scarcity. Do not optimize for session count, retention, or notification conversion.

Every feature should answer:

- Does this reduce user agency?
- Does this imply diagnosis?
- Does this pressure the user?
- Does this make the app harder to leave?
- Does this weaken deterministic safety gates?
- Does this create new sensitive data?
- Does this create a network path?

If the answer is yes, the feature needs redesign or rejection.

## Engineering Rules

- Prefer local computation over network services.
- Prefer deterministic rules over generative judgment for safety.
- Prefer explicit user action over automatic behavior.
- Prefer simple auditable storage over opaque SDKs.
- Prefer generated local audio over bundled proprietary assets.
- Prefer small patches over large rewrites.
- Prefer blunt safety wording over persuasive copy.

## Copy Rules

The app must never tell a user that they are anxious, depressed, dysregulated, dissociated, traumatized, or in panic. It may ask how the user feels. The user is the authority on their internal state.

Avoid:

- "You are anxious."
- "You are dysregulated."
- "You need this."
- "Do not miss your session."
- "We noticed you are struggling."
- "Your score is bad."

Allowed style:

- "How are you doing?"
- "I noticed things look a little different from your usual baseline."
- "Would you like something simple?"
- "You can stop at any time."

## Documentation First

High-risk modules must be documented before implementation. Documentation is not bureaucracy here; it is the safety boundary. If a feature cannot be described clearly, it is not ready to be built.

## No Hidden Incentives

THRIVES must not contain:

- Analytics.
- Telemetry.
- Firebase.
- Crash reporting.
- Engagement optimization.
- Dark patterns.
- Hidden persuasion.
- Cloud-only features.
- Mandatory accounts.
- Model output that overrides safety gates.
