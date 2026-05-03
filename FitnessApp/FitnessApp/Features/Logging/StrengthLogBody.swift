import SwiftUI
import SwiftData
import FitnessCore

struct StrengthLogBody: View {
    @Environment(\.modelContext) private var context
    @Bindable var session: WorkoutSession
    let plannedWorkout: PlannedWorkout?

    @State private var showingPicker = false

    private var plannedEntries: [PlannedExerciseEntry] {
        (plannedWorkout?.plannedExercises ?? []).sorted { $0.orderIndex < $1.orderIndex }
    }

    private var plannedExerciseIds: Set<UUID> {
        Set(plannedEntries.compactMap { $0.exercise?.id })
    }

    private var extraExercises: [Exercise] {
        var seen = Set<UUID>()
        var result: [Exercise] = []
        for set in session.strengthSets {
            guard let ex = set.exercise else { continue }
            if !plannedExerciseIds.contains(ex.id), seen.insert(ex.id).inserted {
                result.append(ex)
            }
        }
        return result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        List {
            ForEach(plannedEntries) { entry in
                if let exercise = entry.exercise {
                    PlannedExerciseSection(
                        session: session,
                        exercise: exercise,
                        plannedEntry: entry
                    )
                }
            }

            if !extraExercises.isEmpty {
                Section("Extra") {
                    ForEach(extraExercises) { exercise in
                        ExtraExerciseRows(session: session, exercise: exercise)
                    }
                }
            }

            Section {
                Button {
                    showingPicker = true
                } label: {
                    Label("Add exercise", systemImage: "plus.circle.fill")
                }
            }

            if plannedEntries.isEmpty && extraExercises.isEmpty {
                Section {
                    Text("Pick an exercise to start logging.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingPicker) {
            ExercisePickerSheet(trainingType: .strength) { exercise in
                addPlaceholderSet(for: exercise)
            }
        }
    }

    private func addPlaceholderSet(for exercise: Exercise) {
        // Pick a sensible default; the user edits before logging.
        let nextNumber = (session.strengthSets
            .filter { $0.exercise?.id == exercise.id }
            .map(\.setNumber)
            .max() ?? 0) + 1
        let set = StrengthSet(
            exercise: exercise,
            setNumber: nextNumber,
            reps: 0,
            weightKg: nil,
            session: session
        )
        context.insert(set)
        try? context.save()
    }
}

// MARK: - Planned exercise section

private struct PlannedExerciseSection: View {
    @Environment(\.modelContext) private var context
    @Bindable var session: WorkoutSession
    let exercise: Exercise
    let plannedEntry: PlannedExerciseEntry

    private var loggedSets: [StrengthSet] {
        session.strengthSets
            .filter { $0.exercise?.id == exercise.id }
            .sorted { $0.setNumber < $1.setNumber }
    }

    private var isSkipped: Bool {
        session.skippedExerciseIds.contains(exercise.id)
    }

    private var targetSummary: String {
        let core = "\(plannedEntry.targetSets) × \(plannedEntry.targetReps)"
        if let kg = plannedEntry.targetWeightKg {
            return "\(core) @ \(formatKg(kg))"
        }
        return core
    }

    var body: some View {
        Section {
            if isSkipped {
                Text("Skipped")
                    .foregroundStyle(.secondary)
                    .italic()
                Button("Unskip") { toggleSkip() }
            } else {
                ForEach(loggedSets) { set in
                    LoggedSetRow(set: set)
                }
                .onDelete(perform: deleteSets)
                AddSetRow(
                    nextSetNumber: (loggedSets.last?.setNumber ?? 0) + 1,
                    defaultReps: plannedEntry.targetReps,
                    defaultWeightKg: plannedEntry.targetWeightKg,
                    onLog: logSet
                )
            }
        } header: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                    Text("Plan: \(targetSummary)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
                Spacer()
                Menu {
                    Button(isSkipped ? "Unskip exercise" : "Skip exercise") { toggleSkip() }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func toggleSkip() {
        if isSkipped {
            session.skippedExerciseIds.removeAll { $0 == exercise.id }
        } else {
            session.skippedExerciseIds.append(exercise.id)
        }
        try? context.save()
    }

    private func logSet(reps: Int, weightKg: Double?) {
        let nextNumber = (loggedSets.last?.setNumber ?? 0) + 1
        let set = StrengthSet(
            exercise: exercise,
            setNumber: nextNumber,
            reps: reps,
            weightKg: weightKg,
            session: session
        )
        context.insert(set)
        try? context.save()
    }

    private func deleteSets(at offsets: IndexSet) {
        let sets = loggedSets
        for offset in offsets {
            context.delete(sets[offset])
        }
        try? context.save()
    }
}

// MARK: - Extra (ad-hoc) exercise rows

struct ExtraExerciseRows: View {
    @Environment(\.modelContext) private var context
    @Bindable var session: WorkoutSession
    let exercise: Exercise

    private var loggedSets: [StrengthSet] {
        session.strengthSets
            .filter { $0.exercise?.id == exercise.id }
            .sorted { $0.setNumber < $1.setNumber }
    }

    var body: some View {
        DisclosureGroup {
            ForEach(loggedSets) { set in
                LoggedSetRow(set: set)
            }
            .onDelete(perform: deleteSets)
            AddSetRow(
                nextSetNumber: (loggedSets.last?.setNumber ?? 0) + 1,
                defaultReps: loggedSets.last?.reps ?? 8,
                defaultWeightKg: loggedSets.last?.weightKg,
                onLog: logSet
            )
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                Text("\(loggedSets.count) set\(loggedSets.count == 1 ? "" : "s") logged")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func logSet(reps: Int, weightKg: Double?) {
        let nextNumber = (loggedSets.last?.setNumber ?? 0) + 1
        let set = StrengthSet(
            exercise: exercise,
            setNumber: nextNumber,
            reps: reps,
            weightKg: weightKg,
            session: session
        )
        context.insert(set)
        try? context.save()
    }

    private func deleteSets(at offsets: IndexSet) {
        let sets = loggedSets
        for offset in offsets {
            context.delete(sets[offset])
        }
        try? context.save()
    }
}

// MARK: - Set rows

private struct LoggedSetRow: View {
    @Bindable var set: StrengthSet

    var body: some View {
        HStack {
            Text("Set \(set.setNumber)")
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)
            Spacer()
            Text("\(set.reps) reps")
            if let kg = set.weightKg {
                Text("·")
                    .foregroundStyle(.tertiary)
                Text(formatKg(kg))
            } else {
                Text("·")
                    .foregroundStyle(.tertiary)
                Text("BW")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.subheadline)
    }
}

private struct AddSetRow: View {
    let nextSetNumber: Int
    let defaultReps: Int
    let defaultWeightKg: Double?
    let onLog: (Int, Double?) -> Void

    @State private var repsText: String = ""
    @State private var weightText: String = ""
    @FocusState private var focused: Field?

    private enum Field: Hashable { case reps, weight }

    var body: some View {
        HStack(spacing: 8) {
            Text("Set \(nextSetNumber)")
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)
            TextField("reps", text: $repsText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .focused($focused, equals: .reps)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
            TextField("kg", text: $weightText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .focused($focused, equals: .weight)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
            Button("Log", action: log)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(parsedReps == nil)
        }
        .font(.subheadline)
        .onAppear {
            if repsText.isEmpty { repsText = String(defaultReps) }
            if weightText.isEmpty, let kg = defaultWeightKg {
                weightText = formatKgPlain(kg)
            }
        }
    }

    private var parsedReps: Int? {
        let cleaned = repsText.filter(\.isNumber)
        guard let value = Int(cleaned), value > 0 else { return nil }
        return value
    }

    private var parsedWeight: Double? {
        let cleaned = weightText.replacingOccurrences(of: ",", with: ".")
        return Double(cleaned)
    }

    private func log() {
        guard let reps = parsedReps else { return }
        onLog(reps, parsedWeight)
        focused = .reps
        // Don't reset reps text — typical pattern is repeat the same reps for the next set.
    }
}

// MARK: - Formatting

private func formatKgPlain(_ kg: Double) -> String {
    String(format: "%g", kg)
}
