# Fitness App

A personal fitness tracker for the Apple ecosystem — a single-user app to log training, follow a weekly plan, track bodyweight and daily health metrics, and analyze progress over time.

## What it does

- **Log training across multiple sports.** Strength (sets × reps × weight), running, tennis, walking-pad sessions, and at-home circuits.
- **Plan-driven days.** Author one or more weekly plans (e.g. "Variant A — tennis only Wed", "Variant B1 — tennis Wed + Sat", "Home cardio fallback") and switch between them with two taps when the day calls for something different.
- **Plan import from a markdown template.** Bring a Claude-drafted training plan into the app by filling a structured `.md` template — the app parses it and seeds the exercise library + weekly plan in one step.
- **Bodyweight tracking with morning reminders.** Manual entry, mirrored to Apple Health.
- **Daily health snapshot.** Resting heart rate, HRV, sleep, steps, active energy, and VO2max read from HealthKit, plus manual sleep-quality and recovery scores.
- **Body measurements.** Periodic tape-measure entries (waist, chest, hips, thigh, arm).
- **HealthKit ingest.** Read existing weight samples and `HKWorkout` history (Apple Watch, third-party apps) so all data lives in one place. Manual entry remains first-class — the app stays fully usable with HealthKit denied.
- **iCloud sync.** Data syncs across the user's devices automatically via CloudKit; works offline.

## Platform targets

- **V1:** iPhone + Mac (single SwiftUI multi-platform target; Mac runs initially via "Designed for iPad").
- **V2:** Apple Watch (quick-log workouts, complications) + AI-assisted plan import.
- **Later:** native iPad and Mac layouts, charts and progression analysis, PR detection.

## Tech stack

- **SwiftUI** for all UI
- **SwiftData** + **CloudKit** for persistence and sync
- **HealthKit** for weight, workouts, and daily metrics
- A local **`FitnessCore`** Swift Package shared by every target (models, persistence, HealthKit, domain logic)

## Specs

Full design lives under [`SPECS/`](./SPECS):

- [`architecture.md`](./SPECS/architecture.md) — Xcode project layout and tech rationale
- [`product.md`](./SPECS/product.md) — V1 scope, V2 candidates, open assumptions
- [`data-model.md`](./SPECS/data-model.md) — entities, relationships, HealthKit ingest rules
- [`plan-import.md`](./SPECS/plan-import.md) — markdown template format and parser behavior
- [`templates/training-plan.template.md`](./SPECS/templates/training-plan.template.md) — fillable plan template

## Status

Specs phase. No code yet — Xcode project scaffolding is the next step.
