# AGENTS.md

Orientation for coding agents working in this repo (Claude Code, Codex,
or any other tool that reads `AGENTS.md`).

## What this is

SAR Log — a native iOS / SwiftUI app for BC search and rescue members to
replace the paper notebook during a task. Records task basics, a
timestamped timeline, and patient vitals. Exports the log as a PDF via
the iOS share sheet at task close.

The overriding design constraint is **minimizing taps in cold, wet,
gloved, low-light field conditions**. Every UX decision is measured
against that.

## Read these first, in order

1. [`CHARTER.md`](./CHARTER.md) — product scope, pre-build decisions,
   testing/CI rules, definition of done. **Source of truth.** If this
   file or `PLAN.md` disagrees with the charter, the charter wins.
2. [`PLAN.md`](./PLAN.md) — the PR-by-PR todo list. Read end-to-end
   before picking up any item.

## How to pick up work

1. Open [`PLAN.md`](./PLAN.md) and find the lowest-numbered unchecked
   PR whose dependencies (see the dependency graph in `PLAN.md`) are
   merged.
2. Re-read [`PLAN.md` § Repo conventions](./PLAN.md#repo-conventions)
   and [`PLAN.md` § Universal acceptance criteria](./PLAN.md#universal-acceptance-criteria).
3. Create a branch named `pr-<NN>-<kebab-slug>` (e.g. `pr-04-task-list`).
4. Implement the item. Keep the PR scoped to that single item.
5. Open a PR. The description should:
   - State which `PLAN.md` item it implements.
   - Include screenshots for any UI work.
   - Confirm universal acceptance criteria are met.

## Non-negotiables

These come from the charter and apply to every PR. Don't relitigate
them; if one feels wrong, open a discussion before coding.

- **No third-party SDKs.** No analytics, no telemetry, no networking.
  Data lives on the device only.
- **No accounts, no cloud, no GPS, no Android.**
- **Auto-save on every tap / keystroke.** No Save button anywhere.
- **No UI tests in v1.** XCTest covers logic only. Extract logic from
  views into testable types when needed.
- **CI coverage thresholds:** 70% statements / 65% branches /
  70% functions / 70% lines. PRs that drop coverage below these fail
  CI.
- **`main` is protected.** Feature work goes via PRs; plan/task-list
  bookkeeping changes may be pushed directly to `main`.

## Repo layout

```
.
├── .github/workflows/ # GitHub Actions CI
├── ci/                # CI helper scripts
├── CHARTER.md        # product scope + decisions (source of truth)
├── PLAN.md           # PR-by-PR todo list
├── AGENTS.md         # this file — agent orientation
├── README.md         # quick start + project links
├── SARLog.xcodeproj  # Xcode project
└── SARLog/           # SwiftUI app source
    ├── Persistence/  # SwiftData models / repository + co-located Tests/
    ├── Support/      # shared UI / helper code
    ├── TaskDetail/   # task detail screens
    ├── TaskList/     # task list screens / logic + co-located Tests/
    └── Tests/        # app-level logic tests
```

Co-located `Tests/` folders should be added beside source folders as
logic lands in subsequent PRs. Update this layout section when the
shape changes meaningfully.

## When in doubt

- Charter ambiguity → ask Evan. Don't assume.
- Plan ambiguity → check the open-questions section at the top of
  [`PLAN.md`](./PLAN.md#open-questions-for-evan); if not listed, ask.
- Tooling / harness question → consult the docs for the agent you're
  running (e.g. Claude Code on the web, Codex). This repo deliberately
  stays tool-agnostic.
