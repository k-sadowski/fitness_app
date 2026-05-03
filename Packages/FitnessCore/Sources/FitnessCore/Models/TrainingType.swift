import Foundation

public enum TrainingType: String, Codable, CaseIterable, Sendable, Identifiable {
    case strength
    case running
    case tennis
    case walkingPad
    case circuit
    case other

    public var id: String { rawValue }
}
