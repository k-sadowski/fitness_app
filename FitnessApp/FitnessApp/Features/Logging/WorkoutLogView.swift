import SwiftUI
import SwiftData
import FitnessCore

struct WorkoutLogView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let plannedWorkout: PlannedWorkout?
    let trainingType: TrainingType
    let initialTitle: String

    @State private var session: WorkoutSession?
    @State private var showingDiscardConfirm = false

    init(plannedWorkout: PlannedWorkout) {
        self.plannedWorkout = plannedWorkout
        self.trainingType = plannedWorkout.trainingType
        self.initialTitle = plannedWorkout.title.isEmpty ? plannedWorkout.trainingType.label : plannedWorkout.title
    }

    init(adHocType: TrainingType) {
        self.plannedWorkout = nil
        self.trainingType = adHocType
        self.initialTitle = adHocType.label
    }

    var body: some View {
        NavigationStack {
            Group {
                if let session {
                    body(for: session)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(initialTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") {
                        if let s = session, sessionHasContent(s) {
                            showingDiscardConfirm = true
                        } else {
                            discard()
                        }
                    }
                    .tint(.red)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Finish", action: finish)
                        .disabled(!canFinish)
                        .bold()
                }
            }
            .confirmationDialog(
                "Discard this workout?",
                isPresented: $showingDiscardConfirm,
                titleVisibility: .visible
            ) {
                Button("Discard", role: .destructive, action: discard)
                Button("Keep editing", role: .cancel) {}
            } message: {
                Text("Any logged sets, timer, and notes will be deleted.")
            }
        }
        .interactiveDismissDisabled()
        .onAppear(perform: openOrCreateSession)
    }

    @ViewBuilder
    private func body(for session: WorkoutSession) -> some View {
        switch trainingType {
        case .strength:
            StrengthLogBody(session: session, plannedWorkout: plannedWorkout)
        case .running, .walkingPad:
            CardioLogBody(session: session, plannedWorkout: plannedWorkout, kind: .distance)
        case .tennis:
            CardioLogBody(session: session, plannedWorkout: plannedWorkout, kind: .tennis)
        case .circuit:
            CardioLogBody(session: session, plannedWorkout: plannedWorkout, kind: .circuit)
        case .other:
            ContentUnavailableView(
                "Not supported",
                systemImage: "questionmark.square.dashed",
                description: Text("Workouts of type 'Other' can't be logged in the app yet.")
            )
        }
    }

    private var canFinish: Bool {
        guard let session else { return false }
        return WorkoutFinishCriteria.canFinish(session: session, plannedWorkout: plannedWorkout)
    }

    private func sessionHasContent(_ s: WorkoutSession) -> Bool {
        if !s.strengthSets.isEmpty { return true }
        if let cardio = s.cardio, cardio.durationSeconds > 0 { return true }
        if let n = s.notes, !n.isEmpty { return true }
        if !s.skippedExerciseIds.isEmpty { return true }
        return false
    }

    private func openOrCreateSession() {
        guard session == nil else { return }
        if let planned = plannedWorkout {
            let plannedId = planned.id
            let dayStart = Calendar.current.startOfDay(for: Date())
            guard let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) else { return }
            let predicate = #Predicate<WorkoutSession> { s in
                s.sourcePlannedWorkoutId == plannedId
                    && s.endedAt == nil
                    && s.startedAt >= dayStart
                    && s.startedAt < dayEnd
            }
            var descriptor = FetchDescriptor<WorkoutSession>(predicate: predicate)
            descriptor.fetchLimit = 1
            if let existing = try? context.fetch(descriptor).first {
                session = existing
                return
            }
            let new = WorkoutSession(
                trainingType: planned.trainingType,
                title: planned.title.isEmpty ? planned.trainingType.label : planned.title,
                sourcePlannedWorkoutId: planned.id
            )
            context.insert(new)
            try? context.save()
            session = new
        } else {
            let new = WorkoutSession(trainingType: trainingType, title: trainingType.label)
            context.insert(new)
            try? context.save()
            session = new
        }
    }

    private func finish() {
        guard let session else { return }
        session.endedAt = Date()
        try? context.save()
        dismiss()
    }

    private func discard() {
        if let session {
            context.delete(session)
            try? context.save()
        }
        dismiss()
    }
}

// MARK: - Previews

#Preview("Strength — planned") {
    let container = try! ModelContainerFactory.makeInMemory()
    let context = ModelContext(container)
    let workout = PlannedWorkout(trainingType: .strength, title: "Push Day")
    context.insert(workout)
    let bench = Exercise(name: "Bench Press", trainingType: .strength)
    let oh = Exercise(name: "Overhead Press", trainingType: .strength)
    context.insert(bench); context.insert(oh)
    context.insert(PlannedExerciseEntry(exercise: bench, targetSets: 4, targetReps: 6, targetWeightKg: 80, orderIndex: 0, plannedWorkout: workout))
    context.insert(PlannedExerciseEntry(exercise: oh, targetSets: 3, targetReps: 8, targetWeightKg: 45, orderIndex: 1, plannedWorkout: workout))
    try! context.save()
    return WorkoutLogView(plannedWorkout: workout)
        .modelContainer(container)
}

#Preview("Cardio — planned") {
    let container = try! ModelContainerFactory.makeInMemory()
    let context = ModelContext(container)
    let workout = PlannedWorkout(trainingType: .running, title: "Easy Z2", plannedDurationMinutes: 30, plannedDistanceKm: 5.0)
    context.insert(workout)
    try! context.save()
    return WorkoutLogView(plannedWorkout: workout)
        .modelContainer(container)
}

#Preview("Tennis — ad hoc") {
    let container = try! ModelContainerFactory.makeInMemory()
    return WorkoutLogView(adHocType: .tennis)
        .modelContainer(container)
}
