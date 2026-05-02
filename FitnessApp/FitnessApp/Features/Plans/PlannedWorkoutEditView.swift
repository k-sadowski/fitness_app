import SwiftUI
import SwiftData
import FitnessCore

struct PlannedWorkoutEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var workout: PlannedWorkout

    @State private var showingExercisePicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $workout.title)
                    Picker("Type", selection: $workout.trainingType) {
                        ForEach(TrainingType.allCases, id: \.self) { type in
                            Label(type.label, systemImage: type.systemImage).tag(type)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: notesBinding, axis: .vertical)
                        .lineLimit(2...6)
                }

                if workout.trainingType.supportsDuration {
                    Section("Planned duration") {
                        IntField(label: "Minutes", value: $workout.plannedDurationMinutes, placeholder: "e.g. 30")
                    }
                }

                if workout.trainingType.supportsDistance {
                    Section("Planned distance") {
                        DoubleField(label: "Kilometres", value: $workout.plannedDistanceKm, placeholder: "e.g. 5.0")
                    }
                }

                if workout.trainingType.supportsPlannedExercises {
                    Section("Planned exercises") {
                        let entries = workout.plannedExercises.sorted { $0.orderIndex < $1.orderIndex }
                        if entries.isEmpty {
                            Text("No exercises yet — tap + below to add one.")
                                .foregroundStyle(.secondary)
                        }
                        ForEach(entries) { entry in
                            PlannedExerciseRow(entry: entry)
                        }
                        .onDelete { offsets in
                            deleteEntries(at: offsets, in: entries)
                        }
                        .onMove { source, destination in
                            moveEntries(in: entries, from: source, to: destination)
                        }
                        Button {
                            showingExercisePicker = true
                        } label: {
                            Label("Add exercise", systemImage: "plus.circle.fill")
                        }
                    }
                }
            }
            .navigationTitle("Edit workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                if workout.trainingType.supportsPlannedExercises && !workout.plannedExercises.isEmpty {
                    ToolbarItem(placement: .navigation) { EditButton() }
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerSheet(trainingType: .strength) { exercise in
                    addEntry(for: exercise)
                }
            }
        }
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { workout.notes ?? "" },
            set: { workout.notes = $0.isEmpty ? nil : $0 }
        )
    }

    private func addEntry(for exercise: Exercise) {
        let nextIndex = (workout.plannedExercises.map(\.orderIndex).max() ?? -1) + 1
        let entry = PlannedExerciseEntry(
            exercise: exercise,
            targetSets: 3,
            targetReps: 8,
            targetWeightKg: nil,
            orderIndex: nextIndex,
            plannedWorkout: workout
        )
        context.insert(entry)
        try? context.save()
    }

    private func deleteEntries(at offsets: IndexSet, in sorted: [PlannedExerciseEntry]) {
        for index in offsets {
            context.delete(sorted[index])
        }
        try? context.save()
    }

    private func moveEntries(in sorted: [PlannedExerciseEntry], from source: IndexSet, to destination: Int) {
        var working = sorted
        working.move(fromOffsets: source, toOffset: destination)
        for (index, entry) in working.enumerated() {
            entry.orderIndex = index
        }
        try? context.save()
    }
}

private struct PlannedExerciseRow: View {
    @Bindable var entry: PlannedExerciseEntry

    var body: some View {
        DisclosureGroup {
            Stepper(value: setsBinding, in: 1...10) {
                LabeledContent("Sets", value: "\(entry.targetSets)")
            }
            Stepper(value: repsBinding, in: 1...50) {
                LabeledContent("Reps", value: "\(entry.targetReps)")
            }
            DoubleField(label: "Weight (kg)", value: $entry.targetWeightKg, placeholder: "Optional")
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.exercise?.name ?? "(unknown exercise)")
                    .font(.body)
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var summary: String {
        let core = "\(entry.targetSets) × \(entry.targetReps)"
        if let kg = entry.targetWeightKg {
            return "\(core) @ \(String(format: "%.1f", kg)) kg"
        }
        return core
    }

    private var setsBinding: Binding<Int> {
        Binding(get: { max(1, entry.targetSets) }, set: { entry.targetSets = $0 })
    }
    private var repsBinding: Binding<Int> {
        Binding(get: { max(1, entry.targetReps) }, set: { entry.targetReps = $0 })
    }
}

// MARK: - Number field helpers

struct IntField: View {
    let label: String
    @Binding var value: Int?
    let placeholder: String

    @State private var text: String = ""

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField(placeholder, text: $text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
                .onAppear {
                    text = value.map(String.init) ?? ""
                }
                .onChange(of: text) { _, newValue in
                    let cleaned = newValue.filter(\.isNumber)
                    if cleaned != newValue { text = cleaned; return }
                    value = Int(cleaned)
                }
        }
    }
}

struct DoubleField: View {
    let label: String
    @Binding var value: Double?
    let placeholder: String

    @State private var text: String = ""

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField(placeholder, text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
                .onAppear {
                    text = value.map { String(format: "%g", $0) } ?? ""
                }
                .onChange(of: text) { _, newValue in
                    let cleaned = newValue.replacingOccurrences(of: ",", with: ".")
                    value = Double(cleaned)
                }
        }
    }
}

#Preview("Strength workout") {
    let container = try! ModelContainerFactory.makeInMemory()
    let context = ModelContext(container)
    let workout = PlannedWorkout(trainingType: .strength, title: "Push Day")
    context.insert(workout)
    let squat = Exercise(name: "Barbell Back Squat", trainingType: .strength)
    context.insert(squat)
    context.insert(PlannedExerciseEntry(exercise: squat, targetSets: 4, targetReps: 6, targetWeightKg: 80, orderIndex: 0, plannedWorkout: workout))
    try! context.save()
    return PlannedWorkoutEditView(workout: workout)
        .modelContainer(container)
}

#Preview("Cardio workout") {
    let container = try! ModelContainerFactory.makeInMemory()
    let context = ModelContext(container)
    let workout = PlannedWorkout(trainingType: .running, title: "Easy Z2", plannedDurationMinutes: 30, plannedDistanceKm: 5.0)
    context.insert(workout)
    try! context.save()
    return PlannedWorkoutEditView(workout: workout)
        .modelContainer(container)
}
