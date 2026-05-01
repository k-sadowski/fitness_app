import Foundation
import SwiftData

@Model
public final class UserPreferences {
    public var id: UUID = UUID()
    public var weightReminderEnabled: Bool = true
    public var weightReminderTime: Date = UserPreferences.defaultMorningReminderTime(hour: 8, minute: 0)
    public var dailyMetricsReminderEnabled: Bool = true
    public var dailyMetricsReminderTime: Date = UserPreferences.defaultMorningReminderTime(hour: 8, minute: 15)
    public var weightUnit: String = "kg"
    public var distanceUnit: String = "km"
    public var hasCompletedOnboarding: Bool = false

    public init(
        id: UUID = UUID(),
        weightReminderEnabled: Bool = true,
        weightReminderTime: Date = UserPreferences.defaultMorningReminderTime(hour: 8, minute: 0),
        dailyMetricsReminderEnabled: Bool = true,
        dailyMetricsReminderTime: Date = UserPreferences.defaultMorningReminderTime(hour: 8, minute: 15),
        weightUnit: String = "kg",
        distanceUnit: String = "km",
        hasCompletedOnboarding: Bool = false
    ) {
        self.id = id
        self.weightReminderEnabled = weightReminderEnabled
        self.weightReminderTime = weightReminderTime
        self.dailyMetricsReminderEnabled = dailyMetricsReminderEnabled
        self.dailyMetricsReminderTime = dailyMetricsReminderTime
        self.weightUnit = weightUnit
        self.distanceUnit = distanceUnit
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }

    public static func defaultMorningReminderTime(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar(identifier: .gregorian).date(from: components) ?? Date()
    }
}
