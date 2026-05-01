import Foundation
import SwiftData

public enum WeightEntrySource: String, Codable, Sendable {
    case manual
    case healthkit
}

@Model
public final class WeightEntry {
    public var id: UUID = UUID()
    public var weightKg: Double = 0
    public var recordedAt: Date = Date()
    public var source: WeightEntrySource = WeightEntrySource.manual
    public var healthKitUUID: UUID?
    public var note: String?

    public init(
        id: UUID = UUID(),
        weightKg: Double,
        recordedAt: Date = Date(),
        source: WeightEntrySource = .manual,
        healthKitUUID: UUID? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.weightKg = weightKg
        self.recordedAt = recordedAt
        self.source = source
        self.healthKitUUID = healthKitUUID
        self.note = note
    }
}
