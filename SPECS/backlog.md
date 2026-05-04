# V1 Backlog

Polish and follow-ups discovered during V1 implementation. These are **post-V1, pre-V2**: small enough that they don't merit a V2 line item in [`product.md`](./product.md), but real enough to track. Items here should not block the V1 ship.

When picking one up, prefer linking the addressing PR/commit and crossing out the line rather than deleting it, until a sweep retires the file.

## Workout logging

- **S16 — edit a logged session.** History detail is read-only; the spec calls for an "Edit" button on `origin == "logged"` sessions that opens the same form as logging. Sets-only edit for strength + duration/distance/notes/RPE for cardio. The HK-imported branch (inert "Edit in the source app." row) is already in place.
- **Strength logger focus chain.** `ui.md` specifies reps → tab → weight → tab → Log → advances focus to the next set's reps input. Currently only the last hop is wired (focus returns to reps after Log).
- **Empty session leak on app kill.** If the user opens `WorkoutLogView` and the app is killed before they tap Discard or Finish, an empty `WorkoutSession` is left in the DB. `WorkoutStatusCalculator` correctly reports it as `notStarted`, but it accrues over time. Add a startup sweep that deletes sessions with `endedAt == nil` and no content older than ~24h.
- **Cardio HK match banner (S12).** "If a `HKWorkout` exists within ±15 min and matches type, offer 'Use Apple Watch totals' to replace the form values." Blocked on HealthKit ingest landing.
- **HKWorkout writeback (S11).** Sessions logged in-app should be mirrored to HealthKit (tagged with our bundle id so the read filter skips them). Blocked on HealthKit ingest.
- **Strength training-type swap.** Changing a `PlannedWorkout.trainingType` away from `.strength` in the editor leaves orphaned `PlannedExerciseEntry` rows attached. Either prompt the user, or clear them, or hide the section non-destructively.

## Today

- **`PlannedWorkoutDetailView` "Logged" state should link to history.** When `status == .done`, the section currently shows a static "Logged. View in History." label. Make it a `NavigationLink` (or `Button` that switches to History tab + pushes detail) to the corresponding `SessionDetailView`.
- **Today's `+ Log workout` flow uses two sheets stacked.** `AdHocLogTypePicker` (sheet) → on dismiss → `WorkoutLogView` (fullScreenCover) via a delayed state hop. Fine functionally but a single picker-then-cover transition would feel snappier.

## History

- **"Workouts done / planned" uses the *current* active plan's count.** Historical weeks show the wrong `planned` denominator if the user switches plans or edits the plan's per-day count later. Acceptable for V1 (single user, low churn) but worth noting. Fix would be to snapshot the plan's weekly count into the first session of each week, or compute from logged sessions only.
- **"This week" anchor / scroll-to-top.** No visual cue distinguishing the current week from past ones; the list is purely chronological. Consider a "This week" pill on the top section header.

## Metrics

- **Weight chart.** `MetricsHomeView` lists entries but the line chart + 7-day rolling average overlay (S17) is not built. The "All weight entries" link goes to a plain list.
- **Weight write-to-HealthKit.** S4 says manual entries should mirror to Apple Health. Not yet wired; blocked on HealthKit slice.
- **Daily metrics, body measurements.** Spec'd (S5, S20, S21) but no UI exists. Could ship without HealthKit (manual sliders only) ahead of the full HK ingest.

## Settings

- **Reminders settings UI is missing.** `UserPreferences` carries the reminder fields and defaults, but `RemindersSettingsView` is not built and no notifications are scheduled.
- **About / version, Units rows.** Standard "About" row and the read-only "Units (coming in a future version)" footnote per `ui.md` aren't in `SettingsRootView` yet.
- **Health & permissions, Import** — same as above; spec'd, not built. (Both blocked on their respective feature slices.)

## Onboarding

- Full onboarding flow (S1–S3) is not implemented. App lands directly on Today; the `Seeder` creates the default Plan + `UserPreferences` on first launch. The "non-blocking banner in Settings for skipped onboarding steps" is also pending.

## Plan import (markdown)

- Not implemented. The template file at `SPECS/templates/training-plan.template.md` exists; the parser, document picker, validation/error UI, and the idempotent commit path described in `SPECS/plan-import.md` are all V1 scope but not yet built.

## Library tab

- Tab is a `ContentUnavailableView` placeholder. `ExerciseListView`, `ExerciseDetailView`, `ExerciseEditView`, and the soft-delete archive toggle (S22) are V1 scope.

## Schema / data integrity

- **One-active-plan invariant on creation.** `PlanActivator` enforces it on toggling, but new plans created via `PlansListView` should also default to `isActive == false` regardless of how they're constructed; verify no path creates a second active plan.
- **`DailyMetrics` per-day uniqueness.** Open question in `data-model.md` — read-path dedup by `date` (latest modified wins) is acceptable, but flag for re-evaluation once the daily-metrics UI lands.

## Cross-cutting

- **iOS 17 / macOS 14 minimum.** Verify on the actual targets — current development is on iOS 26 simulators; check that nothing inadvertently used a 18+ API.
- **Accessibility audit.** No VoiceOver pass yet — labels mostly inferred from system controls; the timer display, status pills, and HK badge in particular deserve explicit `accessibilityLabel`s.
- **Localization.** English-only is the V1 decision, but strings are scattered as literals; if we ever flip the switch, a string-table sweep is needed.
