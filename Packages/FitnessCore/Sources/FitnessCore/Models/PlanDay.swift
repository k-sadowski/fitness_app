import Foundation
import SwiftData

@Model
public final class PlanDay {
    public var id: UUID = UUID()
    public var weekday: Int = 1
    public var plan: Plan?

    @Relationship(deleteRule: .cascade, inverse: \PlannedWorkout.day)
    public var plannedWorkouts: [PlannedWorkout] = []

    public init(
        id: UUID = UUID(),
        weekday: Int,
        plan: Plan? = nil
    ) {
        self.id = id
        self.weekday = weekday
        self.plan = plan
    }
}
