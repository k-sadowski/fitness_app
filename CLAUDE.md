# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Personal fitness tracker for the Apple ecosystem. Single-user app (the developer) backed by SwiftData + CloudKit, with HealthKit ingest. V1 targets iPhone + Mac (one SwiftUI multi-platform target; Mac runs via "Designed for iPad"). V2 adds Apple Watch.

The current code is a vertical slice: Metrics tab logs/lists weight; Today / History / Library / Settings tabs are `ContentUnavailableView` placeholders. HealthKit, plan editing, plan import, and workout logging are spec'd but not implemented.

## Repository layout

```
FitnessApp/                       Xcode multi-platform app target
├── FitnessApp.xcodeproj
├── FitnessApp/                   App sources (FitnessAppApp.swift, ContentView.swift)
├── FitnessAppTests/              XCTest target
└── FitnessAppUITests/            XCUITest target
Packages/
└── FitnessCore/                  Local Swift Package, depended on by every target
    └── Sources/FitnessCore/
        ├── Models/               SwiftData @Model types + SchemaV1
        ├── Persistence/          ModelContainerFactory, Seeder
        ├── HealthKit/            (empty — to be implemented)
        └── Domain/               (empty — to be implemented)
SPECS/                            Authoritative design docs (committed)
IMPORT DATA/                      Local-only training source docs (gitignored)
```

## Build & test

The Swift Package builds and tests standalone — use this for fast iteration on `FitnessCore`:

```bash
cd Packages/FitnessCore
swift build
swift test                                    # all tests
swift test --filter SchemaTests/testSeederCreatesDefaultPlanAndPreferences
```

Full app build/run is via Xcode (16+, iOS 17 / macOS 14 minimum — SwiftData requirement). Open `FitnessApp/FitnessApp.xcodeproj` and ⌘R. The app and UI test targets run from Xcode (`xcodebuild test -project FitnessApp/FitnessApp.xcodeproj -scheme FitnessApp -destination 'platform=iOS Simulator,name=iPhone 15'` if needed from CLI).

## Architecture

### Why a Swift Package for shared code

Xcode targets can't share source files directly but can all depend on a local Swift Package. `FitnessCore` is the single source of truth for models, persistence, HealthKit, and domain logic — guaranteeing the (future) watch target uses the same schema as the phone/Mac target with no drift.

### SwiftData + CloudKit constraints

Because `ModelContainer` is configured with `cloudKitDatabase: .private(...)` for the app, every `@Model` must obey CloudKit's rules — these are **load-bearing constraints**, not style preferences:

- All non-relationship properties must have a default value or be optional.
- Relationships must be optional or default to an empty array.
- No unique constraints (CloudKit doesn't enforce them) — uniqueness is enforced in code if needed.
- Use `UUID` identifiers, not auto-increment.

When adding a model: add it to `SchemaV1.models` and update `SchemaTests.testSchemaContainsAllModels`. Bump to a new `VersionedSchema` (e.g. `SchemaV2`) for any breaking change, and add a `SchemaMigrationPlan` — never mutate `SchemaV1` once data may exist.

### App startup

`FitnessAppApp.init` builds the `ModelContainer` via `ModelContainerFactory.makeApp()`, runs `Seeder.seedIfNeeded` (idempotent — creates the default `Plan` with seven `PlanDay`s and a `UserPreferences` row on first launch), then injects the container into the SwiftUI environment. Any setup failure is `fatalError` by design.

For previews and tests, use `ModelContainerFactory.makeInMemory()` — see existing `#Preview` blocks in `ContentView.swift` for the pattern (build container → optionally seed → attach via `.modelContainer(container)`).

### Manual entry is first-class

A core product invariant: every feature that surfaces HealthKit data must remain fully usable with HealthKit denied. HealthKit ingest is **additive**, never a replacement for manual entry. Imported records are read-only and badged; manual records are editable. Don't gate UI on HealthKit authorization.

### Plan ≠ history

Logged sessions snapshot the originating plan's name and workout title at log time. Plan edits must never rewrite logged history, and history detail screens display the snapshotted strings, not live plan data.

## Specs are authoritative

`SPECS/` is the source of truth for what to build. Read the relevant spec before implementing — they encode resolved UX decisions and rationale that aren't in the code yet:

- `architecture.md` — Xcode layout and tech rationale
- `product.md` — V1 scope, V2 candidates
- `data-model.md` — entity definitions, relationships, HealthKit ingest rules (including dedupe by `healthKitUUID`)
- `ui.md` — navigation graph, screen-by-screen spec, design principles
- `user-stories.md` — 28 day-in-the-life flows (S1–S28); UI spec references these as anchors
- `plan-import.md` + `templates/training-plan.template.md` — markdown plan format and parser behavior

## Conventions

- `IMPORT DATA/` is gitignored — never commit anything from it.
- `.claude/settings.local.json` is gitignored — local permissions only.
- The repo's commit style is concise, sentence-case subject lines describing the user-visible change (see `git log`).
