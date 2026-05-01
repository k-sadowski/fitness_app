import Foundation
import SwiftData

@Model
public final class DailyMetrics {
    public var id: UUID = UUID()
    public var date: Date = Date()
    public var restingHeartRateBpm: Int?
    public var hrvSdnnMs: Double?
    public var sleepHours: Double?
    public var sleepQuality: Int?
    public var recoveryScore: Int?
    public var steps: Int?
    public var activeEnergyKcal: Double?
    public var vo2maxMlKgMin: Double?
    public var note: String?

    public init(
        id: UUID = UUID(),
        date: Date,
        restingHeartRateBpm: Int? = nil,
        hrvSdnnMs: Double? = nil,
        sleepHours: Double? = nil,
        sleepQuality: Int? = nil,
        recoveryScore: Int? = nil,
        steps: Int? = nil,
        activeEnergyKcal: Double? = nil,
        vo2maxMlKgMin: Double? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.date = date
        self.restingHeartRateBpm = restingHeartRateBpm
        self.hrvSdnnMs = hrvSdnnMs
        self.sleepHours = sleepHours
        self.sleepQuality = sleepQuality
        self.recoveryScore = recoveryScore
        self.steps = steps
        self.activeEnergyKcal = activeEnergyKcal
        self.vo2maxMlKgMin = vo2maxMlKgMin
        self.note = note
    }
}
