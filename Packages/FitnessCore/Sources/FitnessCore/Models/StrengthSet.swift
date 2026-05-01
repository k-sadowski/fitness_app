import Foundation
import SwiftData

@Model
public final class StrengthSet {
    public var id: UUID = UUID()
    public var setNumber: Int = 1
    public var reps: Int = 0
    public var weightKg: Double?
    public var rpe: Double?
    public var completedAt: Date = Date()
    public var exercise: Exercise?
    public var session: WorkoutSession?

    public init(
        id: UUID = UUID(),
        exercise: Exercise? = nil,
        setNumber: Int,
        reps: Int,
        weightKg: Double? = nil,
        rpe: Double? = nil,
        completedAt: Date = Date(),
        session: WorkoutSession? = nil
    ) {
        self.id = id
        self.exercise = exercise
        self.setNumber = setNumber
        self.reps = reps
        self.weightKg = weightKg
        self.rpe = rpe
        self.completedAt = completedAt
        self.session = session
    }
}
