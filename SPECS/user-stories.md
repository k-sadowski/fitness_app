# User Stories (V1)

Concrete day-in-the-life flows for the single user the app is built for. Stories are organized by frequency and pin down what the UI must support. Each story uses "I" because the user is the developer.

## Persona

- 30s, in the Apple ecosystem (iPhone, MacBook, Apple Watch Ultra 3, iPad).
- In a structured cut (89 → 73 kg over 7–9 months) while training for tennis + running + gym + walking pad.
- Technical user; comfortable with markdown, files, and reading a chart. Won't tolerate friction in the daily logging flows — those have to be fast or they will not happen.
- Trains across multiple plan variants (tennis Wed only / Wed + Sat / Wed + Sun) and decides Monday morning which week he's running.

## First-run / onboarding

### S1. Grant HealthKit access on first launch

**As me, I want the app to ask for HealthKit access during first-run setup, so that my existing weight + workout history shows up immediately and Apple Watch sessions flow in automatically.**

- App opens → onboarding screen explaining what data is read/written.
- Tap "Connect Health" → system permission sheet for: bodyweight (read/write), workouts (read/write), resting HR, HRV, sleep, steps, active energy, VO2max (read).
- If the user denies any or all: app proceeds, manual entry remains primary, a banner in Settings invites them to grant later.
- App backfills existing weight + workout samples in the background; a small status row shows "Importing… 47 of 312".

### S2. Import a training plan from markdown

**As me, I want to import the training plan I drafted with Claude, so that the exercise library and weekly schedule are populated without retyping.**

- After permissions: an onboarding step offers "Import plan" or "I'll set it up later".
- Tap "Import plan" → document picker → choose the `.md` file.
- Parser runs; if it fails, show a list of errors with line numbers; no commit.
- If it succeeds, show a confirmation summary: "12 exercises (12 new), 7 days will be set up. Plan name: [editable text field]." Default name comes from the file's `name` metadata or filename.
- Confirm → toast "Plan imported." → home screen.

### S3. Skip onboarding and set up later

**As me, I want to skip everything in onboarding and go straight to the app, so that I can explore before committing.**

- Each onboarding screen has a "Skip" link.
- App lands on the home screen with an empty state: "No plan yet — Add a plan" / "No weight entries — Log weight". Both lead to the same flows as the dedicated paths.

## Morning routine (daily)

### S4. Log my morning weight

**As me, I want to log my morning weight in under 5 seconds, so that the daily reminder doesn't become a chore I avoid.**

- Notification at 08:00 → tap → opens directly into the weight log sheet, kg field already focused, suggested value = last entry rounded to nearest 0.1.
- Type weight → "Log" → sheet dismisses, home screen shows the new value with a tiny delta vs. yesterday.
- The value is also written to Apple Health.

### S5. Log sleep quality and recovery

**As me, I want a brief morning prompt for sleep quality and recovery, so that I have subjective data to pair with HealthKit's HR / HRV.**

