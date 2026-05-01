import Foundation
import SwiftData

@Model
public final class PlannedWorkout {
    public var id: UUID = UUID()
    public var trainingType: TrainingType = TrainingType.strength
    public var title: String = ""
    public var notes: String?
    public var orderIndex: Int = 0
    public var plannedDurationMinutes: Int?
    public var plannedDistanceKm: Double?
    public var day: PlanDay?

    @Relationship(deleteRule: .cascade, inverse: \PlannedExerciseEntry.plannedWorkout)
    public var plannedExercises: [PlannedExerciseEntry] = []

    public init(
        id: UUID = UUID(),
        trainingType: TrainingType,
        title: String,
        notes: String? = nil,
        orderIndex: Int = 0,
        plannedDurationMinutes: Int? = nil,
        plannedDistanceKm: Double? = nil,
        day: PlanDay? = nil
    ) {
        self.id = id
        self.trainingType = trainingType
        self.title = title
        self.notes = notes
        self.orderIndex = orderIndex
        self.plannedDurationMinutes = plannedDurationMinutes
        self.plannedDistanceKm = plannedDistanceKm
        self.day = day
    }
}
