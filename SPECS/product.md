# Product Spec

## Audience

Single user (the developer). No multi-user, no auth, no sharing in scope. Data lives in the user's iCloud account via CloudKit.

## Platform Targets

- **V1:** iPhone + Mac (single multi-platform SwiftUI target; Mac runs via "Designed for iPad" initially).
- **V2:** Apple Watch.
- **Later:** native iPad layout, native Mac layout (sidebar / multi-column).

## Training Types in Scope

- **Strength (gym):** sets × reps × weight per exercise
- **Running:** distance + duration (later: route, pace)
- **Tennis:** duration + free-form notes (no per-shot tracking)
- **Walking pad:** distance + duration + speed

## V1 Scope (must-have to be useful daily)

### 1. Weight tracking

- **Manual entry is always available** — log a weight entry directly in the app (value, unit, timestamp; unit defaults to kg). This is the primary path and works even with HealthKit denied.
- View weight history as a list and a simple chart.
- Local notification reminder to log weight (configurable time, default ~08:00).
- Mirror manually-entered weights to Apple Health (HealthKit write) so they also appear in the Health app.
- Additionally, read existing weight samples from HealthKit on first launch and on demand, so the user's full history is in the app even if it was logged elsewhere.

### 2. Plan-driven day overview with multi-plan support

- User authors a **plan** (weekly recurring schedule) — either by editing in the app or by importing a structured markdown template (see feature 6).
- The user can have **several named plans** (e.g. "Variant A — tennis Wed only", "Variant B1 — tennis Wed + Sat", "Home cardio fallback") and **switch between them** at any time. Exactly one plan is active.
- Each plan day contains zero or more **planned workouts**, each tied to a training type and (for strength) a list of planned exercises with target sets/reps/weight.
- Home screen shows **today's planned workouts from the active plan** with their status: not started / in progress / done.
- A plan switcher is reachable in two taps from the home screen — for the "I'm not in the mood for the planned run, swap to home cardio" case. Switching is non-destructive: switching back later picks up where the other plan left off.
- Logged sessions snapshot the originating plan's name and workout title, so history reads correctly regardless of which plan is currently active.

### 3. Progress tracking for the day

