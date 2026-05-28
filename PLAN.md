# SAR Log — v1 Project Plan

A PR-by-PR todo list for a coding agent to deliver SAR Log v1 as defined in
[`CHARTER.md`](./CHARTER.md). Each item is a single, releasable PR scoped to
one feature. Work top-to-bottom; items in the same group can run in parallel
once their group's prerequisite is merged.

## Working rules

- One PR per item. Keep diffs reviewable.
- Every PR ships with XCTest coverage for the logic it adds. CI thresholds
  (70% statements / 65% branches / 70% functions / 70% lines) must pass.
- No UI tests in v1 — automated suite is pure logic.
- `main` is protected; merge via PR only.
- If a PR can't hit the coverage threshold (e.g. a pure SwiftUI view PR), add
  logic tests for any extracted view models / helpers rather than lowering the
  bar.

## Known blocker

- **PR 14 (PDF export)** is blocked until Evan provides the BC SAR / PEP
  paper-form sample to mirror. Do all earlier PRs first; if the sample
  arrives sooner, PR 14 can land in its natural slot.

---

## Foundation

- [ ] **PR 1 — Xcode project bootstrap**
  Create the SwiftUI app target (`SARLog`), folder layout, `.gitignore`,
  `.swiftformat` / `.swiftlint` config if used locally (no CI lint step),
  minimal `README.md`. App launches to an empty root view. No features.

- [ ] **PR 2 — CI pipeline**
  GitHub Actions workflow on push / PR to `main`: `xcodebuild build`,
  `xcodebuild test`, coverage artifact upload (14-day retention),
  15-minute timeout. Enforce coverage thresholds via a script that parses
  the `.xcresult` bundle. Add one trivial logic test so the threshold
  doesn't fail on an empty suite.

- [ ] **PR 3 — Persistence layer (SwiftData)**
  Set up the SwiftData container, the `Task` entity (id, task #, subject
  name, location, scribe name, notes, createdAt, closedAt), and a thin
  repository wrapper. Co-located `Tests/` for repository CRUD. No UI yet.

---

## Task lifecycle

- [ ] **PR 4 — Task list + create / delete / close**
  Root screen lists tasks (active first, then closed). "New task" creates
  and opens an empty task. Swipe-or-button delete with "Are you sure?"
  confirmation. "Close task" action toggles `closedAt`. No archive.

- [ ] **PR 5 — Task detail: subject + location + notes**
  Detail screen with editable task #, subject name, location (free text),
  scribe name, notes. Large tap targets, thumb-zone layout, number-pad
  keyboards where appropriate. Auto-save on every keystroke (no Save
  button anywhere).

---

## Timeline

- [ ] **PR 6 — Timeline data model + list display**
  `TimelineEvent` entity (id, taskId, label, timestamp, isCustom). Render
  a chronological list inside task detail. Tests cover ordering and
  insertion logic.

- [ ] **PR 7 — One-tap predefined events**
  Six buttons (Callout from ECC, Left hall, Arrived staging, Departed
  staging, On scene, Returning to base). Tapping stamps `Date.now` and
  appends. Thumb-zone bottom layout, large targets.

- [ ] **PR 8 — Custom event + edit / backdate timestamps**
  "Add custom event" entry with free-text label. Tap any past event to
  edit its label or timestamp (date + time picker). No audit trail.

---

## Vitals

- [ ] **PR 9 — Vitals data model + entry screen scaffold**
  `VitalsEntry` entity (id, taskId, timestamp, all fields nullable).
  Entry screen routes from task detail. Number-pad keyboard wired for
  all numeric fields. Vitals list rendered as a timestamped row table.

- [ ] **PR 10 — All vitals fields**
  Implement input for HR, BP (sys/dia), SpO₂, RR, Temp, GCS (E/V/M with
  computed sum), Pupils (size + reactivity + L/R), Pain 0–10, capillary
  refill, skin (colour / temp / moisture), LOC / AVPU. No steppers.

- [ ] **PR 11 — Prefill-from-previous opt-in**
  When starting a new vitals entry, offer to prefill from the most
  recent entry. Each prefilled field requires explicit user confirm /
  edit before save — never silently carried forward.

---

## Resilience

- [ ] **PR 12 — Auto-save + crash recovery**
  Verify SwiftData writes flush on every mutation (no buffered "Save"
  semantics). On launch, detect and surface any incomplete mid-write
  state (e.g. an in-progress vitals entry) and let the user resume or
  discard.

- [ ] **PR 13 — Long-backgrounding resume**
  Restore the exact navigation stack and in-progress text-entry state
  after the app is backgrounded for hours or the screen locks
  mid-entry. No context-losing modals.

---

## PDF export (blocked on template sample)

- [ ] **PR 14 — PDF export + iOS share sheet**
  Generate a PDF mirroring the BC SAR / PEP paper form (sample required
  before starting). Header: task #, subject, scribe, date, generated-at.
  Body in order: subject + location → timeline table → vitals table →
  notes. No signature block. Share via the iOS share sheet (Save to
  Files, AirDrop, Email, Print). Tests cover layout / pagination logic.

---

## App Store prep

- [ ] **PR 15 — Privacy manifest + iCloud backup config**
  Add `PrivacyInfo.xcprivacy` declaring no data collection. Confirm the
  app's storage is included in iCloud device backup (not excluded from
  backup). No analytics, no telemetry, no third-party SDKs to declare.

- [ ] **PR 16 — App icon + launch screen + final polish**
  All required icon sizes, launch screen, dark-mode review, Dynamic
  Type sanity pass, accessibility labels on tap targets. Last pass
  before submission.

---

## Definition of done (from charter)

v1 ships when, on a real device:

1. A task can be created, populated with timeline events and vitals, and
   closed end-to-end.
2. A PDF can be exported and shared via AirDrop / email / Files.
3. The app recovers cleanly from a crash and from long backgrounding
   without data loss.
4. All CI checks pass at the coverage thresholds.
5. The app is submitted to and approved by the App Store.
