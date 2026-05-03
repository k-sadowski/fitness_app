import SwiftUI
import SwiftData
import FitnessCore

struct HistoryListView: View {
    @Query(
        filter: #Predicate<WorkoutSession> { $0.endedAt != nil },
        sort: \WorkoutSession.startedAt,
        order: .reverse
    )
    private var sessions: [WorkoutSession]

    @Query(filter: #Predicate<Plan> { $0.isActive }) private var activePlans: [Plan]

    private var weeks: [HistoryWeek] {
        HistoryGrouping.groupByWeek(sessions)
    }

    private var sessionsById: [UUID: WorkoutSession] {
        Dictionary(uniqueKeysWithValues: sessions.map { ($0.id, $0) })
    }

    private var plannedPerWeek: Int {
        activePlans.first?.days.flatMap(\.plannedWorkouts).count ?? 0
    }

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "No sessions yet",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Logged workouts will show up here.")
                    )
                } else {
                    list
                }
            }
            .navigationTitle("History")
            .navigationDestination(for: WorkoutSessionRef.self) { ref in
                if let session = sessionsById[ref.id] {
                    SessionDetailView(session: session)
                }
            }
        }
    }

    private var list: some View {
        List {
            ForEach(weeks, id: \.weekStart) { week in
                Section {
                    ForEach(week.sessionIds, id: \.self) { id in
                        if let session = sessionsById[id] {
                            NavigationLink(value: WorkoutSessionRef(id: session.id)) {
                                SessionRow(session: session)
                            }
                        }
                    }
                } header: {
                    WeekSummaryHeader(
                        weekStart: week.weekStart,
                        summary: HistoryGrouping.summary(
                            for: week.sessionIds.compactMap { sessionsById[$0] },
                            plannedWorkoutCount: plannedPerWeek
                        )
                    )
                }
            }
        }
    }
}

// Stable nav-destination key (SwiftData @Model isn't a great Hashable nav value).
struct WorkoutSessionRef: Hashable {
    let id: UUID
}

// MARK: - Week summary header

private struct WeekSummaryHeader: View {
    let weekStart: Date
    let summary: WeekSummary

    private var weekRange: String {
        let calendar = HistoryGrouping.isoMondayCalendar()
        let end = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: weekStart)) – \(formatter.string(from: end))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(weekRange)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(summary.workoutsDone)/\(summary.workoutsPlanned) done")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                if summary.strengthSessions > 0 {
                    StatChip(icon: "dumbbell.fill", text: "\(summary.strengthSessions)")
                }
                if summary.runDistanceKm > 0 {
                    StatChip(icon: "figure.run", text: formatKm(summary.runDistanceKm))
                }
                if summary.walkingPadDistanceKm > 0 {
                    StatChip(icon: "figure.walk.motion", text: formatKm(summary.walkingPadDistanceKm))
                }
                if summary.tennisSessions > 0 {
                    StatChip(icon: "figure.tennis", text: "\(summary.tennisSessions)")
                }
                if summary.circuitSessions > 0 {
                    StatChip(icon: "figure.mixed.cardio", text: "\(summary.circuitSessions)")
                }
                if summary.totalActiveEnergyKcal > 0 {
                    StatChip(icon: "flame.fill", text: "\(Int(summary.totalActiveEnergyKcal)) kcal")
                }
            }
            .font(.caption)
        }
        .textCase(nil)
        .padding(.vertical, 4)
    }
}

private struct StatChip: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .foregroundStyle(.secondary)
    }
}

// MARK: - Session row

