import SwiftUI
import FitnessCore

extension TrainingType {
    var label: String {
        switch self {
        case .strength:    return "Strength"
        case .running:     return "Running"
        case .tennis:      return "Tennis"
        case .walkingPad:  return "Walking pad"
        case .circuit:     return "Circuit"
        case .other:       return "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .strength:    return "dumbbell.fill"
        case .running:     return "figure.run"
        case .tennis:      return "figure.tennis"
        case .walkingPad:  return "figure.walk.motion"
        case .circuit:     return "figure.mixed.cardio"
        case .other:       return "figure.flexibility"
        }
    }

    var supportsDuration: Bool {
        switch self {
        case .running, .walkingPad, .tennis, .circuit: return true
        case .strength, .other: return false
        }
    }

    var supportsDistance: Bool {
        self == .running || self == .walkingPad
    }

    var supportsPlannedExercises: Bool {
        self == .strength
    }
}

/// ISO 8601 weekday for the given date: 1 = Mon … 7 = Sun.
func isoWeekday(from date: Date, calendar: Calendar = .current) -> Int {
    let w = calendar.component(.weekday, from: date) // 1 = Sun … 7 = Sat
    return w == 1 ? 7 : w - 1
}

func weekdayName(_ weekday: Int) -> String {
    // ISO 8601 weekday: 1 = Mon … 7 = Sun.
    // Foundation's standaloneWeekdaySymbols is Sunday-first (index 0 = Sun).
    let symbols = Calendar(identifier: .gregorian).standaloneWeekdaySymbols
    let sundayFirstIndex = weekday == 7 ? 0 : weekday
    return symbols[sundayFirstIndex]
}

func formatKg(_ kg: Double) -> String {
    String(format: "%.1f kg", kg)
}
