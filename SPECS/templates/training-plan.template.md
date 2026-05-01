# Plan Metadata

```yaml
name: "My Training Plan"
units:
  weight: kg
  distance: km
notes: ""
```

# Exercises

## Barbell Back Squat

```yaml
type: strength
muscles: [quads, glutes, lower_back]
description: |
  Brace, sit between the hips, drive through midfoot.
```

## Bench Press

```yaml
type: strength
muscles: [chest, triceps, front_delts]
description: ""
```

## Easy Run

```yaml
type: running
muscles: []
description: "Zone 2 conversational pace."
```

## Walking Pad Session

```yaml
type: walkingPad
muscles: []
description: "Incline walk during work."
```

## Tennis Practice

```yaml
type: tennis
muscles: []
description: "Drills + match play."
```

# Weekly Schedule

## Monday

### Push Day

```yaml
type: strength
notes: ""
exercises:
  - name: "Bench Press"
    sets: 4
    reps: 6
    weight: 80
```

## Tuesday

### Easy Run

```yaml
type: running
duration_minutes: 30
distance_km: 5
notes: "Zone 2."
```

## Wednesday

### Pull Day

```yaml
type: strength
notes: ""
exercises: []
```

## Thursday

### Tennis

```yaml
type: tennis
duration_minutes: 90
notes: "Match play."
```

## Friday

### Leg Day

```yaml
type: strength
notes: ""
exercises:
  - name: "Barbell Back Squat"
    sets: 5
    reps: 5
    weight: 100
```

## Saturday

### Long Walk

```yaml
type: walkingPad
duration_minutes: 60
distance_km: 6
notes: ""
```

## Sunday

# Rest day — no workouts under Sunday means rest.
