import Foundation
import SwiftData
import XCTest
@testable import FitnessCore

final class HistoryGroupingTests: XCTestCase {
    private let calendar = HistoryGrouping.isoMondayCalendar()

    private func at(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day
        c.hour = hour; c.minute = 0
        return calendar.date(from: c)!
    }

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainerFactory.makeInMemory()
        return ModelContext(container)
    }

    // MARK: - Grouping

    func testGroupingEmpty() {
        XCTAssertEqual(HistoryGrouping.groupByWeek([]).count, 0)
    }

    func testGroupingPutsSameWeekTogether() throws {
        let context = try makeContext()
        // 2026-05-04 = Monday, 2026-05-08 = Friday
        let s1 = WorkoutSession(startedAt: at(2026, 5, 4, hour: 9), trainingType: .strength, title: "A")
        let s2 = WorkoutSession(startedAt: at(2026, 5, 8, hour: 18), trainingType: .running, title: "B")
        context.insert(s1); context.insert(s2)

        let weeks = HistoryGrouping.groupByWeek([s1, s2], calendar: calendar)
        XCTAssertEqual(weeks.count, 1)
        // Newest-first within the week.
        XCTAssertEqual(weeks[0].sessionIds, [s2.id, s1.id])
    }

    func testGroupingOrdersWeeksNewestFirst() throws {
        let context = try makeContext()
        let thisWeek = WorkoutSession(startedAt: at(2026, 5, 6), trainingType: .strength, title: "Now")
        let lastWeek = WorkoutSession(startedAt: at(2026, 4, 29), trainingType: .strength, title: "Prev")
        context.insert(thisWeek); context.insert(lastWeek)

        let weeks = HistoryGrouping.groupByWeek([lastWeek, thisWeek], calendar: calendar)
        XCTAssertEqual(weeks.count, 2)
        XCTAssertGreaterThan(weeks[0].weekStart, weeks[1].weekStart)
    }

    func testWeekStartIsMonday() {
        // 2026-05-08 is a Friday → its ISO week starts on Mon 2026-05-04.
        let friday = at(2026, 5, 8)
        let start = HistoryGrouping.weekStart(for: friday, calendar: calendar)
        let weekday = calendar.component(.weekday, from: start)
        XCTAssertEqual(weekday, 2, "Mondays are weekday=2 in a Sunday-first calendar")
    }

    // MARK: - Summary

    func testSummaryCountsAndDistances() throws {
        let context = try makeContext()
        let strength = WorkoutSession(
            startedAt: at(2026, 5, 4),
            endedAt: at(2026, 5, 4, hour: 13),
            trainingType: .strength,
            title: "Push",
            totalEnergyBurnedKcal: 250
        )
        let run = WorkoutSession(
            startedAt: at(2026, 5, 5),
            endedAt: at(2026, 5, 5, hour: 13),
            trainingType: .running,
            title: "Run",
            totalEnergyBurnedKcal: 400
        )
        let runCardio = CardioSummary(durationSeconds: 1800, distanceKm: 5.0, session: run)
        let walk = WorkoutSession(
            startedAt: at(2026, 5, 6),
            endedAt: at(2026, 5, 6, hour: 13),
            trainingType: .walkingPad,
            title: "Walk"
        )
        let walkCardio = CardioSummary(durationSeconds: 3600, distanceKm: 4.0, session: walk)
        let tennis = WorkoutSession(
            startedAt: at(2026, 5, 7),
            endedAt: at(2026, 5, 7, hour: 13),
            trainingType: .tennis,
            title: "Tennis"
        )
        let unfinished = WorkoutSession(
            startedAt: at(2026, 5, 7, hour: 14),
            trainingType: .circuit,
            title: "Circuit (in progress)"
        )
        for s in [strength, run, walk, tennis, unfinished] { context.insert(s) }
        context.insert(runCardio); context.insert(walkCardio)

        let summary = HistoryGrouping.summary(
            for: [strength, run, walk, tennis, unfinished],
            plannedWorkoutCount: 6
        )
        XCTAssertEqual(summary.workoutsDone, 4)
        XCTAssertEqual(summary.workoutsPlanned, 6)
        XCTAssertEqual(summary.strengthSessions, 1)
        XCTAssertEqual(summary.tennisSessions, 1)
        XCTAssertEqual(summary.circuitSessions, 1) // unfinished still counted by type
        XCTAssertEqual(summary.runDistanceKm, 5.0, accuracy: 0.001)
        XCTAssertEqual(summary.walkingPadDistanceKm, 4.0, accuracy: 0.001)
        XCTAssertEqual(summary.totalActiveEnergyKcal, 650, accuracy: 0.001)
    }

    func testSummaryFallsBackToTotalDistanceWhenCardioMissing() throws {
        let context = try makeContext()
        let imported = WorkoutSession(
            startedAt: at(2026, 5, 4),
            endedAt: at(2026, 5, 4, hour: 13),
            trainingType: .running,
            title: "Imported run",
            origin: .healthkit,
            totalDistanceKm: 7.5
        )
        context.insert(imported)

        let summary = HistoryGrouping.summary(for: [imported], plannedWorkoutCount: 0)
        XCTAssertEqual(summary.runDistanceKm, 7.5, accuracy: 0.001)
    }

    func testSummaryEmpty() {
        let summary = HistoryGrouping.summary(for: [], plannedWorkoutCount: 4)
        XCTAssertEqual(summary.workoutsDone, 0)
        XCTAssertEqual(summary.workoutsPlanned, 4)
        XCTAssertEqual(summary.runDistanceKm, 0)
    }
}
