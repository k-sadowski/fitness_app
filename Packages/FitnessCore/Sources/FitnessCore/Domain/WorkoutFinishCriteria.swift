import Foundation

public enum WorkoutFinishCriteria {
    /// Whether a `WorkoutSession` is eligible for "Finish" per S6 / S11–S14.
    ///
    /// - Strength against a plan: every planned exercise has at least one logged set
    ///   or is explicitly skipped.
    /// - Strength ad-hoc (or planned with no exercises): at least one logged set.
    /// - Cardio / tennis / circuit: a `CardioSummary` exists with `durationSeconds > 0`.
    public static func canFinish(
        session: WorkoutSession,
        plannedWorkout: PlannedWorkout?
    ) -> Bool {
        switch session.trainingType {
        case .strength:
            return canFinishStrength(session: session, plannedWorkout: plannedWorkout)
        case .running, .walkingPad, .tennis, .circuit:
            return (session.cardio?.durationSeconds ?? 0) > 0
        case .other:
            return false
        }
    }

    private static func canFinishStrength(
        session: WorkoutSession,
        plannedWorkout: PlannedWorkout?
    ) -> Bool {
        let plannedEntries = plannedWorkout?.plannedExercises ?? []
        if plannedEntries.isEmpty {
            return !session.strengthSets.isEmpty
        }
        let loggedExerciseIds = Set(session.strengthSets.compactMap { $0.exercise?.id })
        let skipped = Set(session.skippedExerciseIds)
        for entry in plannedEntries {
            guard let exId = entry.exercise?.id else { continue }
            if !loggedExerciseIds.contains(exId) && !skipped.contains(exId) {
                return false
            }
        }
        return true
    }
}
