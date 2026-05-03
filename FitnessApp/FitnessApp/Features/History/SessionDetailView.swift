import SwiftUI
import SwiftData
import FitnessCore

struct SessionDetailView: View {
    @Bindable var session: WorkoutSession

    var body: some View {
        Form {
            headerSection
            switch session.trainingType {
            case .strength:
                strengthBody
            case .running, .walkingPad, .tennis, .circuit:
                cardioBody
            case .other:
                EmptyView()
            }
            sourceSection
        }
        .navigationTitle(session.title.isEmpty ? session.trainingType.label : session.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerSection: some View {
        Section {
            LabeledContent("Type") {
                Label(session.trainingType.label, systemImage: session.trainingType.systemImage)
                    .foregroundStyle(.secondary)
            }
            LabeledContent("Date") {
                Text(session.startedAt, format: .dateTime.weekday(.wide).month().day().year().hour().minute())
                    .foregroundStyle(.secondary)
            }
            if let dur = durationSeconds {
                LabeledContent("Duration", value: formatDurationHuman(dur))
            }
            if let kcal = session.totalEnergyBurnedKcal, kcal > 0 {
                LabeledContent("Active energy", value: "\(Int(kcal)) kcal")
            }
            if let notes = session.notes, !notes.isEmpty {
                Text(notes)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var durationSeconds: Int? {
        if let s = session.cardio?.durationSeconds, s > 0 { return s }
        if let end = session.endedAt {
            return Int(end.timeIntervalSince(session.startedAt))
        }
        return nil
    }

    // MARK: - Strength body

    @ViewBuilder
    private var strengthBody: some View {
        let groups = strengthGroups()
        if groups.isEmpty && session.skippedExerciseIds.isEmpty {
            Section {
                Text("No sets logged.").foregroundStyle(.secondary)
            }
        } else {
            ForEach(groups, id: \.exercise.id) { group in
                Section {
                    if group.isSkipped {
                        Text("Skipped")
                            .foregroundStyle(.secondary)
                            .italic()
                    } else if group.sets.isEmpty {
                        Text("No sets logged for this exercise.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(group.sets) { set in
                            SetRow(set: set)
                        }
                    }
                } header: {
                    HStack {
                        Text(group.exercise.name)
                        if group.isExtra {
                            Spacer()
                            Text("Extra")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private struct StrengthGroup {
        let exercise: Exercise
        let sets: [StrengthSet]
        let isSkipped: Bool
        let isExtra: Bool
    }

    private func strengthGroups() -> [StrengthGroup] {
        // Build groups: planned exercises first (in plan order), then extras.
        let plannedEntries = plannedEntriesForSession()
        let plannedById: [UUID: PlannedExerciseEntry] = Dictionary(
            uniqueKeysWithValues: plannedEntries.compactMap { entry in
                guard let id = entry.exercise?.id else { return nil }
                return (id, entry)
            }
        )

        let setsByExerciseId = Dictionary(grouping: session.strengthSets) { $0.exercise?.id ?? UUID() }
        let skipped = Set(session.skippedExerciseIds)

        var groups: [StrengthGroup] = []
        for entry in plannedEntries {
            guard let ex = entry.exercise else { continue }
            let sets = (setsByExerciseId[ex.id] ?? []).sorted { $0.setNumber < $1.setNumber }
            groups.append(StrengthGroup(exercise: ex, sets: sets, isSkipped: skipped.contains(ex.id), isExtra: false))
        }

        for ex in extraExercises() {
            let sets = (setsByExerciseId[ex.id] ?? []).sorted { $0.setNumber < $1.setNumber }
            groups.append(StrengthGroup(exercise: ex, sets: sets, isSkipped: false, isExtra: true))
        }

        // If there's no plan link at all, every set is "extra" — group by exercise.
        if plannedById.isEmpty {
            groups = []
            var seen = Set<UUID>()
            for set in session.strengthSets {
                guard let ex = set.exercise, seen.insert(ex.id).inserted else { continue }
                let sets = (setsByExerciseId[ex.id] ?? []).sorted { $0.setNumber < $1.setNumber }
                groups.append(StrengthGroup(exercise: ex, sets: sets, isSkipped: false, isExtra: false))
            }
        }
        return groups
    }

    private func plannedEntriesForSession() -> [PlannedExerciseEntry] {
        // Resolve via sourcePlannedWorkoutId. Plan edits could have removed the workout
        // but we still snapshot exercises through the StrengthSet links — that's the
        // designed-in tradeoff (Plan ≠ history). If we can find the planned workout,
        // we list its planned exercises in plan order; otherwise we fall through to
        // ad-hoc grouping.
        guard let plannedId = session.sourcePlannedWorkoutId,
              let context = session.modelContext else { return [] }
        let predicate = #Predicate<PlannedWorkout> { $0.id == plannedId }
        var descriptor = FetchDescriptor<PlannedWorkout>(predicate: predicate)
        descriptor.fetchLimit = 1
        let planned = (try? context.fetch(descriptor).first)
        return planned?.plannedExercises.sorted { $0.orderIndex < $1.orderIndex } ?? []
    }

    private func extraExercises() -> [Exercise] {
        let plannedIds = Set(plannedEntriesForSession().compactMap { $0.exercise?.id })
        var seen = Set<UUID>()
        var result: [Exercise] = []
        for set in session.strengthSets {
            guard let ex = set.exercise else { continue }
            if !plannedIds.contains(ex.id), seen.insert(ex.id).inserted {
                result.append(ex)
            }
        }
        return result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    // MARK: - Cardio body

    @ViewBuilder
    private var cardioBody: some View {
        if let cardio = session.cardio {
            Section("Totals") {
                LabeledContent("Duration", value: formatDurationHuman(cardio.durationSeconds))
                if let km = cardio.distanceKm {
                    LabeledContent("Distance", value: formatKm(km))
                }
                if let pace = cardio.averageSpeedKmh {
                    LabeledContent("Avg speed", value: String(format: "%.1f km/h", pace))
                }
                if let rpe = cardio.rpe {
                    LabeledContent("RPE", value: "\(Int(rpe))")
                }
            }
        }
    }

    // MARK: - Source

    private var sourceSection: some View {
        Section {
            if session.origin == .healthkit {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Imported from Apple Health", systemImage: "heart.fill")
                        .foregroundStyle(.pink)
                    if let bundle = session.sourceBundleId {
                        Text("Source: \(bundle)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("Edit in the source app.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Label("Logged manually", systemImage: "pencil.and.outline")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Source")
        }
    }
}

// MARK: - Set row

private struct SetRow: View {
    let set: StrengthSet

    var body: some View {
        HStack {
            Text("Set \(set.setNumber)")
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)
            Spacer()
            Text("\(set.reps) reps")
            Text("·").foregroundStyle(.tertiary)
            if let kg = set.weightKg {
                Text(formatKg(kg))
            } else {
                Text("BW").foregroundStyle(.secondary)
            }
        }
        .font(.subheadline)
    }
}

// MARK: - Preview

#Preview("Strength — planned") {
    let container = try! ModelContainerFactory.makeInMemory()
    let context = ModelContext(container)
    let bench = Exercise(name: "Bench Press", trainingType: .strength)
    let oh = Exercise(name: "Overhead Press", trainingType: .strength)
    context.insert(bench); context.insert(oh)

    let planned = PlannedWorkout(trainingType: .strength, title: "Push Day")
    context.insert(planned)
    context.insert(PlannedExerciseEntry(exercise: bench, targetSets: 4, targetReps: 6, targetWeightKg: 80, plannedWorkout: planned))
    context.insert(PlannedExerciseEntry(exercise: oh, targetSets: 3, targetReps: 8, targetWeightKg: 45, plannedWorkout: planned))

    let now = Date()
    let session = WorkoutSession(
        startedAt: now.addingTimeInterval(-3000),
        endedAt: now,
        trainingType: .strength,
        title: "Push Day",
        sourcePlannedWorkoutId: planned.id,
        skippedExerciseIds: [oh.id]
    )
    context.insert(session)
    context.insert(StrengthSet(exercise: bench, setNumber: 1, reps: 6, weightKg: 80, session: session))
    context.insert(StrengthSet(exercise: bench, setNumber: 2, reps: 6, weightKg: 82.5, session: session))

    try! context.save()
    return NavigationStack { SessionDetailView(session: session) }
        .modelContainer(container)
}

#Preview("Cardio") {
    let container = try! ModelContainerFactory.makeInMemory()
    let context = ModelContext(container)
    let now = Date()
    let session = WorkoutSession(
        startedAt: now.addingTimeInterval(-2000),
        endedAt: now,
        trainingType: .running,
        title: "Easy run"
    )
    context.insert(session)
    context.insert(CardioSummary(durationSeconds: 1800, distanceKm: 5.2, averageSpeedKmh: 10.4, session: session))
    try! context.save()
    return NavigationStack { SessionDetailView(session: session) }
        .modelContainer(container)
}
