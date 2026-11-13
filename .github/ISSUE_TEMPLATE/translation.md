---
name: Translation
about: Offer a language for the offline app. No Flutter install is required.
title: "Translation: "
labels: documentation
assignees: ""
---

## Language

Language name, and the locale code to use in the filename (for example `sv`, `de`, `es`, `pt_BR`). One language per issue.

## How to contribute

You can do this entirely on GitHub. You do not need Flutter, Android Studio, or a local build.

Pick one of these:

1. Paste the translation in a comment on this issue. Use a table:

   | Key | English | Translation |
   | --- | --- | --- |
   | boxBreathingTitle | Box Breathing | |
   | breathingBegin | Begin | |
   | breathingPause | Pause | |

2. Or add the file yourself. On GitHub, open `thrives_app/lib/l10n/app_en.arb`, choose **Edit** or **Copy**, and save the copy as `thrives_app/lib/l10n/app_<locale>.arb` (for Swedish, `app_sv.arb`). Change the first line `"@@locale": "en"` to your locale. Translate only the text on the right of each message. Leave every key, every `{placeholder}`, and every `"@key"` description in English.

A maintainer will check the wording and open a pull request if you used option 1.

## Keep these as they are

- The name MonkeyThrive.
- Anything inside `{curly braces}`. Those are filled in by the app, such as `{current}` and `{total}` in `Cycle {current} of {total}`.
- Numbers for crisis lines, and the meaning of safety sentences. A locked tool stays locked. “Present”, “overwhelmed”, and “flat or numb” name the reading the person already gave. They are not a diagnosis.
- Do not add links, tracking, fonts, or instructions that need a network connection. The app stays offline.

## Sample message

```json
"breathingCycle": "Cycle {current} of {total}"
```

A Swedish file would keep the key and the placeholders:

```json
"@@locale": "sv",
"breathingCycle": "Varv {current} av {total}"
```
