import Foundation
import SwiftData
import XCTest
@testable import FitnessCore

final class WorkoutFinishCriteriaTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainerFactory.makeInMemory()
        return ModelContext(container)
    }

    // MARK: - Strength

    func testStrengthAdHocNoSetsCannotFinish() throws {
        let context = try makeContext()
        let session = WorkoutSession(trainingType: .strength, title: "Ad hoc")
        context.insert(session)
        XCTAssertFalse(WorkoutFinishCriteria.canFinish(session: session, plannedWorkout: nil))
    }

    func testStrengthAdHocOneSetCanFinish() throws {
        let context = try makeContext()
        let exercise = Exercise(name: "Bench", trainingType: .strength)
        let session = WorkoutSession(trainingType: .strength, title: "Ad hoc")
        let set = StrengthSet(exercise: exercise, setNumber: 1, reps: 5, weightKg: 60, session: session)
        context.insert(exercise); context.insert(session); context.insert(set)
        XCTAssertTrue(WorkoutFinishCriteria.canFinish(session: session, plannedWorkout: nil))
    }

    func testStrengthPlannedWithUnloggedExerciseCannotFinish() throws {
        let context = try makeContext()
        let bench = Exercise(name: "Bench", trainingType: .strength)
        let squat = Exercise(name: "Squat", trainingType: .strength)
        let planned = PlannedWorkout(trainingType: .strength, title: "Push")
        context.insert(bench); context.insert(squat); context.insert(planned)
        context.insert(PlannedExerciseEntry(exercise: bench, targetSets: 3, targetReps: 5, plannedWorkout: planned))
        context.insert(PlannedExerciseEntry(exercise: squat, targetSets: 3, targetReps: 5, plannedWorkout: planned))

        let session = WorkoutSession(trainingType: .strength, title: "Push", sourcePlannedWorkoutId: planned.id)
        let set = StrengthSet(exercise: bench, setNumber: 1, reps: 5, weightKg: 60, session: session)
        context.insert(session); context.insert(set)

        XCTAssertFalse(WorkoutFinishCriteria.canFinish(session: session, plannedWorkout: planned))
    }

    func testStrengthPlannedAllLoggedCanFinish() throws {
        let context = try makeContext()
        let bench = Exercise(name: "Bench", trainingType: .strength)
        let squat = Exercise(name: "Squat", trainingType: .strength)
        let planned = PlannedWorkout(trainingType: .strength, title: "Push")
        context.insert(bench); context.insert(squat); context.insert(planned)
        context.insert(PlannedExerciseEntry(exercise: bench, targetSets: 3, targetReps: 5, plannedWorkout: planned))
        context.insert(PlannedExerciseEntry(exercise: squat, targetSets: 3, targetReps: 5, plannedWorkout: planned))

        let session = WorkoutSession(trainingType: .strength, title: "Push", sourcePlannedWorkoutId: planned.id)
        context.insert(session)
        context.insert(StrengthSet(exercise: bench, setNumber: 1, reps: 5, weightKg: 60, session: session))
        context.insert(StrengthSet(exercise: squat, setNumber: 1, reps: 5, weightKg: 80, session: session))

        XCTAssertTrue(WorkoutFinishCriteria.canFinish(session: session, plannedWorkout: planned))
    }

    func testStrengthPlannedSkippedCountsAsCovered() throws {
        let context = try makeContext()
        let bench = Exercise(name: "Bench", trainingType: .strength)
        let squat = Exercise(name: "Squat", trainingType: .strength)
        let planned = PlannedWorkout(trainingType: .strength, title: "Push")
        context.insert(bench); context.insert(squat); context.insert(planned)
        context.insert(PlannedExerciseEntry(exercise: bench, targetSets: 3, targetReps: 5, plannedWorkout: planned))
        context.insert(PlannedExerciseEntry(exercise: squat, targetSets: 3, targetReps: 5, plannedWorkout: planned))

        let session = WorkoutSession(
            trainingType: .strength,
            title: "Push",
            sourcePlannedWorkoutId: planned.id,
            skippedExerciseIds: [squat.id]
        )
        context.insert(session)
        context.insert(StrengthSet(exercise: bench, setNumber: 1, reps: 5, weightKg: 60, session: session))

        XCTAssertTrue(WorkoutFinishCriteria.canFinish(session: session, plannedWorkout: planned))
    }

    func testStrengthEmptyPlanFallsBackToAdHocRule() throws {
        let context = try makeContext()
        let planned = PlannedWorkout(trainingType: .strength, title: "Empty")
        context.insert(planned)
        let session = WorkoutSession(trainingType: .strength, title: "Empty", sourcePlannedWorkoutId: planned.id)
        context.insert(session)
        XCTAssertFalse(WorkoutFinishCriteria.canFinish(session: session, plannedWorkout: planned))

        let bench = Exercise(name: "Bench", trainingType: .strength)
        context.insert(bench)
        context.insert(StrengthSet(exercise: bench, setNumber: 1, reps: 5, weightKg: 60, session: session))
        XCTAssertTrue(WorkoutFinishCriteria.canFinish(session: session, plannedWorkout: planned))
    }

    // MARK: - Cardio / tennis / circuit

    func testCardioWithoutSummaryCannotFinish() throws {
        let context = try makeContext()
        let session = WorkoutSession(trainingType: .running, title: "Run")
        context.insert(session)
        XCTAssertFalse(WorkoutFinishCriteria.canFinish(session: session, plannedWorkout: nil))
    }

    func testCardioWithDurationCanFinish() throws {
        let context = try makeContext()
        let session = WorkoutSession(trainingType: .running, title: "Run")
        let cardio = CardioSummary(durationSeconds: 120, distanceKm: 0.5, session: session)
        context.insert(session); context.insert(cardio)
        XCTAssertTrue(WorkoutFinishCriteria.canFinish(session: session, plannedWorkout: nil))
    }

    func testTennisRequiresDuration() throws {
        let context = try makeContext()
        let session = WorkoutSession(trainingType: .tennis, title: "Tennis", notes: "felt good")
        context.insert(session)
        XCTAssertFalse(
            WorkoutFinishCriteria.canFinish(session: session, plannedWorkout: nil),
            "Notes alone shouldn't satisfy finish for cardio-style sessions"
        )

        let cardio = CardioSummary(durationSeconds: 1800, session: session)
        context.insert(cardio)
        XCTAssertTrue(WorkoutFinishCriteria.canFinish(session: session, plannedWorkout: nil))
    }

    func testCircuitRequiresDuration() throws {
        let context = try makeContext()
        let session = WorkoutSession(trainingType: .circuit, title: "Home circuit")
        context.insert(session)
        XCTAssertFalse(WorkoutFinishCriteria.canFinish(session: session, plannedWorkout: nil))
        let cardio = CardioSummary(durationSeconds: 600, session: session)
        context.insert(cardio)
        XCTAssertTrue(WorkoutFinishCriteria.canFinish(session: session, plannedWorkout: nil))
    }
}
