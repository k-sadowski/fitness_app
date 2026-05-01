# Plan Import Spec (V1, deterministic markdown template)

## Goal

Let the user seed the exercise library and the weekly plan from a single structured markdown file they fill in (typically based on a Claude-drafted plan). V1 uses a strict template and a deterministic parser — no LLM in the loop. V2 will add AI-assisted import that handles arbitrary structure.

## File Format

A single `.md` file with three top-level sections, in this order:

1. `# Plan Metadata` (optional)
2. `# Exercises`
3. `# Weekly Schedule`

Section headings are matched **case-insensitively** but the order is fixed. Anything outside these sections is treated as user notes and ignored.

### 1. `# Plan Metadata` (optional)

A YAML code block. All keys optional.

```yaml
name: "Hypertrophy + endurance, May 2026"
units:
  weight: kg     # one of: kg, lb (v1 stores kg internally; lb is converted on import)
  distance: km   # one of: km, mi
notes: "Free-form notes about the program."
```

### 2. `# Exercises`

One `## ExerciseName` subheading per exercise, followed by a YAML code block with the exercise's metadata.

```markdown
## Barbell Back Squat

\`\`\`yaml
type: strength            # strength | running | tennis | walkingPad
muscles: [quads, glutes, lower_back]
description: |
  Brace, sit between the hips, drive through midfoot.
  Keep the bar over midfoot.
\`\`\`
```

Rules:

- `type` is required and must be one of the four `TrainingType` values.
- `muscles` is optional; freeform tags.
- `description` is optional, supports multi-line YAML strings.
- Exercise name is the canonical key. Re-importing with the same name **updates** the existing exercise; renaming an exercise in the library after import is the user's job (we don't track renames across imports).

### 3. `# Weekly Schedule`

One `## Day` subheading per weekday, in any order. Recognised day names: `Monday`, `Tuesday`, `Wednesday`, `Thursday`, `Friday`, `Saturday`, `Sunday` (English only in v1; case-insensitive). Days not present in the file are imported as **rest days** (zero planned workouts).

Each day contains zero or more `### WorkoutTitle` subheadings, each followed by a YAML code block describing the planned workout.

#### Strength workout

```markdown
### Push Day

\`\`\`yaml
type: strength
notes: "Compound first, accessories after."
exercises:
  - name: "Bench Press"     # must match an entry in the # Exercises section
    sets: 4
    reps: 6
    weight: 80              # in metadata.units.weight; nil/omit = bodyweight
  - name: "Overhead Press"
    sets: 3
    reps: 8
    weight: 50
\`\`\`
```

Rules:

- Each `exercises[].name` **must** match an exercise defined in the `# Exercises` section. Unknown names abort the import with a clear error.
- `sets`, `reps` are required integers ≥ 1.
- `weight` is optional; omitted = bodyweight.

#### Cardio / tennis workout

```markdown
### Easy Run

\`\`\`yaml
type: running              # running | tennis | walkingPad
duration_minutes: 30        # optional
distance_km: 5              # optional, ignored for tennis
notes: "Zone 2."
\`\`\`
```

Rules:

- `type` is required.
- For `running` / `walkingPad`: `duration_minutes` and `distance_km` are both optional but at least one is recommended.
- For `tennis`: `distance_km` is ignored.

## Parser Behavior

- Written in pure Swift inside `FitnessCore` (no third-party YAML lib if avoidable; use `Yams` if needed — small, MIT-licensed).
- Parse → validate → produce an `ImportPlan` value object with the full set of `Exercise`, `PlanDay`, `PlannedWorkout`, `PlannedExerciseEntry` instances **in memory**.
- Only on successful validation do we persist anything (single `ModelContext` transaction).
- Errors collect line numbers from the original markdown where possible, and are surfaced in the import UI as a list ("Line 42: unknown exercise 'Front Squat'").

## Merge Semantics

- **Exercises** are matched by `name` (case-insensitive, trimmed). Match → update fields. No match → insert.
- **PlanDays** always exist (seven seeded rows). Import **replaces** the `plannedWorkouts` of each day mentioned in the file. Days **not** mentioned are left untouched (so you can import a partial plan and edit the rest in-app).
- **Never deletes user-logged sessions.** Import only touches the library and the plan template.

## UI Flow (V1)

1. Settings → "Import plan from markdown".
2. iOS document picker / Mac file picker.
3. Parse → if errors, show the error list, no commit.
4. If valid, show a confirmation screen: "X exercises (Y new, Z updated), N days will be replaced." User taps Import.
5. Toast: "Imported. Plan and library updated."
6. A "Download template" link in the same screen exports `training-plan.template.md` to share.

## V2 Extension (not in V1)

- Drop the strict template requirement. Pass the file (or pasted text) to a Claude-powered importer that proposes a structured plan, then reuses the same v1 commit pipeline after the user reviews. The deterministic template parser stays as a power-user fallback.

## Open Questions

- **Unit conversion on import:** if the file declares `units.weight: lb`, do we convert to kg silently or surface a confirmation? Recommendation: convert silently, show the converted values on the confirmation screen.
- **Localization of day names:** v1 English-only. Polish / others can be added when the app gets localized.
- **YAML library choice:** stdlib has no YAML parser. Either add `Yams` (small, well-maintained) or restrict the template to a JSON code block. Recommendation: ship `Yams`; YAML is friendlier to hand-edit.
