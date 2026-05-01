import Foundation
import SwiftData

@Model
public final class PlannedExerciseEntry {
    public var id: UUID = UUID()
    public var targetSets: Int = 0
    public var targetReps: Int = 0
    public var targetWeightKg: Double?
    public var orderIndex: Int = 0
    public var exercise: Exercise?
    public var plannedWorkout: PlannedWorkout?

    public init(
        id: UUID = UUID(),
        exercise: Exercise? = nil,
        targetSets: Int,
        targetReps: Int,
        targetWeightKg: Double? = nil,
        orderIndex: Int = 0,
        plannedWorkout: PlannedWorkout? = nil
    ) {
        self.id = id
        self.exercise = exercise
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeightKg = targetWeightKg
        self.orderIndex = orderIndex
        self.plannedWorkout = plannedWorkout
    }
}
