# SAR Log — Project Charter

## Objective

A native iOS app for BC search and rescue members to replace the written notebook during a task. Records task basics (task #, subject name, location, notes), a timestamped timeline of events, and patient vitals. The single overriding design constraint is minimizing taps — every common workflow must be as fast as possible in cold, wet, gloved, low-light field conditions.

## Key considerations

- Use the same way of working as the Pocket Doctor project: Claude Code setup, slash commands, PR-digest workflow, testing discipline, single-developer cadence. Code architecture differs — SAR Log is native SwiftUI, not RN/Expo.
- Data lives on the user's phone only. No cloud, no accounts, no third-party SDKs.
- At the end of a task the user exports the log as a PDF via the iOS share sheet.

---

# Pre-Build Decisions

## 1. Stack

| Option | Notes |
|---|---|
| Expo / React Native | Matches Pocket Doctor; Android-ready |
| **Native SwiftUI ✓** | Better field UX; iOS-only path |

**Decision:** SwiftUI. Android expansion is not planned.

## 2. Domain & scope

- **Subjects per task:** One subject per task for v1. Multi-subject / group support deferred.
- **Device model:** Single device, "I am the scribe." Multi-device sync deferred to v2.
- **Task lifecycle:**
  - Tasks never auto-close. User closes manually or starts a new one.
  - Tasks can span multiple days / operational periods. User creates a new task manually for each new operational period if desired.
  - Delete (with "Are you sure?" confirmation) — no archive in v1.
- **PEP task numbers:** Free text. No autofill, no validation.

## 3. Timeline events

One-tap predefined events (v1):

- Callout from ECC
- Left hall
- Arrived staging
- Departed staging
- On scene
- Returning to base

Other behaviours:

- User can add a free-text custom event on the fly.
- Custom-event personal library — **deferred to v2.**
- Auto-timestamp from device clock on tap.
- Past timestamps are editable — no audit trail in v1.
- Backdating a forgotten event is supported.

## 4. Vitals

Field set for v1:

- HR
- BP (systolic / diastolic)
- SpO₂
- RR
- Temp
- GCS (E / V / M, summed)
- Pupils (size, reactivity, L/R)
- Pain 0–10
- Capillary refill
- Skin (colour / temp / moisture)
- LOC / AVPU

Entry UX:

- Number pad for all numeric fields. No steppers in v1.
- Option to prefill a new entry with the previous reading's values. User must explicitly opt in or confirm each field — values are never silently carried forward.
- Each vitals entry is a timestamped row in the log. No trend visualisation in v1.

## 5. Field UX (cold / wet / gloved / dark)

- Large tap targets throughout. No small text input fields.
- No swipe gestures that conflict with iOS system gestures.
- Thumb-zone layout — primary actions at the bottom of the screen.
- One-handed operation throughout.
- Voice input for notes — **NOT in v1.**
- No context-losing modals if the screen locks mid-entry.
- No GPS.

## 6. Data integrity & chain-of-custody

BC SAR logs can become evidence in coroner inquests, lawsuits, and police investigations. The generated PDF is the source of truth filed with reports — not the in-app data. Silent in-app edits are acceptable in v1 because the PDF is generated and filed once at task close.

- Auto-save after every tap / keystroke. No Save button anywhere.
- Crash recovery on next app launch — recover mid-write state.
- iCloud device backup enabled so a dead phone doesn't destroy the record.
- No silent auto-deletion of tasks.

## 7. Privacy & access

- No analytics, no telemetry, no third-party SDKs.
- No accounts, passwords, or logins.

## 8. PDF export

Design the PDF to mirror the team's current paper notebook / official PEP form.

- **Sample / template:** To be provided by Evan when PDF work begins.
- Header: task #, subject name, scribe name, date, generated-at timestamp.
- Body (in order): subject info + location → timeline table → vitals table → notes.
- No signature block in v1.
- Export via iOS share sheet: Save to Files, AirDrop, Email, Print.

## 9. v1 scope cuts

- No multi-subject / group logging
- No multi-device sync
- No Apple Watch companion
- No cloud anything
- No in-app map view (coordinates shared to Apple Maps via URL scheme)
- No voice input for notes
- No audit trail on edits
- No custom-event personal library
- No PDF signature block
- No Android (SwiftUI choice forecloses this without a rewrite)

## 10. v1 must-haves not in original brief

- Resume mid-task after long backgrounding
- PDF template based on real BC SAR / PEP form (sample to be provided)
- Stack decision made before first PR ✓

---

# Testing & quality

## Framework

XCTest (built into Xcode). All tests are pure logic — no UI rendering in the automated suite, mirroring Pocket Doctor's Jest approach.

## What gets tested

Co-located `Tests/` folders next to source. Planned suites:

- Data model logic (task lifecycle, timeline ordering, vitals entries)
- PDF generation logic
- Persistence layer (SwiftData repository functions)
- Utility / helper functions

## What is not tested in v1

No XCUITest (UI / E2E). Those rely on the manual Xcode run / TestFlight flow, same as Pocket Doctor's `expo run:ios`.

## Coverage thresholds (CI-enforced)

Mirrors Pocket Doctor: **70% statements / 65% branches / 70% functions / 70% lines.**

## CI (GitHub Actions)

Triggers on push / PR to `main`:

1. Build (`xcodebuild build`)
2. Typecheck (Swift compiler — errors are build failures)
3. Test (`xcodebuild test`)
4. Upload coverage artifact (14-day retention)

15-minute timeout. No separate lint step in CI.

---

# Build & deploy

| Stage | Method |
|---|---|
| Development | Xcode → personal device (sideload) |
| Testing / staging | TestFlight |
| Release | App Store |

**App Store requirements (no backend makes this straightforward):**
- App Store Connect setup
- Privacy manifest (`PrivacyInfo.xcprivacy`) — declare no data collection
- App icon (all required sizes)
- No third-party SDKs = no additional privacy disclosures

---

# Definition of done — v1

SAR Log v1 is complete when:

1. A task can be created, populated with timeline events and vitals, and closed end-to-end on a real device.
2. A PDF export can be generated and shared via AirDrop / email / Files.
3. The app recovers cleanly from a crash or long backgrounding without data loss.
4. All CI checks pass (build + typecheck + tests at coverage thresholds).
5. The app is submitted to and approved by the App Store.

---

# GitHub repository

- **Repo:** `sar-log`
- **Branch model:** `main` is protected; feature work goes via PRs.
  Plan/task-list bookkeeping changes may be pushed directly to `main`.
- **Charter location:** `CHARTER.md` in repo root.
