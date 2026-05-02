import Foundation
import SwiftData
import XCTest
@testable import FitnessCore

final class PlanActivatorTests: XCTestCase {
    func testActivatingASecondPlanDeactivatesTheFirst() throws {
        let container = try ModelContainerFactory.makeInMemory()
        let context = ModelContext(container)

        let a = Plan(name: "A", isActive: true)
        let b = Plan(name: "B", isActive: false)
        context.insert(a)
        context.insert(b)
        try context.save()

        try PlanActivator.activate(b, in: context)

        XCTAssertFalse(a.isActive)
        XCTAssertTrue(b.isActive)
    }

    func testActivatingTheAlreadyActivePlanIsANoop() throws {
        let container = try ModelContainerFactory.makeInMemory()
        let context = ModelContext(container)

        let a = Plan(name: "A", isActive: true)
        context.insert(a)
        try context.save()

        try PlanActivator.activate(a, in: context)

        XCTAssertTrue(a.isActive)
    }

    func testActivatingFromAllInactiveStateWorks() throws {
        let container = try ModelContainerFactory.makeInMemory()
        let context = ModelContext(container)

        let a = Plan(name: "A", isActive: false)
        let b = Plan(name: "B", isActive: false)
        context.insert(a)
        context.insert(b)
        try context.save()

        try PlanActivator.activate(a, in: context)

        XCTAssertTrue(a.isActive)
        XCTAssertFalse(b.isActive)
    }

    func testDeactivateLeavesAllPlansInactive() throws {
        let container = try ModelContainerFactory.makeInMemory()
        let context = ModelContext(container)

        let a = Plan(name: "A", isActive: true)
        let b = Plan(name: "B", isActive: false)
        context.insert(a)
        context.insert(b)
        try context.save()

        try PlanActivator.deactivate(a, in: context)

        XCTAssertFalse(a.isActive)
        XCTAssertFalse(b.isActive)
    }
}
