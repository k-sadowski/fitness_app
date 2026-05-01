import Foundation
import SwiftData

@Model
public final class Plan {
    public var id: UUID = UUID()
    public var name: String = ""
    public var notes: String?
    public var isActive: Bool = false
    public var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \PlanDay.plan)
    public var days: [PlanDay] = []

    public init(
        id: UUID = UUID(),
        name: String,
        notes: String? = nil,
        isActive: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.isActive = isActive
        self.createdAt = createdAt
    }
}
