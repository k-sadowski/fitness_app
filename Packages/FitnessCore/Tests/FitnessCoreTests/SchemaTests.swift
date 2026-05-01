import Foundation
import SwiftData
import XCTest
@testable import FitnessCore

final class SchemaTests: XCTestCase {
    func testInMemoryContainerInstantiates() throws {
        _ = try ModelContainerFactory.makeInMemory()
    }

    func testSchemaContainsAllModels() {
        let modelTypes = SchemaV1.models.map { String(describing: $0) }
        XCTAssertTrue(modelTypes.contains("Plan"))
        XCTAssertTrue(modelTypes.contains("PlanDay"))
        XCTAssertTrue(modelTypes.contains("PlannedWorkout"))
        XCTAssertTrue(modelTypes.contains("PlannedExerciseEntry"))
        XCTAssertTrue(modelTypes.contains("Exercise"))
        XCTAssertTrue(modelTypes.contains("WorkoutSession"))
        XCTAssertTrue(modelTypes.contains("StrengthSet"))
        XCTAssertTrue(modelTypes.contains("CardioSummary"))
        XCTAssertTrue(modelTypes.contains("WeightEntry"))
        XCTAssertTrue(modelTypes.contains("DailyMetrics"))
        XCTAssertTrue(modelTypes.contains("BodyMeasurement"))
        XCTAssertTrue(modelTypes.contains("UserPreferences"))
    }

    func testSeederCreatesDefaultPlanAndPreferences() throws {
        let container = try ModelContainerFactory.makeInMemory()
        let context = ModelContext(container)
        try Seeder.seedIfNeeded(in: context)

        let plans = try context.fetch(FetchDescriptor<Plan>())
        XCTAssertEqual(plans.count, 1)
        XCTAssertEqual(plans.first?.name, "Default")
        XCTAssertEqual(plans.first?.isActive, true)
        XCTAssertEqual(plans.first?.days.count, 7)

        let prefs = try context.fetch(FetchDescriptor<UserPreferences>())
        XCTAssertEqual(prefs.count, 1)

        try Seeder.seedIfNeeded(in: context)
        let plansAfter = try context.fetch(FetchDescriptor<Plan>())
        XCTAssertEqual(plansAfter.count, 1, "Seeder should be idempotent")
    }
}