private struct SessionRow: View {
    let session: WorkoutSession

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.trainingType.systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(session.title.isEmpty ? session.trainingType.label : session.title)
                        .font(.body.weight(.medium))
                    if session.origin == .healthkit {
                        HKBadge()
                    }
                }
                HStack(spacing: 8) {
                    Text(session.startedAt, format: .dateTime.weekday(.abbreviated).hour().minute())
                    if let metric = primaryMetric {
                        Text("·").foregroundStyle(.tertiary)
                        Text(metric)
                    }
                    if let dur = formattedDuration {
                        Text("·").foregroundStyle(.tertiary)
                        Text(dur)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }

    private var primaryMetric: String? {
        switch session.trainingType {
        case .strength:
            return topSetSummary(for: session)
        case .running, .walkingPad:
            if let km = session.cardio?.distanceKm ?? session.totalDistanceKm, km > 0 {
                return "\(formatKm(km))"
            }
            return nil
        case .tennis, .circuit, .other:
            return nil
        }
    }

    private var formattedDuration: String? {
        let seconds: Int? = {
            if let s = session.cardio?.durationSeconds, s > 0 { return s }
            if let end = session.endedAt {
                return Int(end.timeIntervalSince(session.startedAt))
            }
            return nil
        }()
        guard let seconds, seconds > 0 else { return nil }
        return formatDurationHuman(seconds)
    }
}

struct HKBadge: View {
    var body: some View {
        Text("HK")
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(.pink.opacity(0.18), in: Capsule())
            .foregroundStyle(.pink)
            .accessibilityLabel("Imported from Apple Health")
    }
}

// MARK: - Helpers

func topSetSummary(for session: WorkoutSession) -> String? {
    guard let top = session.strengthSets
        .max(by: { lhs, rhs in
            (lhs.weightKg ?? 0) < (rhs.weightKg ?? 0)
                || ((lhs.weightKg ?? 0) == (rhs.weightKg ?? 0) && lhs.reps < rhs.reps)
        })
    else { return nil }
    if let kg = top.weightKg {
        return "\(top.reps) × \(formatKg(kg))"
    }
    return "\(top.reps) reps"
}

func formatKm(_ km: Double) -> String {
    String(format: "%.2f km", km)
}

func formatDurationHuman(_ seconds: Int) -> String {
    let h = seconds / 3600
    let m = (seconds % 3600) / 60
    if h > 0 {
        return "\(h)h \(m)m"
    }
    return "\(m)m"
}

// MARK: - Preview

#Preview("History — populated") {
    let container = try! ModelContainerFactory.makeInMemory()
    let context = ModelContext(container)
    let plan = Plan(name: "Variant A", isActive: true)
    context.insert(plan)
    for w in 1...7 {
        let day = PlanDay(weekday: w, plan: plan)
        context.insert(day)
        if w % 2 == 1 {
            context.insert(PlannedWorkout(trainingType: .strength, title: "S", day: day))
        }
    }

    let now = Date()
    let strength = WorkoutSession(startedAt: now, endedAt: now.addingTimeInterval(3300), trainingType: .strength, title: "Push", totalEnergyBurnedKcal: 280)
    let bench = Exercise(name: "Bench", trainingType: .strength)
    context.insert(bench)
    context.insert(strength)
    context.insert(StrengthSet(exercise: bench, setNumber: 1, reps: 6, weightKg: 80, session: strength))
    context.insert(StrengthSet(exercise: bench, setNumber: 2, reps: 6, weightKg: 82.5, session: strength))

    let run = WorkoutSession(startedAt: now.addingTimeInterval(-86400), endedAt: now.addingTimeInterval(-86400 + 1800), trainingType: .running, title: "Easy run", totalEnergyBurnedKcal: 350)
    context.insert(run)
    context.insert(CardioSummary(durationSeconds: 1800, distanceKm: 5.2, session: run))

    let lastWeek = WorkoutSession(startedAt: now.addingTimeInterval(-86400 * 9), endedAt: now.addingTimeInterval(-86400 * 9 + 4500), trainingType: .tennis, title: "Tennis")
    context.insert(lastWeek)
    context.insert(CardioSummary(durationSeconds: 4500, session: lastWeek))

    try! context.save()
    return HistoryListView()
        .modelContainer(container)
}

#Preview("History — empty") {
    HistoryListView()
        .modelContainer(try! ModelContainerFactory.makeInMemory())
}
