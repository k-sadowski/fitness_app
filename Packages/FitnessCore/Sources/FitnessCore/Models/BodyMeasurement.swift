import Foundation
import SwiftData

@Model
public final class BodyMeasurement {
    public var id: UUID = UUID()
    public var recordedAt: Date = Date()
    public var weightKg: Double?
    public var waistCm: Double?
    public var abdomenCm: Double?
    public var chestCm: Double?
    public var hipsCm: Double?
    public var thighCm: Double?
    public var armCm: Double?
    public var note: String?

    public init(
        id: UUID = UUID(),
        recordedAt: Date = Date(),
        weightKg: Double? = nil,
        waistCm: Double? = nil,
        abdomenCm: Double? = nil,
        chestCm: Double? = nil,
        hipsCm: Double? = nil,
        thighCm: Double? = nil,
        armCm: Double? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.recordedAt = recordedAt
        self.weightKg = weightKg
        self.waistCm = waistCm
        self.abdomenCm = abdomenCm
        self.chestCm = chestCm
        self.hipsCm = hipsCm
        self.thighCm = thighCm
        self.armCm = armCm
        self.note = note
    }
}