- **Manual logging is always available** for every training type and is the primary path; HealthKit ingest is additive.
- Tap a planned workout → live logging screen.
- Strength: log actual sets (reps + weight) against the plan; see plan vs. actual side-by-side. Strength is **manual-only** in v1 (HealthKit doesn't carry sets/reps/weight in a useful way).
- Running / walking pad: start/stop timer, manual distance entry; if a matching HealthKit workout already exists for the time window, offer to attach its totals instead of re-typing.
- Tennis: start/stop timer + notes.
- Ad-hoc workouts: log a workout that wasn't on the plan (any training type) — same screens, no plan link.
- Mark workout as complete; this is what flips the home-screen status.

### 4. Exercise library (user-curated)

- User adds exercises: name, training type, optional description, optional muscle groups, optional notes/cues.
- Exercises are referenced from plan entries and from logged sessions (so renaming an exercise updates everywhere).
- No pre-seeded catalog — the user builds their library from their own plan.

### 5. HealthKit ingest (workouts and weight)

HealthKit ingest is **complementary** to manual entry, never a replacement. The app must remain fully usable with HealthKit permissions denied.

- Read **HKWorkout** samples from HealthKit and store a local copy in the app's database for analysis.
- On first launch (after permission): backfill the user's existing workouts and weight samples.
- Ongoing: subscribe via `HKObserverQuery` + a background delivery so new workouts logged elsewhere (Apple Watch, Strava sync, Nike Run Club, etc.) flow into the app automatically.
- Map HealthKit `HKWorkoutActivityType` to our `TrainingType` (running, tennis, walking pad → other; strength training, etc.). Anything we can't map is stored as `other` with the raw type preserved.
- Dedup rule: every imported sample is stored with its `HKSample.uuid`; re-imports are no-ops.
- Workouts the user logs in *our* app are also written back to HealthKit — but tagged with our bundle id so we can skip them on read (avoid round-trip duplicates).
- The user can browse imported workouts alongside ones they logged manually; both feed the same progress views.

### 6. Plan + exercise library import from a markdown template

The user already has a training plan drafted with Claude. V1 ships a **structured markdown template** (see `SPECS/plan-import.md` and `SPECS/templates/training-plan.template.md`) that they fill in and import to seed the exercise library and the weekly plan in one step.

- The user picks a `.md` file from the Files app (iOS document picker) or drops one onto the Mac app.
- A **strict, deterministic parser** reads the template — no AI in v1. Any deviation from the template structure surfaces a clear error pointing to the offending line.
- Import is **transactional**: parse first, validate, then commit; partial imports are not written.
- Import is **idempotent / merge-friendly**: re-importing the same file (or an edited version) updates existing exercises and plan days by stable name/weekday rather than creating duplicates. The user can re-import after editing the markdown.
- After import, everything is editable in the app exactly as if it had been entered manually.
- A "Download template" action in the app surfaces the template file so the user always has a starting point.
- Each import targets a **named plan**: re-importing the same file updates that plan; importing a different file as a new name creates a new plan, supporting the "Variant A / B1 / B2" workflow.

### 7. Daily metrics + body measurements

Beyond bodyweight, the user wants a daily morning snapshot and periodic tape-measure entries. Most numbers come from HealthKit; subjective fields are manual.

- **Daily metrics (one row per day):**
  - **Auto from HealthKit:** resting heart rate, HRV (SDNN), sleep hours (sum of asleep stages from the previous night), steps, active energy, VO2max.
  - **Manual:** sleep quality (1–10) and recovery / how-you-feel (1–10), plus an optional note.
  - Morning notification (default 08:15, configurable) prompts only for the manual fields. HealthKit fields populate in the background.
  - History view: a scrollable list / simple chart per metric, with a 7-day average summary.
- **Body measurements (sparse, ~monthly):**
  - Manual entry form: waist (at navel), abdomen (widest), chest, hips, thigh (widest), flexed arm, optional weight snapshot, note.
  - History view shows entries side-by-side so the user sees deltas at a glance.
- Both feature areas are **fully usable with HealthKit denied** — the auto fields just stay blank.

## Out of Scope for V1

- Apple Watch app (planned for v2)
- Charts beyond a basic weight trend and a workout list
- Personal-record detection / progression suggestions
- Photos, video form-checks, social features
- Plan periodization (multi-week cycles, deload weeks)
- Native iPad / Mac layouts — "Designed for iPad" is fine for v1
- Editing or splitting imported HealthKit workouts (read-only mirror; user edits the source app)

## V2+ Candidates (rough order)

1. Apple Watch app — quick "log set" + "start workout" + complications
2. Charts: per-exercise progression, volume, weekly summary
3. **AI-assisted plan import** — accept any markdown / free-text plan from Claude (or any source) regardless of structure, propose exercises and weekly schedule, let the user review and accept. Replaces the strict v1 template path; the template path stays as a deterministic fallback.
4. Native iPad / Mac layouts (sidebar, multi-column)
5. PR detection and suggestion of next target weight
6. Heart-rate / route / split data from imported HealthKit workouts

## Open Assumptions (please confirm or correct)

- **Units:** weights and bodyweight in **kg**, distance in **km**. App-wide preference, no per-entry toggle for v1.
- **Plan shape:** a **weekly recurring** template (Mon–Sun), not a dated multi-week program. Editing the plan affects future days only; logged history is immutable.
- **Reminders:** local notifications only (no server). One reminder for weight logging; later, optional reminder before each planned workout.
- **HealthKit:** v1 reads weight + workouts; v1 writes weight + workouts (logged in our app). On read, we filter out our own writes by source bundle id to avoid duplicates.
- **Offline-first:** the app must work fully offline. CloudKit syncs in the background when online.
