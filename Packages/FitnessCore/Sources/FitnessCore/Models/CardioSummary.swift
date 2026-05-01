import Foundation
import SwiftData

@Model
public final class CardioSummary {
    public var id: UUID = UUID()
    public var durationSeconds: Int = 0
    public var distanceKm: Double?
    public var averageSpeedKmh: Double?
    public var session: WorkoutSession?

    public init(
        id: UUID = UUID(),
        durationSeconds: Int,
        distanceKm: Double? = nil,
        averageSpeedKmh: Double? = nil,
        session: WorkoutSession? = nil
    ) {
        self.id = id
        self.durationSeconds = durationSeconds
        self.distanceKm = distanceKm
        self.averageSpeedKmh = averageSpeedKmh
        self.session = session
    }
}
