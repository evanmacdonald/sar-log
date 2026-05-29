# SAR Log — v1 Project Plan

A PR-by-PR todo list for coding agents to deliver SAR Log v1 as defined in
[`CHARTER.md`](./CHARTER.md). Each item is a single, releasable PR scoped to
one feature.

> **For implementing agents:** read this file end-to-end before picking up a
> PR. The [Universal acceptance criteria](#universal-acceptance-criteria) and
> [Repo conventions](#repo-conventions) apply to every PR — they are not
> restated inside each item.

## Contents

1. [Repo conventions](#repo-conventions)
2. [Universal acceptance criteria](#universal-acceptance-criteria)
3. [Dependency graph](#dependency-graph)
4. [Open questions for Evan](#open-questions-for-evan)
5. [Explicit non-goals (v1)](#explicit-non-goals-v1)
6. [PR list](#pr-list)
7. [Definition of done](#definition-of-done)

---

## Repo conventions

- **Branch model:** `main` is protected. Feature work goes via PRs, one PR
  per item in [PR list](#pr-list). Plan/task-list bookkeeping changes may be
  pushed directly to `main`.
- **Branch names:** `pr-<NN>-<kebab-slug>`, e.g. `pr-04-task-list`.
- **Commit style:** imperative, scoped to the PR. Squash on merge.
- **PR description template:** what the PR does, which PR number from this
  plan it implements, screenshots for any UI work, and a check that
  [universal acceptance criteria](#universal-acceptance-criteria) are met.
- **Test layout:** co-located `Tests/` folder beside each source folder,
  matching the Pocket Doctor convention.
- **Source of truth:** [`CHARTER.md`](./CHARTER.md). If this plan and the
  charter disagree, the charter wins — open a PR to fix the plan.

## Universal acceptance criteria

Every PR must satisfy these. Don't restate them in PR descriptions; just
confirm they're met.

- **Tests:** XCTest coverage for any new logic. CI thresholds
  (70% statements / 65% branches / 70% functions / 70% lines) pass.
  Extract logic from views into testable types if needed.
- **No UI tests:** pure logic only in the automated suite.
- **Auto-save:** any new field / event / vitals input persists on every
  tap / keystroke. No Save button anywhere in the app.
- **Field conditions (UI PRs only):** large tap targets, thumb-zone
  primary actions at the bottom, one-handed operation, no swipe
  gestures that conflict with iOS system gestures, no context-losing
  modals if the screen locks mid-entry, dark-mode legible.
- **No new third-party SDKs.** No analytics, no telemetry, no network
  calls. Charter forbids these for the life of v1.
- **CI green** on the PR before merge: build, test, coverage thresholds.

## Dependency graph

```
PR 1 (bootstrap)
  └─ PR 2 (CI)
       └─ PR 3 (SwiftData + Task entity)
            └─ PR 4 (task list + lifecycle)
                 └─ PR 5 (task detail fields + Maps link)
                      ├─ PR 6 (timeline model + list)
                      │    ├─ PR 7 (predefined events)
                      │    └─ PR 8 (custom + edit/backdate)
                      ├─ PR 9 (vitals model + scaffold)
                      │    └─ PR 10 (all vitals fields)
                      │         └─ PR 11 (prefill opt-in)
                      ├─ PR 12 (auto-save + crash recovery + iCloud backup)
                      └─ PR 13 (long-backgrounding resume)
PR 14 (PDF + share sheet)   — blocked on PEP form sample; needs PR 6, 9, 10
PR 15 (privacy manifest)    — can land any time after PR 1
PR 16 (icon + launch + polish) — last PR before submission
```

**Parallelizable pairs once their prerequisite is merged:**
PR 7 ⟂ PR 8, PR 12 ⟂ PR 13, PR 6-line ⟂ PR 9-line ⟂ PR 12-line ⟂ PR 13.

## Open questions for Evan

Implementing agents should ask before assuming on these. None block early
PRs; flag as you reach them.

1. **Scribe name** — persisted across tasks as a user default
   (auto-fills future tasks), or fresh entry each task? Affects PR 5.
2. **Close-task UX placement** — explicit "Close task" button in task
   detail, or only from task list? Affects PR 4.
3. **Apple Maps linkage trigger** — auto-detect coordinates in the
   location text field, or a dedicated "open in Maps" affordance the
   user invokes? Affects PR 5.
4. **PEP form sample** — Evan to deliver before PR 14 can begin.

## Explicit non-goals (v1)

Do not implement these in any PR. From charter §9:

- No multi-subject / group logging
- No multi-device sync
- No Apple Watch companion
- No cloud anything (no accounts, no backend, no remote storage)
- No in-app map view (Apple Maps URL-scheme link only — see PR 5)
- No voice input for notes
- No audit trail on edits
- No custom-event personal library
- No PDF signature block
- No Android
- No analytics, telemetry, or third-party SDKs
- No GPS
- No steppers (vitals use number pad only)

---

## PR list

### Foundation

- [x] **PR 1 — Xcode project bootstrap**
  - SwiftUI app target `SARLog`, folder layout, `.gitignore`.
  - `README.md` linking to `CHARTER.md` and `PLAN.md`.
  - `AGENTS.md` already exists at repo root as the agent entry doc;
    update its "Repo layout" section to reflect the new Xcode
    structure.
  - App launches to an empty root view. No features.
  - **Acceptance:** repo opens in Xcode and builds; README in place;
    AGENTS.md layout section reflects the new structure; `git status`
    clean on a fresh clone.

- [x] **PR 2 — CI pipeline**
  - GitHub Actions workflow on push / PR to `main`.
  - Steps: `xcodebuild build` (Swift compiler errors fail the build —
    this is the typecheck step the charter calls out), `xcodebuild
    test`, parse `.xcresult` for coverage and fail the job if any of
    the four thresholds drop below charter values, upload coverage
    artifact with 14-day retention.
  - 15-minute job timeout. No lint step in CI.
  - Add one trivial logic test if needed so coverage parsing succeeds
    on an otherwise empty suite.
  - **Acceptance:** CI green on the PR; CI red on a deliberately
    failing test (verified once and reverted).

- [ ] **PR 3 — Persistence layer (SwiftData) + Task entity**
  - SwiftData container wired into the app.
  - `Task` entity: id, taskNumber (free text), subjectName, location,
    scribeName, notes, createdAt, closedAt (nullable).
  - Repository wrapper for CRUD + active/closed queries.
  - Co-located `Tests/` cover CRUD, ordering, and closedAt
    transitions.
  - After merge: upload an internal TestFlight smoke build to de-risk
    signing, App Store Connect processing, and install-on-device flow.
  - **Acceptance:** repository tests pass; entity persists across app
    relaunch in a manual smoke test.

### Task lifecycle

- [ ] **PR 4 — Task list + create / delete / close**
  - Root screen: active tasks first, then closed.
  - "New task" button creates a blank task and navigates to detail.
  - Delete with "Are you sure?" confirmation (no archive).
  - Close-task action toggles `closedAt`. Closed tasks remain
    viewable; they're not deleted.
  - **Acceptance:** list reflects state after create / delete / close
    with no manual refresh; deletion confirmation cannot be bypassed.

- [ ] **PR 5 — Task detail: subject + location + notes + Maps link**
  - Editable fields: taskNumber, subjectName, location (free text),
    scribeName, notes.
  - Per charter §9: tapping a location that looks like coordinates
    opens Apple Maps via URL scheme. No in-app map view.
  - Auto-save on every keystroke.
  - **Acceptance:** all fields persist live; Maps link opens Apple
    Maps from a coordinate-shaped location string; one-handed
    reachable.

### Timeline

- [ ] **PR 6 — Timeline data model + list display**
  - `TimelineEvent` entity: id, taskId, label, timestamp, isCustom.
  - Chronological list inside task detail (newest first or oldest
    first — pick one and document in PR description).
  - Tests cover ordering and insertion at arbitrary timestamps
    (for backdating in PR 8).
  - **Acceptance:** list renders in stable order; underlying tests
    cover insert / fetch / sort.

- [ ] **PR 7 — One-tap predefined events**
  - Six bottom-of-screen buttons: Callout from ECC, Left hall,
    Arrived staging, Departed staging, On scene, Returning to base.
  - Tap stamps `Date.now` and appends.
  - **Acceptance:** any predefined event reachable in a single tap
    from task detail; buttons sit in the thumb zone.

- [ ] **PR 8 — Custom event + edit / backdate timestamps**
  - "Add custom event" entry with free-text label.
  - Tap any existing event to edit its label and / or timestamp
    via a date+time picker.
  - No audit trail.
  - **Acceptance:** backdating an event reorders the list correctly;
    editing persists immediately.

### Vitals

- [ ] **PR 9 — Vitals data model + entry screen scaffold**
  - `VitalsEntry` entity: id, taskId, timestamp, all clinical fields
    nullable (filled by PR 10).
  - Entry screen reachable from task detail.
  - Number-pad keyboard wired (no steppers, ever).
  - Vitals list rendered as a timestamped row table within task
    detail.
  - **Acceptance:** can create an empty `VitalsEntry`; the entry
    appears as a timestamped row.

- [ ] **PR 10 — All vitals fields**
  - HR, BP (systolic / diastolic), SpO₂, RR, Temp, GCS (E / V / M
    with computed sum), Pupils (size + reactivity + L/R separately),
    Pain 0–10, capillary refill, Skin (colour / temp / moisture),
    LOC / AVPU.
  - Number pad for all numeric fields. No steppers.
  - Logic tests cover GCS sum and any input validation.
  - **Acceptance:** every charter §4 field is enterable and saved;
    GCS total updates as E / V / M change.

- [ ] **PR 11 — Prefill-from-previous opt-in**
  - When starting a new vitals entry, surface the previous entry's
    values as suggestions.
  - Each field requires explicit user confirm or edit — never
    silently carried forward.
  - **Acceptance:** prefill is offered, never applied automatically;
    an unconfirmed prefilled field is not saved.

### Resilience

- [ ] **PR 12 — Auto-save + crash recovery + iCloud backup**
  - Verify SwiftData writes flush on every mutation (no buffered
    "Save" semantics anywhere).
  - On launch, detect incomplete mid-write state (e.g. a half-filled
    vitals entry) and surface "resume or discard".
  - Confirm app storage is **not** marked
    `isExcludedFromBackup` — iCloud device backup must include it.
  - **Acceptance:** force-quit during a vitals edit, relaunch, and
    state is recoverable; storage file shows up in a device backup
    inspection.

- [ ] **PR 13 — Long-backgrounding resume**
  - Use SwiftUI scene storage / state restoration to restore the
    navigation stack and in-progress text-entry state after the app
    is backgrounded for hours or the screen locks mid-entry.
  - No context-losing modals during backgrounding.
  - **Acceptance:** open a task, start editing notes, lock the
    phone, relaunch hours later — cursor and unsaved-keystroke state
    intact.

### PDF export

- [ ] **PR 14 — PDF export + iOS share sheet** *(blocked on PEP form
  sample)*
  - Precondition: Evan delivers the BC SAR / PEP paper-form sample.
    Do not start until then.
  - Generate a PDF that mirrors the paper form.
    - Header: task #, subject name, scribe name, date, generated-at.
    - Body in order: subject info + location → timeline table →
      vitals table → notes.
    - No signature block.
  - Expose via iOS share sheet: Save to Files, AirDrop, Email,
    Print.
  - Logic tests cover layout / pagination / table generation. No
    rendered-output snapshot tests in v1.
  - **Acceptance:** generate a PDF from a populated task, share via
    AirDrop, Files, and Email on a real device.

### App Store prep

- [ ] **PR 15 — Privacy manifest**
  - Add `PrivacyInfo.xcprivacy` declaring no data collection, no
    tracking, no required reason APIs beyond what's actually used.
  - No third-party SDKs to declare.
  - **Acceptance:** Xcode validates the manifest; App Store Connect
    privacy section can be filled in as "No data collected".

- [ ] **PR 16 — App icon + launch screen + final polish**
  - App icon at every required size.
  - Launch screen.
  - Dark-mode review pass, Dynamic Type sanity pass, accessibility
    labels on every tap target.
  - This is the last *code* PR before App Store submission. The
    submission itself is operational and lives outside this plan.
  - **Acceptance:** archive build runs on a real device; visual pass
    in light and dark mode; VoiceOver navigates the primary flows.

---

## Definition of done

v1 ships when, on a real device:

1. A task can be created, populated with timeline events and vitals,
   and closed end-to-end.
2. A PDF can be exported and shared via AirDrop / Email / Files.
3. The app recovers cleanly from a crash and from long backgrounding
   without data loss.
4. All CI checks pass at the charter coverage thresholds.
5. The app is submitted to and approved by the App Store. *(This
   step is operational — outside the PR list above. PR 16 is the
   last coding step.)*
