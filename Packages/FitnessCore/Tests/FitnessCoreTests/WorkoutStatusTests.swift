import Foundation
import SwiftData
import XCTest
@testable import FitnessCore

final class WorkoutStatusTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainerFactory.makeInMemory()
        return ModelContext(container)
    }

    private func makePlanned(in context: ModelContext, type: TrainingType = .strength) -> PlannedWorkout {
        let plan = Plan(name: "Test", isActive: true)
        let day = PlanDay(weekday: 1, plan: plan)
        let workout = PlannedWorkout(trainingType: type, title: "W", day: day)
        context.insert(plan); context.insert(day); context.insert(workout)
        return workout
    }

    func testNoSessionMeansNotStarted() throws {
        let context = try makeContext()
        let planned = makePlanned(in: context)
        let status = WorkoutStatusCalculator.status(for: planned, on: Date(), in: [])
        XCTAssertEqual(status, .notStarted)
    }

    func testSessionWithNoContentIsNotStarted() throws {
        let context = try makeContext()
        let planned = makePlanned(in: context)
        let session = WorkoutSession(
            startedAt: Date(),
            trainingType: .strength,
            title: "W",
            sourcePlannedWorkoutId: planned.id
        )
        context.insert(session)
        let status = WorkoutStatusCalculator.status(for: planned, on: Date(), in: [session])
        XCTAssertEqual(status, .notStarted)
    }

    func testSessionWithStrengthSetIsInProgress() throws {
        let context = try makeContext()
        let planned = makePlanned(in: context)
        let session = WorkoutSession(
            startedAt: Date(),
            trainingType: .strength,
            title: "W",
            sourcePlannedWorkoutId: planned.id
        )
        let set = StrengthSet(setNumber: 1, reps: 5, weightKg: 60, session: session)
        context.insert(session); context.insert(set)
        let status = WorkoutStatusCalculator.status(for: planned, on: Date(), in: [session])
        XCTAssertEqual(status, .inProgress)
    }

    func testSessionWithNotesIsInProgress() throws {
        let context = try makeContext()
        let planned = makePlanned(in: context, type: .tennis)
        let session = WorkoutSession(
            startedAt: Date(),
            trainingType: .tennis,
            title: "W",
            notes: "felt good",
            sourcePlannedWorkoutId: planned.id
        )
        context.insert(session)
        let status = WorkoutStatusCalculator.status(for: planned, on: Date(), in: [session])
        XCTAssertEqual(status, .inProgress)
    }

    func testSessionWithEndedAtIsDone() throws {
        let context = try makeContext()
        let planned = makePlanned(in: context)
        let session = WorkoutSession(
            startedAt: Date().addingTimeInterval(-3600),
            endedAt: Date(),
            trainingType: .strength,
            title: "W",
            sourcePlannedWorkoutId: planned.id
        )
        context.insert(session)
        let status = WorkoutStatusCalculator.status(for: planned, on: Date(), in: [session])
        XCTAssertEqual(status, .done)
    }

    func testSessionForDifferentPlannedWorkoutIsIgnored() throws {
        let context = try makeContext()
        let planned = makePlanned(in: context)
        let other = makePlanned(in: context)
        let session = WorkoutSession(
            startedAt: Date(),
            trainingType: .strength,
            title: "W",
            sourcePlannedWorkoutId: other.id
        )
        let set = StrengthSet(setNumber: 1, reps: 5, session: session)
        context.insert(session); context.insert(set)
        let status = WorkoutStatusCalculator.status(for: planned, on: Date(), in: [session])
        XCTAssertEqual(status, .notStarted)
    }

    func testSessionFromYesterdayIsIgnored() throws {
        let context = try makeContext()
        let planned = makePlanned(in: context)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let session = WorkoutSession(
            startedAt: yesterday,
            endedAt: yesterday.addingTimeInterval(3600),
            trainingType: .strength,
            title: "W",
            sourcePlannedWorkoutId: planned.id
        )
        context.insert(session)
        let status = WorkoutStatusCalculator.status(for: planned, on: Date(), in: [session])
        XCTAssertEqual(status, .notStarted)
    }
}
