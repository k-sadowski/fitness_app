import Foundation

public enum PlannedWorkoutStatus: String, Sendable {
    case notStarted
    case inProgress
    case done
}

public enum WorkoutStatusCalculator {
    /// Computes the S6 status pill for a planned workout on a given calendar date.
    /// `sessions` is the candidate pool — typically all `WorkoutSession`s, filtered here by date and link.
    public static func status(
        for plannedWorkout: PlannedWorkout,
        on date: Date,
        in sessions: [WorkoutSession],
        calendar: Calendar = .current
    ) -> PlannedWorkoutStatus {
        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return .notStarted
        }
        let plannedID = plannedWorkout.id
        let candidates = sessions.filter { session in
            session.sourcePlannedWorkoutId == plannedID
                && session.startedAt >= dayStart
                && session.startedAt < dayEnd
        }
        guard let session = candidates.first else { return .notStarted }
        if session.endedAt != nil { return .done }
        if hasContent(session) { return .inProgress }
        return .notStarted
    }

    private static func hasContent(_ session: WorkoutSession) -> Bool {
        if !session.strengthSets.isEmpty { return true }
        if session.cardio != nil { return true }
        if let notes = session.notes, !notes.isEmpty { return true }
        return false
    }
}
