# UI Spec (V1)

Defines the navigation graph and the screens needed to deliver every story in [`user-stories.md`](./user-stories.md). Story anchors (S1–S28) are referenced inline. ASCII mockups are illustrative only — final layout is the implementer's call as long as the elements and interactions are present.

## Design principles

- **Daily flows are the budget.** Logging weight (S4), the morning prompt (S5), seeing today (S6), and logging a workout (S11–S14) must each be reachable in ≤ 2 taps from launch and finishable without scrolling on iPhone.
- **Manual is first-class.** Every screen that surfaces HealthKit-sourced data must be readable and the rest of the app fully usable when HealthKit is denied (S23).
- **HealthKit-imported records are read-only.** A small HK badge on imported sessions; tapping "Edit" shows a sheet pointing to the source app (S16, S26).
- **Plan ≠ history.** Plan edits never rewrite logged sessions (S8); logged session detail uses the snapshotted plan title, never the live one.
- **One Active Plan.** The plan name is always visible on Today; switching is two taps (S7).

## Platform navigation

### iPhone — `TabView` root, five tabs

| Tab | Icon | Purpose |
|---|---|---|
| **Today** | `figure.run.circle.fill` | Today's plan, quick log, plan switcher |
| **History** | `clock.arrow.circlepath` | Past sessions grouped by week |
| **Library** | `dumbbell.fill` | User-curated exercises |
| **Metrics** | `chart.line.uptrend.xyaxis` | Weight, daily metrics, body measurements |
| **Settings** | `gearshape.fill` | Plans, HealthKit, reminders, import, about |

Each tab uses `NavigationStack` for drill-down. Sheets are used for quick logging (weight, morning prompt, body measurement). Full-screen `fullScreenCover` is used for live workout logging so the user can't accidentally swipe away mid-set.

### Mac (Designed for iPad → later native) — `NavigationSplitView`

