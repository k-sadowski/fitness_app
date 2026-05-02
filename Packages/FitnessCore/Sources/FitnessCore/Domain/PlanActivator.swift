import Foundation
import SwiftData

public enum PlanActivator {
    public static func activate(_ plan: Plan, in context: ModelContext) throws {
        let allPlans = try context.fetch(FetchDescriptor<Plan>())
        for other in allPlans where other.id != plan.id {
            if other.isActive { other.isActive = false }
        }
        plan.isActive = true
        try context.save()
    }

    public static func deactivate(_ plan: Plan, in context: ModelContext) throws {
        plan.isActive = false
        try context.save()
    }
}
