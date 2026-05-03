import Foundation

/// One ISO week's worth of logged sessions, ordered newest-first within the week.
public struct HistoryWeek: Sendable, Equatable {
    /// Monday 00:00 of this ISO week, in the supplied calendar.
    public let weekStart: Date
    public let sessionIds: [UUID]
}

/// Aggregate per-week metrics for the History summary card (S18).
public struct WeekSummary: Sendable, Equatable {
    public let workoutsDone: Int
    public let workoutsPlanned: Int
    public let strengthSessions: Int
    public let tennisSessions: Int
    public let circuitSessions: Int
    public let runDistanceKm: Double
    public let walkingPadDistanceKm: Double
    public let totalActiveEnergyKcal: Double

    public init(
        workoutsDone: Int,
        workoutsPlanned: Int,
        strengthSessions: Int,
        tennisSessions: Int,
        circuitSessions: Int,
        runDistanceKm: Double,
        walkingPadDistanceKm: Double,
        totalActiveEnergyKcal: Double
    ) {
        self.workoutsDone = workoutsDone
        self.workoutsPlanned = workoutsPlanned
        self.strengthSessions = strengthSessions
        self.tennisSessions = tennisSessions
        self.circuitSessions = circuitSessions
        self.runDistanceKm = runDistanceKm
        self.walkingPadDistanceKm = walkingPadDistanceKm
        self.totalActiveEnergyKcal = totalActiveEnergyKcal
    }
}

public enum HistoryGrouping {
    /// Groups sessions into ISO weeks (Monday-start), newest week first.
    /// Each week's `sessionIds` are sorted by `startedAt` newest-first.
    public static func groupByWeek(
        _ sessions: [WorkoutSession],
        calendar: Calendar = isoMondayCalendar()
    ) -> [HistoryWeek] {
        guard !sessions.isEmpty else { return [] }
        var buckets: [Date: [WorkoutSession]] = [:]
        for session in sessions {
            let start = weekStart(for: session.startedAt, calendar: calendar)
            buckets[start, default: []].append(session)
        }
        return buckets
            .map { (start, items) -> HistoryWeek in
                let sortedIds = items
                    .sorted { $0.startedAt > $1.startedAt }
                    .map(\.id)
                return HistoryWeek(weekStart: start, sessionIds: sortedIds)
            }
            .sorted { $0.weekStart > $1.weekStart }
    }

    /// Computes the summary card for one week's sessions.
    /// `plannedWorkoutCount` is the number of `PlannedWorkout`s on the active plan
    /// (weekly total across 7 days). Pass 0 if no plan is active.
    public static func summary(
        for sessions: [WorkoutSession],
        plannedWorkoutCount: Int
    ) -> WeekSummary {
        var done = 0
        var strength = 0
        var tennis = 0
        var circuit = 0
        var runKm: Double = 0
        var walkKm: Double = 0
        var energy: Double = 0
        for s in sessions {
            if s.endedAt != nil { done += 1 }
            switch s.trainingType {
            case .strength: strength += 1
            case .tennis:   tennis += 1
            case .circuit:  circuit += 1
            case .running:
                runKm += s.cardio?.distanceKm ?? s.totalDistanceKm ?? 0
            case .walkingPad:
                walkKm += s.cardio?.distanceKm ?? s.totalDistanceKm ?? 0
            case .other:
                break
            }
            energy += s.totalEnergyBurnedKcal ?? 0
        }
        return WeekSummary(
            workoutsDone: done,
            workoutsPlanned: plannedWorkoutCount,
            strengthSessions: strength,
            tennisSessions: tennis,
            circuitSessions: circuit,
            runDistanceKm: runKm,
            walkingPadDistanceKm: walkKm,
            totalActiveEnergyKcal: energy
        )
    }

    /// A calendar configured to use ISO 8601 weeks (week starts Monday, week 1
    /// contains the first Thursday) in the user's current time zone.
    public static func isoMondayCalendar() -> Calendar {
        var c = Calendar(identifier: .iso8601)
        c.timeZone = .current
        c.firstWeekday = 2 // Monday
        c.minimumDaysInFirstWeek = 4
        return c
    }

    /// Monday 00:00 of the ISO week containing `date`.
    public static func weekStart(for date: Date, calendar: Calendar = isoMondayCalendar()) -> Date {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: comps) ?? calendar.startOfDay(for: date)
    }
}
