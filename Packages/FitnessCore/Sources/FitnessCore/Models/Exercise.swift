import Foundation
import SwiftData

@Model
public final class Exercise {
    public var id: UUID = UUID()
    public var name: String = ""
    public var trainingType: TrainingType = TrainingType.strength
    public var descriptionText: String?
    public var muscleGroups: [String] = []
    public var isArchived: Bool = false
    public var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \PlannedExerciseEntry.exercise)
    public var plannedEntries: [PlannedExerciseEntry] = []

    @Relationship(deleteRule: .nullify, inverse: \StrengthSet.exercise)
    public var loggedSets: [StrengthSet] = []

    public init(
        id: UUID = UUID(),
        name: String,
        trainingType: TrainingType,
        descriptionText: String? = nil,
        muscleGroups: [String] = [],
        isArchived: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.trainingType = trainingType
        self.descriptionText = descriptionText
        self.muscleGroups = muscleGroups
        self.isArchived = isArchived
        self.createdAt = createdAt
    }
}