- Notification at 08:15 (after weight reminder) → opens a single-screen form with two 1–10 sliders (sleep quality, recovery) and an optional note field.
- Resting HR, HRV, sleep hours, steps, active energy, VO2max are shown above the sliders, populated from HealthKit (last night's data). Read-only.
- "Save" → home screen.

### S6. See today's plan at a glance

**As me, I want the home screen to show today's planned workouts the moment I open the app, so that I never wonder what I'm doing today.**

- Home screen has three sections: today's date + active plan name; today's planned workouts (with status pills: not started / in progress / done); a compact weight + recovery summary.
- Tapping a planned workout opens its detail / log screen.
- **Status pill rules:**
  - **Not started** — no `WorkoutSession` exists for that planned workout today, or one exists but has no logged content (no `StrengthSet` rows, no cardio totals, no notes). Opening the log screen and bailing without entering anything keeps the pill at "not started".
  - **In progress** — a `WorkoutSession` exists with at least one piece of logged content and is not finished.
  - **Done** — the user tapped "Finish workout"; for strength, this requires having logged something for every planned exercise (or explicitly skipped them); for cardio/tennis/circuit, it requires duration > 0.
- If today is a rest day, the workout section reads "Rest day."

## Plan management & switching

### S7. Switch to a different plan because I don't feel like running

**As me, I want to switch from "Variant A" to "Home cardio" in two taps, so that when I wake up tired I can swap the planned run for a home circuit without editing anything.**

- Tap the plan name on the home screen → bottom sheet listing my plans (active one checkmarked) + "Manage plans".
- Tap a different plan → sheet dismisses, home screen now shows the new plan's today.
- The previous plan is preserved untouched; switching back later just works.

### S8. Edit a planned workout in-app

**As me, I want to tweak a planned exercise's target weight directly in the app, so that I don't have to go back to the markdown file for small progressions.**

- From a planned workout's detail screen → "Edit plan" → form shows the planned exercises and targets.
- Change the weight on Bench Press from 80 to 82.5 → save.
- Edits affect future days; logged sessions keep their snapshot.

### S9. Add a brand-new plan from a different markdown file

**As me, I want to import a second markdown file as "Variant B1", so that I can pre-load all my variants and pick on Monday morning.**

- Settings → Plans → "Import plan" → file picker → in the confirmation screen, name it "Variant B1" → confirm.
- Plans list now shows two; the previously-active one stays active until I switch.

### S10. Re-import an updated markdown after editing it

**As me, I want re-importing the same file to update the existing plan rather than create a duplicate, so that I can keep markdown as my source of truth and re-sync.**

- Settings → Plans → "Import plan" → pick the same file → in the confirmation screen, the parser detects it matches an existing plan by name and shows "Update Variant A: 0 new exercises, 3 updated, 7 days will be replaced."
- Confirm → existing plan and exercises updated in place; logged history untouched.

## Workout logging

### S11. Log a strength session against the plan

**As me, I want a fast log screen that shows planned vs. actual side-by-side, so that I can tap through a Push Day in 60 seconds of UI time.**

- Tap "Push Day" on the home screen → log screen: list of planned exercises with sets as rows.
- Each row shows planned (e.g. 4×6 @ 80) on the left; tap → expands to per-set inputs (reps, weight). Defaults to the planned values; usually I just hit "log" four times.
- After all exercises, "Finish workout" → status flips to done on the home screen.
- The session is also written to HealthKit as a workout (strength training).

### S12. Log a cardio session (run / walking pad)

**As me, I want a simple start/stop timer and distance entry, so that I can log a 5 km easy run without fiddling.**

- Tap "Easy Run" → screen with start button.
- Start → timer ticks; when done, "Finish" → form prefilled with planned distance + elapsed duration. Edit if needed.
- Optionally: if a HealthKit workout exists within **±15 minutes of the session start time** (and matches training type), offer "Use Apple Watch totals instead" — one tap to attach distance + duration + calories from that HK sample.
- Save → home screen.

### S13. Log tennis

**As me, I want to log tennis with a timer and a notes field, so that the session is in my history without me having to invent structured data that doesn't exist.**

- Tap "Tennis" → start timer → "Finish" → notes field + RPE 1–10 → save.

### S14. Log a circuit (home cardio)

**As me, I want to log a home-cardio circuit as a single timed session, so that "5 exercises × 1 min × 6 rounds" doesn't force me to log 30 individual sets.**

- Tap a `circuit` planned workout → start timer → "Finish" → form has duration + optional notes (which variant, how rounds went) + RPE.
- The plan's exercise list is shown as reference, not as a checklist.

### S15. Log an ad-hoc workout that wasn't planned

**As me, I want to log a workout that wasn't on the plan (a spontaneous run, an unplanned tennis match), so that my history reflects reality.**

- Home screen → "+ Log workout" button → choose training type → same logging screens as the planned versions, just without a plan link.
- Saved session has `sourcePlannedWorkoutId == nil`.
- For strength: if I type an exercise name not in the library, an "+ Create '[name]'" row appears below the list. Tapping it inline-creates the exercise (training type pre-filled to `strength`, description blank, editable later in the library) and selects it. No detour through the Library tab.

### S16. Manually edit a logged session after the fact

**As me, I want to fix a typo in a set I logged yesterday, so that data quality stays high.**

- Tap any past session → "Edit" → same form as logging → save.
- Sessions imported from HealthKit (`origin == "healthkit"`) are read-only with an explanation: "Edit in the source app."

## Reviewing data

### S17. See my weight trend

**As me, I want to see my weight over the last 4 weeks at a glance, so that I'm reading the trend (not yesterday-vs-today noise).**

- Tab/menu → "Weight" → list + simple line chart, with a 7-day rolling average overlay.
- Manual entries and HealthKit-sourced entries appear in the same list, distinguishable by a small icon.

### S18. See last week's training

**As me, I want a weekly summary card on Sunday evening, so that I know how I did against the plan.**

- Tab/menu → "History" → grouped by week → each week has totals: workouts done / planned, run km, walking-pad km, tennis sessions, strength sessions, total active energy.
- Tapping a week expands the day list.

### S19. See an exercise's progression

**As me, I want to tap "Bench Press" in the library and see every set I've ever done, so that I can confirm I'm progressing.**

- Library → tap an exercise → detail screen with description + a list of all logged sets across all sessions, grouped by date, weight × reps.
- Charts deferred to V2; v1 is fine with a list.

### S20. See my body measurements over time

**As me, I want to see my last 6 months of waist / chest / hips, so that visual progress is visible even when the scale stalls.**

- Tab/menu → "Measurements" → list of entries + a small horizontal-scroll chart per metric.
- "+ Add measurement" → form pre-filled from the previous entry; I overwrite what I measured this month.

## Periodic / monthly

### S21. Take monthly body measurements

**As me, I want a single form for all body measurements, so that I do them in one sitting and don't lose data.**

- Measurements tab → "+ Add" → form with all fields visible (waist, abdomen, chest, hips, thigh, arm, optional weight, note) → save.

### S22. Edit my exercise library

**As me, I want to add a new exercise (e.g. "Cable Pulldowns") that I want to start doing, so that my next plan import — or in-app edit — can reference it.**

- Library tab → "+ New exercise" → name, type, description, muscle groups → save.
- The exercise becomes selectable in any planned-workout edit screen.
- **Deleting an exercise is a soft-delete:** the exercise gets an `isArchived` flag, disappears from picker UIs, but remains intact for any past sessions or planned entries that reference it (history stays valid). Library has a "Show archived" toggle for restoring or pruning.

## Edge cases & failure modes

### S23. Use the app with HealthKit fully denied

**As me, I want the app to be fully usable if I deny HealthKit, so that privacy reasons or a botched first-launch don't lock me out.**

- All manual logging works.
- HealthKit-sourced fields on Daily Metrics (resting HR, HRV, sleep, etc.) show as "—" / blank.
- Banner in Settings: "Connect Apple Health for automatic metrics."

### S24. Re-importing same file twice in a row

**As me, I want re-importing not to create duplicates, so that I can keep my markdown file in iCloud Drive and re-import on a whim.**

- Second import shows the confirmation screen with "0 new, N updated, days replaced." and is idempotent — running it 3× in a row produces the same database state as running it once.

### S25. Plan covers only some weekdays

**As me, I want a partial plan import to leave the unmentioned days untouched, so that I can layer two markdown files into one plan.**

- Importing a file with only Mon–Wed sections updates those three days; Thu–Sun stay as they were.

### S26. Conflicting workouts: I logged a run, and Apple Watch also logged it

**As me, I want the app to recognize my Apple Watch's record of the same run as a duplicate of what I logged manually, so that history shows one session, not two.**

- When our app's logged session writes to HealthKit, it tags itself with our bundle id.
- On read, samples with our bundle id are skipped.
- For runs the user did *not* log in our app but logged on Apple Watch: those import normally and appear in history as `origin == "healthkit"`.
- Time-window deduplication beyond bundle id is not attempted in v1.

### S27. Conflicting weight entries

**As me, I want a weight I typed in the app and the same weight read back from HealthKit not to appear twice in the list.**

- Manual weight entries are written to HealthKit and locally store the resulting `HKSample.uuid`.
- On HealthKit read, samples whose `uuid` already exists in our DB are skipped.

### S28. App used on iPhone and Mac at the same time

**As me, I want a workout I just finished logging on iPhone to be visible on Mac when I open the app a minute later, without manual sync.**

- CloudKit sync runs in the background; opening the Mac app pulls the latest changes within seconds.
- If a record is being edited on both devices simultaneously: last-write-wins is acceptable for v1 (we'll only conflict on rare manual edits to the same row).

## Out of scope for V1 (deliberately)

- Watch app interactions (planned for V2).
- AI-assisted plan import (V2).
- Personal-record badges / progression suggestions.
- Sharing, social features, exporting reports.
- Editing the same session simultaneously on two devices with merge UI.

## Resolved decisions (from these stories)

- **Status pills (S6):** "in progress" requires real logged content; opening and bailing keeps the pill at "not started"; "done" requires an explicit "Finish workout" tap. No timeout-based auto-cancel.
- **HealthKit attach window (S12):** ±15 minutes around the session start, matching training type.
- **Inline exercise creation (S15):** ad-hoc strength logging can create new exercises inline (typed name → "+ Create '[name]'" row).
- **Exercise deletion (S22):** soft-delete via `isArchived` flag — preserves history, hides from pickers, restorable via a "Show archived" toggle.

The `isArchived` flag will be added to `Exercise` in `data-model.md`.
