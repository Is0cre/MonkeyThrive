---
name: Crisis directory addition
about: Add offline emergency or support numbers for a country
title: "[crisis] "
labels: documentation
assignees: ""
---

## Country

Name, and the ISO 3166-1 alpha-2 code to store (for example `se`, `us`, `de`). Countries already in the app: Sweden, United States, United Kingdom, Philippines, Germany, Malta, and an International fallback.

## Contacts

| Name | Number as published | Digits to dial | Category (`emergency`, `helpline`, or `guidance`) | What the line is | Text keyword, if any |
| --- | --- | --- | --- | --- | --- |
| | | | | | |

A text-only line (such as a short-code keyword) must not also be offered as a voice call. If one national number does not reach every service, list the separate number and say so.

## Source

Link to the organisation or government page that publishes each number, and the date you checked it. The app stores the number on the device. It does not open that page.

## Checks

- [ ] These are the official numbers, not a search snippet or a third-party list.
- [ ] Emergency numbers are included, and search must not hide them.
- [ ] An unknown locale for this language stays on International unless the country code itself matches.
- [ ] No website, office switchboard, or number that needs an account.

## Notes

Anything a contributor should preserve in `thrives_app/lib/core/data/crisis_helplines.dart`.
