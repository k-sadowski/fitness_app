# Data Model Spec

All entities are SwiftData `@Model` types defined in the `FitnessCore` package. CloudKit-syncable, so they obey CloudKit's constraints:

- All non-relationship properties must have a default value or be optional.
- Relationships must be optional or have a default (empty array).
- No unique constraints (CloudKit doesn't enforce them).
- Use `UUID` identifiers, not auto-increment.

## Entities

### `Exercise`
The user-curated library entry.

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | primary identifier |
| `name` | `String` | e.g. "Barbell Back Squat" |
| `trainingType` | `TrainingType` (enum, raw `String`) | strength / running / tennis / walkingPad / circuit / other |
| `descriptionText` | `String?` | how to perform, cues |
| `muscleGroups` | `[String]` | freeform tags for v1 |
| `isArchived` | `Bool` | default `false`. Soft-delete flag — archived exercises hide from pickers but preserve history. |
| `createdAt` | `Date` | |
| `plannedEntries` | `[PlannedExerciseEntry]` (inverse) | |
| `loggedSets` | `[StrengthSet]` (inverse) | |

### `TrainingType` (enum)

`strength`, `running`, `tennis`, `walkingPad`, `circuit`, `other`. Stored as raw `String` for forward-compat.

- `circuit` — bodyweight rounds-based session (e.g. "5 exercises × 1 min × 6 rounds" home cardio). Logged as a `CardioSummary` (duration / energy) plus optional notes; no `StrengthSet` rows.
- `other` — fallback for HealthKit activity types we haven't mapped (hike, yoga, rowing, etc.); `WorkoutSession.rawActivityTypeRawValue` preserves the original.

### `Plan`

A named weekly plan template. The user can have several (e.g. "Variant A — tennis only Wed", "Variant B1 — tennis Wed + Sat") and switch between them.

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | |
| `name` | `String` | e.g. "Variant A", "Off-season" |
| `notes` | `String?` | description, when to use |
| `isActive` | `Bool` | exactly one plan should be active at a time (enforced in code, not by CloudKit) |
| `createdAt` | `Date` | |
| `days` | `[PlanDay]` | seven entries; cascade delete |

On first launch: create one default `Plan` named "Default" with `isActive = true` and its seven `PlanDay` rows. Plan import creates or updates a `Plan` by name.

### `PlanDay`

One day of one plan.

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | |
| `weekday` | `Int` | 1 = Monday, 7 = Sunday (ISO 8601) |
| `plannedWorkouts` | `[PlannedWorkout]` | order matters; cascade delete |
| `plan` | `Plan?` (inverse) | |

Each `Plan` owns exactly seven `PlanDay` rows. The user edits them; they're never deleted while the plan exists.

### `PlannedWorkout`
A planned workout slot for a given weekday.

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | |
| `trainingType` | `TrainingType` | |
| `title` | `String` | e.g. "Push Day", "Easy Run" |
| `notes` | `String?` | |
| `orderIndex` | `Int` | for stable ordering within a day |
| `plannedExercises` | `[PlannedExerciseEntry]` | only meaningful for strength; cascade delete |
| `plannedDurationMinutes` | `Int?` | for running / tennis / walking |
| `plannedDistanceKm` | `Double?` | for running / walking |
| `day` | `PlanDay?` (inverse) | |

### `PlannedExerciseEntry`
A line item in a planned strength workout: "3×8 @ 80kg of Squat".

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | |
| `exercise` | `Exercise?` | reference into the library |
| `targetSets` | `Int` | |
| `targetReps` | `Int` | |
| `targetWeightKg` | `Double?` | nil = bodyweight |
| `orderIndex` | `Int` | |

### `WorkoutSession`

A real, dated, logged session. Created either by the user (starting a planned or ad-hoc workout) or by the HealthKit ingest pipeline.

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | |
| `startedAt` | `Date` | |
| `endedAt` | `Date?` | nil while in progress |
| `trainingType` | `TrainingType` | mapped from HK activity type if imported |
| `title` | `String` | snapshot from `PlannedWorkout.title`, or "Run", "Walk", etc. if imported |
| `notes` | `String?` | |
| `sourcePlannedWorkoutId` | `UUID?` | soft link — survives plan edits |
| `origin` | `String` | "logged" \| "healthkit" — controls editability |
| `healthKitUUID` | `UUID?` | `HKWorkout.uuid` for imported sessions; used for dedup on re-import |
| `sourceBundleId` | `String?` | bundle id of the app that produced the HK sample (Apple Watch, Strava, our own — used to skip our own writes on read) |
| `rawActivityTypeRawValue` | `Int?` | `HKWorkoutActivityType.rawValue` — preserved when we couldn't map to a `TrainingType` |
| `totalEnergyBurnedKcal` | `Double?` | from HKWorkout if present |
| `totalDistanceKm` | `Double?` | from HKWorkout if present (also flows into `cardio.distanceKm`) |
| `strengthSets` | `[StrengthSet]` | cascade; empty for imported cardio |
| `cardio` | `CardioSummary?` | cascade |
| `skippedExerciseIds` | `[UUID]` | `Exercise.id`s the user explicitly skipped during a planned strength session — surfaced as "Skipped" rows in history |

### `StrengthSet`
One set inside a session.

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | |
| `exercise` | `Exercise?` | |
| `setNumber` | `Int` | 1-indexed within the exercise |
| `reps` | `Int` | |
| `weightKg` | `Double?` | nil = bodyweight |
| `rpe` | `Double?` | optional, deferred from v1 UI but room in schema |
| `completedAt` | `Date` | |
| `session` | `WorkoutSession?` (inverse) | |

### `CardioSummary`
Aggregate totals for running / tennis / walking sessions. One per session.

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | |
| `durationSeconds` | `Int` | |
| `distanceKm` | `Double?` | nil for tennis |
| `averageSpeedKmh` | `Double?` | derived but stored |
| `session` | `WorkoutSession?` (inverse) | |

### `WeightEntry`

A bodyweight log.

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | |
| `weightKg` | `Double` | |
| `recordedAt` | `Date` | |
| `source` | `String` | "manual" \| "healthkit" — for dedup |
| `healthKitUUID` | `UUID?` | if mirrored to Health, the HK sample id |
| `note` | `String?` | |

### `DailyMetrics`

One row per calendar day, capturing the morning health snapshot. Most fields are sourced from HealthKit; subjective fields are manual-only. All fields are optional — partial rows are normal.

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | |
| `date` | `Date` | normalized to local-day midnight; one row per day per device — dedup by date on read |
| `restingHeartRateBpm` | `Int?` | HK |
| `hrvSdnnMs` | `Double?` | HK (`HKQuantityTypeIdentifier.heartRateVariabilitySDNN`) |
| `sleepHours` | `Double?` | HK; sum of asleep stages for the previous night |
| `sleepQuality` | `Int?` | manual, 1–10 |
| `recoveryScore` | `Int?` | manual, 1–10 — user's subjective wakeup feeling |
| `steps` | `Int?` | HK |
| `activeEnergyKcal` | `Double?` | HK |
| `vo2maxMlKgMin` | `Double?` | HK; updates infrequently |
| `note` | `String?` | freeform |

### `BodyMeasurement`

Periodic tape-measure snapshot (the user takes monthly).

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | |
| `recordedAt` | `Date` | |
| `weightKg` | `Double?` | optional snapshot to compare alongside circumference |
| `waistCm` | `Double?` | at navel |
| `abdomenCm` | `Double?` | widest point |
| `chestCm` | `Double?` | |
| `hipsCm` | `Double?` | |
| `thighCm` | `Double?` | widest |
| `armCm` | `Double?` | flexed biceps |
| `note` | `String?` | |

### `UserPreferences` (single row)

| Field | Type | Notes |
|---|---|---|
| `weightReminderEnabled` | `Bool` | default `true` |
| `weightReminderTime` | `Date` | only hour/minute used; default 08:00 |
| `weightUnit` | `String` | "kg" for v1; schema allows future "lb" |
| `distanceUnit` | `String` | "km" for v1 |
| `dailyMetricsReminderEnabled` | `Bool` | default `true` — morning prompt for sleep quality / recovery |
| `dailyMetricsReminderTime` | `Date` | only hour/minute; default 08:15 |

## Relationships Diagram (v1)

```
Plan >── PlanDay >── PlannedWorkout >── PlannedExerciseEntry >── Exercise
                                                                      │
                                                                      └─< StrengthSet >── WorkoutSession ──< CardioSummary
                                                                                                │
                                                                                                └─ sourcePlannedWorkoutId (soft)

WeightEntry        (standalone)
DailyMetrics       (one per day)
BodyMeasurement    (sparse)
UserPreferences    (singleton)
```

## Migration & Seeding

- On first launch: create one `Plan` named "Default" with `isActive = true` and its seven `PlanDay` rows; create a default `UserPreferences`.
- Switching active plans: set `isActive = false` on the previous active plan and `true` on the new one in the same `ModelContext` save. The home screen always reads from the active plan.
- Schema version baked into `Schema(versionedSchema: ...)` — bump on any breaking change. SwiftData lightweight migration handles additive changes for free.

## Why "soft link" from session to planned workout?

Editing the plan must not retroactively rewrite history. We snapshot `title` and reference the planned workout by `UUID` only, so deleting a `PlannedWorkout` doesn't orphan or corrupt logged sessions.

## HealthKit Ingest Rules

Manual entry and HealthKit ingest coexist on equal footing. Every list/chart unions both sources; the user can always create a `WorkoutSession` or `WeightEntry` directly in the app, regardless of HealthKit permission state.

- `origin == "logged"` records are **fully editable** in our UI (the user typed them).
- A `WorkoutSession` with `origin == "healthkit"` is **read-only in our UI**. The user edits the source app (Health, Strava, etc.); we re-import on next sync.
- **Dedup on import** (workouts): query existing sessions by `healthKitUUID`; skip if present.
- **Skip our own writes** (workouts): when reading from HealthKit, ignore samples whose `sourceBundleId` matches our app's bundle id. This prevents the round-trip duplicate we'd otherwise get for sessions logged inside the app and mirrored to Health.
- **Dedup on import** (weight): same pattern — `WeightEntry.healthKitUUID` is unique per HK sample; re-imports are no-ops. Manual entries in the app are written to HealthKit and stored locally with `source = "manual"` and the HK uuid filled in after the write succeeds.
- **Activity-type mapping:** keep a single mapping table from `HKWorkoutActivityType` → `TrainingType`. Anything not mapped (e.g. yoga, hike) lands as `TrainingType.other` (to be added) with `rawActivityTypeRawValue` preserved so we can map it later without re-importing.

## Open Questions

- **Set RPE / notes per set:** schema has `rpe` and could add per-set notes; v1 UI won't expose them. Keep the columns or drop until needed?
- **Tennis intensity:** any structured data (e.g. "match" vs "drill") or strictly free-form notes for v1?
- **Imported cardio detail:** v1 stores totals only (distance, duration, energy). Heart-rate samples and route polylines are deferred — confirm we don't need them in v1 charts.
- **`DailyMetrics` per-day uniqueness:** CloudKit can't enforce a unique key on `date`. We deduplicate in the read path (always pick the row whose modified timestamp is latest). Acceptable, or do we need a more rigorous strategy?
- **Circuit logging detail:** v1 logs `circuit` sessions as duration + energy + notes only (no per-round breakdown). If you want per-round logging later, we'd add a `CircuitRound` child entity — keep it as a v2 candidate?