Sidebar lists the same five sections. Detail column owns the current screen. Sheets become centered popovers / modals; `fullScreenCover` becomes a centered sheet (Mac doesn't go full-screen for logging — the log screen takes ~720pt centered).

### iPad

Same `NavigationSplitView` as Mac, with a translucent sidebar. Not separately spec'd in V1 — "Designed for iPad" is the build target until a native iPad layout is requested.

## Screens by tab

### Today tab

#### `TodayHomeView` — home screen (S6)

Top to bottom:

1. **Header row.** Date ("Saturday, May 2") + active plan name as a tappable chip → opens **Plan Switcher** bottom sheet (S7).
2. **Today's workouts.** A vertical list of `PlannedWorkoutCard`s. Each card shows: training-type icon, title, sets×reps×weight summary (or duration / distance), status pill (Not started / In progress / Done), and a tap target → `PlannedWorkoutDetailView`.
3. **+ Log workout** button (prominent, secondary style) → ad-hoc workout type picker → log screen (S15).
4. **Quick stats row.** Three compact tiles:
   - Today's weight + delta vs. yesterday → tap → opens **Weight Log Sheet** (S4).
   - Recovery 1–10 + sleep hours → tap → opens **Morning Metrics Sheet** (S5).
   - Today's active energy / steps from HealthKit (read-only display).
5. **Empty / rest-day states.** If no plan exists: a single CTA card "Add your first plan — Import or create". If today's plan day has no workouts: "Rest day."

```
┌────────────────────────────────────┐
│  Sat May 2     [Variant A ▾]       │
│                                    │
│  Today                             │
│  ┌──────────────────────────────┐  │
│  │ 🏋️  Push Day                  │  │
│  │ 4 exercises · ~45 min         │  │
│  │                  [In progress]│  │
│  └──────────────────────────────┘  │
│  ┌──────────────────────────────┐  │
│  │ 🚶 Walking pad                │  │
│  │ 2.5 km/h · 2.5h               │  │
│  │                  [Not started]│  │
│  └──────────────────────────────┘  │
│                                    │
│  [ + Log workout ]                 │
│                                    │
│  ┌────┐ ┌─────────┐ ┌────────┐     │
│  │88.6│ │Recov 7  │ │14 230  │     │
│  │−0.3│ │Sleep 7h │ │ steps  │     │
│  └────┘ └─────────┘ └────────┘     │
└────────────────────────────────────┘
```

#### `PlanSwitcherSheet` — bottom sheet (S7)

Lists every `Plan` ordered by `name`. The active one shows a checkmark. Tapping a plan dismisses the sheet and toggles `isActive`. Below the list: "Manage plans" → Settings → Plans.

#### `PlannedWorkoutDetailView` — drill-down

Shows the plan vs. live progress. Two states:

- **Not started:** read-only summary + a primary "Start workout" button → `WorkoutLogView` (`fullScreenCover` on iPhone).
- **In progress:** "Resume" → reopens `WorkoutLogView` with the current `WorkoutSession`.

Includes an "Edit plan" link (S8) → `PlannedWorkoutEditView` (sheet). Plan edits don't affect any in-progress or logged session.

#### `WorkoutLogView` — full-screen logger (S11–S14)

One screen per training type, but they share a frame: header (workout title + timer), body (type-specific content), bottom bar (Discard / Finish workout).

- **Strength body (S11).** List of planned exercises. Each exercise expands inline to per-set rows (reps + weight number-pad inputs). Default values come from the plan; "Log" appends a `StrengthSet`. Each exercise also has a context-menu "Skip exercise" affordance — explicit, recorded as a skip rather than as zeros. After every planned exercise has either at least one logged set or an explicit skip, "Finish workout" enables.
- **Cardio body (S12).** Big timer + Start/Pause. On finish: a form prefilled with planned distance + measured duration. **HK match banner**: if a `HKWorkout` exists within ±15 min and matches type, "Use Apple Watch totals" replaces the form values.
- **Tennis body (S13).** Big timer + Start/Pause. On finish: notes field + RPE 1–10 → save.
- **Circuit body (S14).** Big timer + Start/Pause. On finish: duration is captured automatically; user adds optional notes (which variant) + RPE → save. The plan's exercise list is shown as collapsed reference.

Bottom bar always: **Discard** (red, confirms) and **Finish workout** (primary, disabled until criteria met). Discarding a session that was started from a planned workout returns its status pill to "Not started" (the empty `WorkoutSession` is deleted on discard).

#### `AdHocLogTypePicker` — sheet (S15)

Modal sheet listing the six training types (icon + label). Tap → opens the matching `WorkoutLogView` with no plan link. For strength: includes the inline exercise creation behavior (see Library section).

#### `WeightLogSheet` — sheet (S4)

Single screen: kg field (autofocused, decimal pad), suggested value = last entry, optional note. "Log" writes both locally and to HealthKit. Closes on save.

#### `MorningMetricsSheet` — sheet (S5)

Top section (read-only, populated from HealthKit): resting HR, HRV, sleep hours, steps, active energy, VO2max. "—" for blanks.

Bottom section (manual): two 1–10 sliders (Sleep quality, Recovery), optional notes field. "Save" → upserts the day's `DailyMetrics` row.

### History tab

#### `HistoryListView` — root (S18)

Sectioned list grouped by ISO week, newest first. Each section header shows a compact summary card: workouts done / planned, run km, walking-pad km, tennis sessions, strength sessions, total active energy. Tap a section → expanded day-by-day list of `WorkoutSession` rows.

Each row: training-type icon, title, duration, primary metric (top set for strength, distance for cardio, duration for tennis/circuit), HK badge if `origin == "healthkit"`. Tap → `SessionDetailView`.

#### `SessionDetailView` — drill-down

Read-only view of the session: header (title, date, duration, type), body (sets list for strength; totals + cardio summary for cardio/circuit/tennis), source row (logged manually OR imported from Health, with the `sourceBundleId` shown for imports — "From: Apple Watch").

For strength sessions, the body lists every planned exercise. Exercises the user explicitly skipped show as a muted row labelled "Skipped" — honest history is the goal. Exercises that were unplanned but logged (ad-hoc additions) appear at the bottom under "Extra".

- For `origin == "logged"`: an "Edit" button → opens the same form as logging (S16).
- For `origin == "healthkit"`: "Edit" is replaced by an inert info row "Imported from Health. Edit in the source app." (S26)

### Library tab

#### `ExerciseListView` — root

A searchable list of `Exercise` rows, default-sorted alphabetically, grouped by `trainingType`. Each row: name, training type icon, archived badge if applicable. **A "Show archived" toggle in the toolbar** (default off) reveals soft-deleted exercises (S22).

Toolbar `+` → `ExerciseEditView` (new).

#### `ExerciseDetailView` — drill-down (S19)

Header: name, training type, muscle group chips, description (markdown-rendered). Below: a list of every logged set (or session, for cardio/tennis/circuit) referencing this exercise, grouped by date — weight × reps for strength; date + duration for others. No charts in V1.

Toolbar: "Edit" → `ExerciseEditView`. "Archive" / "Restore" toggle (S22).

#### `ExerciseEditView` — sheet

Form: name (required), training type (segmented picker, defaults to `strength`), description (multi-line markdown), muscle groups (free-form chip input). Save / Cancel.

#### Inline exercise creation (used inside `WorkoutLogView`, S15)

When the user types an exercise name in an ad-hoc strength log that doesn't match an existing exercise (case-insensitive trim), a "+ Create '[name]'" row appears below the picker. Tap → creates the `Exercise` with the typed name, training type pre-set to `strength`, blank description, then selects it. No further detour.

### Metrics tab

#### `MetricsHomeView` — root

Three sub-sections in a single scroll, each with a "See all" link to a dedicated drill-down:

1. **Weight (S17)** — line chart for last 4 weeks with 7-day rolling average overlay; latest entry; "+" button → `WeightLogSheet`.
2. **Daily metrics** — small grid of today's values (HR rest, HRV, sleep, steps, active energy, recovery). Tap → `DailyMetricsHistoryView`.
3. **Body measurements (S20)** — last entry summary; "+ Add measurement" → `BodyMeasurementForm` (S21).

#### `WeightHistoryView`

Full-height chart + scrollable list of all `WeightEntry` rows. Each row: weight, date, source icon (manual / HK).

#### `DailyMetricsHistoryView`

A list of `DailyMetrics` rows newest first, each row showing the day's values in a compact grid. Above the list: a metric picker (HR rest / HRV / Sleep hours / Recovery / VO2max) → tapping draws a 30-day chart for that metric.

#### `BodyMeasurementForm` — sheet (S21)

All fields visible at once, prefilled from the previous entry: waist, abdomen, chest, hips, thigh, arm, optional weight, note. "Save" → new `BodyMeasurement` row.

#### `BodyMeasurementsHistoryView`

Side-by-side comparison: rows = entries (date), columns = metrics. Sticky leftmost column = date. Easy to eyeball deltas.

### Settings tab

Standard `Form` style.

#### `SettingsRootView`

Sections:

1. **Plans** → `PlansListView`
2. **Health & permissions** → `HealthPermissionsView`
3. **Reminders** → `RemindersSettingsView`
4. **Import** → `ImportPlanView` (also reachable from `PlansListView`)
5. **Units** (kg / km, read-only in V1 with a "coming in a future version" footnote — schema supports the toggle but UI defers it)
6. **About / version**

#### `PlansListView` — Settings → Plans

A list of all `Plan` rows. The active one is checkmarked. Each row tappable → `PlanEditView`. Toolbar `+` → `ImportPlanView` (recommended path) or "New empty plan".

Each row also has a context menu: "Make active", "Rename", "Delete" (with confirmation; deleting a plan removes its 7 PlanDays and any `PlannedWorkout`/`PlannedExerciseEntry` rows; logged sessions stay intact via the soft `sourcePlannedWorkoutId`).

#### `PlanEditView` — drill-down

Editor for one `Plan`. Top: name, notes, isActive toggle. Below: seven `PlanDay` sections (Mon–Sun), each listing planned workouts with reorder + add/delete. Tapping a `PlannedWorkout` → `PlannedWorkoutEditView` (sheet).

#### `PlannedWorkoutEditView` — sheet (S8)

Form for one planned workout: title, training type, notes, planned duration / distance (cardio types), and — for strength — a reorderable list of `PlannedExerciseEntry` rows with the exercise picker, sets, reps, weight.

#### `ImportPlanView` — drill-down (S2, S9, S10)

Three states:

- **Initial:** explanation + "Choose file" button → opens system document picker.
- **Validating:** spinner + filename.
- **Result.** Two outcomes:
  - **Errors found:** scrollable list of `(line, message)` rows. "Try again" returns to initial. No commit.
  - **Success:** confirmation summary — exercises (X new, Y updated), days (N replaced), plus a name field (defaulted to file's `name` metadata or filename, editable). If a plan with that name already exists: "This will update the existing 'Variant A'." Confirm → commit → toast → back to `PlansListView`.

A persistent "Download template" button at the bottom exports `training-plan.template.md` to the user's chosen location.

#### `HealthPermissionsView` — drill-down (S1, S23)

Lists each HealthKit data type with its current authorization status (granted / denied / not requested). For denied/not-requested rows: a "Request" button. iOS won't re-prompt once the user has answered, so denied rows include a "Open Health app" link.

Banner at top: a one-line health summary ("All access granted" / "Some access missing — features X / Y / Z affected").

#### `RemindersSettingsView`

Two reminder rows: weight, daily metrics. Each: enabled toggle + time picker (hour:minute).

## Onboarding flow (S1–S3)

Triggered on first launch only (`UserDefaults` flag, also persisted in `UserPreferences`). Three full-screen steps with a Skip link on each:

1. **Welcome** — what the app is, one screen of text + an illustration.
2. **Connect Health** — explains read/write scope, "Connect Health" button → system permission sheet → silent backfill begins. "Skip" → continue.
3. **Bring your plan** — "Import plan" → `ImportPlanView` flow (commits return here on success). "I'll set up later" → continue.

After step 3, the app lands on `TodayHomeView`. The onboarding flag is set regardless of which paths the user took.

A non-blocking banner appears at the top of `SettingsRootView` for any onboarding step the user skipped, until they complete it.

## Sheets vs. covers vs. drill-downs (decision rule)

- **Drill-down (`NavigationLink`):** content the user can return to in the same context (planned workout detail, exercise detail, plan editor).
- **Sheet (`.sheet`):** quick, dismissible inputs (weight log, morning metrics, body measurement, planned-workout edit, import flow). Sheets allow swipe-to-dismiss.
- **Full-screen cover (`.fullScreenCover`):** live workout logging only — swipe-to-dismiss is too easy to trigger mid-set. iPhone only; on Mac it's a centered modal.

## Keyboard, focus, and number entry

- All weight / measurement inputs use `.decimalPad`. Reps inputs use `.numberPad`.
- The strength logger's per-set rows use a focus chain: enter reps → tab → enter weight → tab → log. Hitting "log" advances focus to the next set's reps input (no dismissing the keyboard between sets).

## Empty states (must exist for every list)

- **Today, no plan:** "No plan yet. Import or create one." → `ImportPlanView` / new-plan flow.
- **Today, rest day:** "Rest day. + Log workout" still available.
- **History, no sessions:** "Logged workouts will show up here."
- **Library, no exercises:** "Build your library by importing a plan or adding exercises manually."
- **Metrics, no weight entries:** "Tap + to log your first weight."
- **Metrics, no body measurements:** "Add your first measurements to see deltas over time."
- **Plans list, no plans:** the same first-plan CTA as Today.

## What's deferred from V1 UI

- Charts beyond a basic weight line chart and per-metric 30-day charts in DailyMetricsHistory.
- Personal-record badges, progression suggestions.
- Drag-and-drop reorder on Mac.
- Native iPad / Mac sidebar customization (the iPad-style sidebar carries over for V1).
- Localization — English only in V1.
- Watch-app companion screens (V2).

## Resolved decisions

- **Tab count:** five tabs (Today / History / Library / Metrics / Settings). No collapse.
- **Plan switcher discoverability:** the plan-name chip on the Today header is the only entry point in V1. The single user knows it's there; no long-press shortcut needed.
- **Strength logger "skip":** explicit "Skip exercise" context-menu action. Skipped exercises are stored as skips (not zeros) and appear in `SessionDetailView` as a muted "Skipped" row — history reflects what actually happened.
