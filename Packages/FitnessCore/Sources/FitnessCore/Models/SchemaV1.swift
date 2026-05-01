import Foundation
import SwiftData

public enum SchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    public static var models: [any PersistentModel.Type] {
        [
            Plan.self,
            PlanDay.self,
            PlannedWorkout.self,
            PlannedExerciseEntry.self,
            Exercise.self,
            WorkoutSession.self,
            StrengthSet.self,
            CardioSummary.self,
            WeightEntry.self,
            DailyMetrics.self,
            BodyMeasurement.self,
            UserPreferences.self,
        ]
    }
}
