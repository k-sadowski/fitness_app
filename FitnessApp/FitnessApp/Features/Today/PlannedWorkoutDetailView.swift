import SwiftUI
import SwiftData
import FitnessCore

struct PlannedWorkoutDetailView: View {
    @Bindable var workout: PlannedWorkout
    let status: PlannedWorkoutStatus

    @State private var showingEditSheet = false
    @State private var showingLogger = false

    var body: some View {
        Form {
            Section("Workout") {
                LabeledContent("Title", value: workout.title.isEmpty ? "Untitled" : workout.title)
                LabeledContent("Type") {
                    Label(workout.trainingType.label, systemImage: workout.trainingType.systemImage)
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Status") { StatusPill(status: status) }
                if let notes = workout.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            if workout.trainingType.supportsPlannedExercises {
                Section("Planned exercises") {
                    let entries = workout.plannedExercises.sorted { $0.orderIndex < $1.orderIndex }
                    if entries.isEmpty {
                        Text("No exercises in this workout yet.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(entries) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.exercise?.name ?? "(unknown)")
                            Text(summary(for: entry))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if workout.trainingType.supportsDuration || workout.trainingType.supportsDistance {
                Section("Targets") {
                    if let min = workout.plannedDurationMinutes {
                        LabeledContent("Duration", value: "\(min) min")
                    }
                    if let km = workout.plannedDistanceKm {
                        LabeledContent("Distance", value: "\(String(format: "%g", km)) km")
                    }
                    if workout.plannedDurationMinutes == nil && workout.plannedDistanceKm == nil {
                        Text("No targets set.")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if status != .done && workout.trainingType != .other {
                Section {
                    Button {
                        showingLogger = true
                    } label: {
                        Label(status == .inProgress ? "Resume workout" : "Start workout",
                              systemImage: status == .inProgress ? "arrow.clockwise" : "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            if status == .done {
                Section {
                    Label("Logged. View in History.", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
            }

            Section {
                Button {
                    showingEditSheet = true
                } label: {
                    Label("Edit plan", systemImage: "pencil")
                }
            }
        }
        .navigationTitle(workout.title.isEmpty ? "Workout" : workout.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            PlannedWorkoutEditView(workout: workout)
        }
        .fullScreenCover(isPresented: $showingLogger) {
            WorkoutLogView(plannedWorkout: workout)
        }
    }

    private func summary(for entry: PlannedExerciseEntry) -> String {
        let core = "\(entry.targetSets) × \(entry.targetReps)"
        if let kg = entry.targetWeightKg {
            return "\(core) @ \(String(format: "%.1f", kg)) kg"
        }
        return core
    }
}

struct StatusPill: View {
    let status: PlannedWorkoutStatus

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(background, in: Capsule())
            .foregroundStyle(foreground)
    }

    private var label: String {
        switch status {
        case .notStarted: return "Not started"
        case .inProgress: return "In progress"
        case .done:       return "Done"
        }
    }

    private var background: some ShapeStyle {
        switch status {
        case .notStarted: return AnyShapeStyle(.gray.opacity(0.2))
        case .inProgress: return AnyShapeStyle(.orange.opacity(0.25))
        case .done:       return AnyShapeStyle(.green.opacity(0.25))
        }
    }

    private var foreground: some ShapeStyle {
        switch status {
        case .notStarted: return AnyShapeStyle(Color.secondary)
        case .inProgress: return AnyShapeStyle(Color.orange)
        case .done:       return AnyShapeStyle(Color.green)
        }
    }
}

#Preview("Strength, not started") {
    let container = try! ModelContainerFactory.makeInMemory()
    let context = ModelContext(container)
    let workout = PlannedWorkout(trainingType: .strength, title: "Push Day")
    context.insert(workout)
    let bench = Exercise(name: "Bench Press", trainingType: .strength)
    context.insert(bench)
    context.insert(PlannedExerciseEntry(exercise: bench, targetSets: 4, targetReps: 6, targetWeightKg: 80, plannedWorkout: workout))
    try! context.save()
    return NavigationStack {
        PlannedWorkoutDetailView(workout: workout, status: .notStarted)
    }
    .modelContainer(container)
}

#Preview("Cardio, in progress") {
    let container = try! ModelContainerFactory.makeInMemory()
    let context = ModelContext(container)
    let workout = PlannedWorkout(trainingType: .running, title: "Easy Z2", plannedDurationMinutes: 30, plannedDistanceKm: 5.0)
    context.insert(workout)
    try! context.save()
    return NavigationStack {
        PlannedWorkoutDetailView(workout: workout, status: .inProgress)
    }
    .modelContainer(container)
}
