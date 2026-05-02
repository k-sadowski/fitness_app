import SwiftUI
import SwiftData
import FitnessCore

struct PlanEditView: View {
    @Environment(\.modelContext) private var context
    @Bindable var plan: Plan

    @State private var workoutToEdit: PlannedWorkout?
    @State private var dayAwaitingType: PlanDay?

    var body: some View {
        Form {
            Section("Plan") {
                TextField("Name", text: $plan.name)
                TextField("Notes (optional)", text: notesBinding, axis: .vertical)
                    .lineLimit(2...4)
                Toggle("Active", isOn: activeBinding)
            }

            ForEach(sortedDays) { day in
                Section(header: Text(weekdayName(day.weekday))) {
                    let workouts = day.plannedWorkouts.sorted { $0.orderIndex < $1.orderIndex }
                    if workouts.isEmpty {
                        Text("Rest day")
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                    ForEach(workouts) { workout in
                        Button {
                            workoutToEdit = workout
                        } label: {
                            PlannedWorkoutRow(workout: workout)
                        }
                        .foregroundStyle(.primary)
                    }
                    .onDelete { offsets in
                        deleteWorkouts(at: offsets, in: workouts)
                    }
                    .onMove { source, destination in
                        moveWorkouts(in: workouts, from: source, to: destination)
                    }
                    Button {
                        dayAwaitingType = day
                    } label: {
                        Label("Add workout", systemImage: "plus.circle.fill")
                    }
                }
            }
        }
        .navigationTitle(plan.name.isEmpty ? "Untitled plan" : plan.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { EditButton() }
        }
        .sheet(item: $workoutToEdit) { workout in
            PlannedWorkoutEditView(workout: workout)
        }
        .confirmationDialog(
            "Workout type",
            isPresented: typeDialogBinding,
            presenting: dayAwaitingType
        ) { day in
            ForEach(TrainingType.allCases, id: \.self) { type in
                Button(type.label) {
                    let workout = createWorkout(in: day, type: type)
                    dayAwaitingType = nil
                    workoutToEdit = workout
                }
            }
            Button("Cancel", role: .cancel) { dayAwaitingType = nil }
        } message: { day in
            Text("Add a workout to \(weekdayName(day.weekday)).")
        }
    }

    private var typeDialogBinding: Binding<Bool> {
        Binding(get: { dayAwaitingType != nil }, set: { if !$0 { dayAwaitingType = nil } })
    }

    private var sortedDays: [PlanDay] {
        plan.days.sorted { $0.weekday < $1.weekday }
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { plan.notes ?? "" },
            set: { plan.notes = $0.isEmpty ? nil : $0 }
        )
    }

    private var activeBinding: Binding<Bool> {
        Binding(
            get: { plan.isActive },
            set: { newValue in
                do {
                    if newValue {
                        try PlanActivator.activate(plan, in: context)
                    } else {
                        try PlanActivator.deactivate(plan, in: context)
                    }
                } catch {
                    // SwiftData failure here would mean disk/CloudKit issues; surface later when error UI lands.
                }
            }
        )
    }

    private func createWorkout(in day: PlanDay, type: TrainingType) -> PlannedWorkout {
        let nextIndex = (day.plannedWorkouts.map(\.orderIndex).max() ?? -1) + 1
        let workout = PlannedWorkout(
            trainingType: type,
            title: "",
            orderIndex: nextIndex,
            day: day
        )
        context.insert(workout)
        try? context.save()
        return workout
    }

    private func deleteWorkouts(at offsets: IndexSet, in sorted: [PlannedWorkout]) {
        for index in offsets {
            context.delete(sorted[index])
        }
        try? context.save()
    }

    private func moveWorkouts(in sorted: [PlannedWorkout], from source: IndexSet, to destination: Int) {
        var working = sorted
        working.move(fromOffsets: source, toOffset: destination)
        for (index, workout) in working.enumerated() {
            workout.orderIndex = index
        }
        try? context.save()
    }
}

private struct PlannedWorkoutRow: View {
    let workout: PlannedWorkout

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: workout.trainingType.systemImage)
                .frame(width: 24)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(workout.title.isEmpty ? "Untitled" : workout.title)
                    .font(.body)
                if let summary = summary {
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
    }

    private var summary: String? {
        switch workout.trainingType {
        case .strength:
            let count = workout.plannedExercises.count
            if count == 0 { return "No exercises yet" }
            return "\(count) exercise\(count == 1 ? "" : "s")"
        case .running, .walkingPad:
            var parts: [String] = []
            if let km = workout.plannedDistanceKm { parts.append("\(String(format: "%g", km)) km") }
            if let min = workout.plannedDurationMinutes { parts.append("\(min) min") }
            return parts.isEmpty ? nil : parts.joined(separator: " · ")
        case .tennis, .circuit:
            if let min = workout.plannedDurationMinutes { return "\(min) min" }
            return nil
        case .other:
            return nil
        }
    }
}

#Preview("Plan editor") {
    let container = try! ModelContainerFactory.makeInMemory()
    let context = ModelContext(container)
    let plan = Plan(name: "Variant A", isActive: true)
    context.insert(plan)
    for weekday in 1...7 {
        let day = PlanDay(weekday: weekday, plan: plan)
        context.insert(day)
        if weekday == 1 {
            let workout = PlannedWorkout(trainingType: .strength, title: "Push Day", orderIndex: 0, day: day)
            context.insert(workout)
        }
        if weekday == 3 {
            let workout = PlannedWorkout(trainingType: .tennis, title: "Tennis", orderIndex: 0, plannedDurationMinutes: 90, day: day)
            context.insert(workout)
        }
    }
    try! context.save()
    return NavigationStack { PlanEditView(plan: plan) }
        .modelContainer(container)
}
