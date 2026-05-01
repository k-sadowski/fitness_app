import Foundation
import SwiftData

public enum Seeder {
    public static func seedIfNeeded(in context: ModelContext) throws {
        let prefsCount = try context.fetchCount(FetchDescriptor<UserPreferences>())
        if prefsCount == 0 {
            context.insert(UserPreferences())
        }

        let planCount = try context.fetchCount(FetchDescriptor<Plan>())
        if planCount == 0 {
            let defaultPlan = Plan(name: "Default", isActive: true)
            context.insert(defaultPlan)
            for weekday in 1...7 {
                let day = PlanDay(weekday: weekday, plan: defaultPlan)
                context.insert(day)
            }
        }

        try context.save()
    }
}
