# Architecture & Tech Stack

## Goal

A personal fitness tracking app for use across the Apple ecosystem: iPhone (primary), Apple Watch, iPad, and Mac. Track exercises, log training sessions, record weight and progress.

## Tech Choice: Native Apple (SwiftUI + HealthKit)

A single SwiftUI codebase targets iPhone/iPad/Mac, with a separate watchOS target sharing the same models. HealthKit provides weight, workouts, and heart rate integration — the main reason to stay native.

**Tradeoff considered:** Cross-platform frameworks (Flutter, React Native, PWA) shorten the learning curve but make Apple Watch and HealthKit painful or impossible. Since Watch + Health integration is the whole point of staying on this hardware, native wins.

## Xcode Project Layout

```
fitness_app/
├── FitnessApp.xcodeproj
├── FitnessApp/                    # iOS + iPad + Mac (single multi-platform target)
│   ├── FitnessAppApp.swift        # @main, SwiftUI App
│   ├── Features/                  # one folder per feature (Workouts/, Weight/, Exercises/)
│   └── Assets.xcassets
├── FitnessAppWatch/               # watchOS app (separate target — required)
│   ├── FitnessAppWatchApp.swift
│   └── Views/
└── Packages/
    └── FitnessCore/               # local Swift Package, shared by all targets
        ├── Package.swift
        └── Sources/FitnessCore/
            ├── Models/            # SwiftData @Model types: Exercise, WorkoutSession, WeightEntry
            ├── Persistence/       # ModelContainer setup, CloudKit config
            ├── HealthKit/         # HealthKitStore — weight read/write, workout writes
            └── Domain/            # progress calculations, PR detection, etc.
```

## Key Tech Choices

- **SwiftUI** everywhere — single view layer for iPhone/iPad/Mac; watchOS gets its own (smaller) views but reuses models.
- **SwiftData** for persistence (the modern Core Data replacement) — define `@Model` once in `FitnessCore`, all targets share it.
- **CloudKit** sync — flip a flag on the SwiftData `ModelContainer` and data syncs across all devices automatically. Free, private to the user's iCloud account.
- **HealthKit** for weight + workout writes — so logged sessions appear in the Fitness/Health apps and on the Watch rings.
- **Mac target:** start with "Designed for iPad" (free, zero extra code). Promote to a native Mac target later only if a desktop-tailored layout is wanted.

## Why a Swift Package for Shared Code

Targets can't share source files directly, but they can all depend on a local Swift Package. Putting models, persistence, and HealthKit logic in `FitnessCore` means the watch app and phone app are guaranteed to use the same schema — no drift.

## Build Order

1. `FitnessCore` package with `Exercise`, `WorkoutSession`, `WeightEntry` `@Model`s + a `ModelContainer` with CloudKit enabled.
2. iOS app: log a workout, log a weight, see history. Just lists and forms — no charts yet.
3. Add HealthKit weight read/write.
4. Add the watch target — quick "log set" view.
5. Charts and progress views last.
