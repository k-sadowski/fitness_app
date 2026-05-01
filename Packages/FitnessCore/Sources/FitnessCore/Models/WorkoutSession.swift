import Foundation
import SwiftData

public enum WorkoutOrigin: String, Codable, Sendable {
    case logged
    case healthkit
}

@Model
public final class WorkoutSession {
    public var id: UUID = UUID()
    public var startedAt: Date = Date()
    public var endedAt: Date?
    public var trainingType: TrainingType = TrainingType.strength
    public var title: String = ""
    public var notes: String?
    public var sourcePlannedWorkoutId: UUID?
    public var origin: WorkoutOrigin = WorkoutOrigin.logged
    public var healthKitUUID: UUID?
    public var sourceBundleId: String?
    public var rawActivityTypeRawValue: Int?
    public var totalEnergyBurnedKcal: Double?
    public var totalDistanceKm: Double?
    public var skippedExerciseIds: [UUID] = []

    @Relationship(deleteRule: .cascade, inverse: \StrengthSet.session)
    public var strengthSets: [StrengthSet] = []

    @Relationship(deleteRule: .cascade, inverse: \CardioSummary.session)
    public var cardio: CardioSummary?

    public init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        trainingType: TrainingType,
        title: String,
        notes: String? = nil,
        sourcePlannedWorkoutId: UUID? = nil,
        origin: WorkoutOrigin = .logged,
        healthKitUUID: UUID? = nil,
        sourceBundleId: String? = nil,
        rawActivityTypeRawValue: Int? = nil,
        totalEnergyBurnedKcal: Double? = nil,
        totalDistanceKm: Double? = nil,
        skippedExerciseIds: [UUID] = []
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.trainingType = trainingType
        self.title = title
        self.notes = notes
        self.sourcePlannedWorkoutId = sourcePlannedWorkoutId
        self.origin = origin
        self.healthKitUUID = healthKitUUID
        self.sourceBundleId = sourceBundleId
        self.rawActivityTypeRawValue = rawActivityTypeRawValue
        self.totalEnergyBurnedKcal = totalEnergyBurnedKcal
        self.totalDistanceKm = totalDistanceKm
        self.skippedExerciseIds = skippedExerciseIds
    }
}
