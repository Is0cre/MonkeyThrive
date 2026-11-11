---
name: Offline regression
about: A network call, permission, tracker, or failure when the device is offline
title: "[offline] "
labels: bug
assignees: ""
---

## What broke

Describe the offline or privacy regression. Name the screen and what should have stayed on the device.

## Platform

- [ ] Android APK
- [ ] Web / PWA at monkeythrive.app
- Flutter version:
- Device or browser:

## Evidence of a network path

- [ ] `INTERNET` or a network-state permission was added
- [ ] A request was observed while the app was in use (name the host)
- [ ] A tracker, analytics SDK, crash reporter, or remote font loaded
- [ ] A feature fails with the network turned off
- [ ] Other:

## Steps

1.
2.
3.

## What the app should do

MonkeyThrive stays usable with no network. Journal entries, check-ins, and sensor readings stay on the device. The crisis directory is compiled in and is not fetched.

## Logs

Paste local logs only. Remove phone numbers and anything copied from the crisis directory.
