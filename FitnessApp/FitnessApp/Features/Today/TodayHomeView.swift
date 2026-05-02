import SwiftUI
import SwiftData
import FitnessCore

struct TodayHomeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.appTabSelection) private var tabSelection
    @Query private var plans: [Plan]
    @Query(sort: \WorkoutSession.startedAt) private var sessions: [WorkoutSession]
    @Query(sort: \WeightEntry.recordedAt, order: .reverse) private var weightEntries: [WeightEntry]

    @State private var showingPlanSwitcher = false
    @State private var showingWeightLog = false
    @State private var workoutToShow: PlannedWorkout?

    private var today: Date { Date() }
    private var activePlan: Plan? { plans.first(where: \.isActive) }
    private var todayDay: PlanDay? {
        guard let plan = activePlan else { return nil }
        let weekday = isoWeekday(from: today)
        return plan.days.first(where: { $0.weekday == weekday })
    }
    private var todayWorkouts: [PlannedWorkout] {
        (todayDay?.plannedWorkouts ?? []).sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Today")
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        // Default title is fine; principal slot reserved for future plan chip on iPad.
                        EmptyView()
                    }
                }
                .sheet(isPresented: $showingPlanSwitcher) {
                    PlanSwitcherSheet()
                }
                .sheet(isPresented: $showingWeightLog) {
                    WeightLogSheet(suggestedWeight: weightEntries.first?.weightKg)
                }
                .navigationDestination(item: $workoutToShow) { workout in
                    PlannedWorkoutDetailView(
                        workout: workout,
                        status: WorkoutStatusCalculator.status(for: workout, on: today, in: sessions)
                    )
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if activePlan == nil {
            noPlanState
        } else {
            List {
                Section {
                    headerRow
                }

                Section("Today") {
                    if todayWorkouts.isEmpty {
                        Text("Rest day.")
                            .foregroundStyle(.secondary)
                            .italic()
                    } else {
                        ForEach(todayWorkouts) { workout in
                            Button {
                                workoutToShow = workout
                            } label: {
                                PlannedWorkoutCard(
                                    workout: workout,
                                    status: WorkoutStatusCalculator.status(for: workout, on: today, in: sessions)
                                )
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }

                Section {
                    Button {
                        // Wired in a later slice when WorkoutLogView lands.
                    } label: {
                        Label("Log workout", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(true)
                    Text("Ad-hoc logging coming soon.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                Section("Quick stats") {
                    Button {
                        showingWeightLog = true
                    } label: {
                        WeightTile(latest: weightEntries.first, previous: weightEntries.dropFirst().first)
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
    }

    private var headerRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(today, format: .dateTime.weekday(.wide).month().day())
                    .font(.headline)
            }
            Spacer()
            if let plan = activePlan {
                Button {
                    showingPlanSwitcher = true
                } label: {
                    HStack(spacing: 4) {
                        Text(plan.name.isEmpty ? "Untitled plan" : plan.name)
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.tint.opacity(0.15), in: Capsule())
                    .foregroundStyle(.tint)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Switch plan")
            }
        }
    }

    private var noPlanState: some View {
        ContentUnavailableView {
            Label("No plan yet", systemImage: "calendar.badge.plus")
        } description: {
            Text("Create a plan to schedule your week.")
        } actions: {
            Button("Open Plans") {
                tabSelection?.wrappedValue = .settings
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Card

private struct PlannedWorkoutCard: View {
    let workout: PlannedWorkout
    let status: PlannedWorkoutStatus

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: workout.trainingType.systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.title.isEmpty ? "Untitled" : workout.title)
                    .font(.body.weight(.semibold))
                if let summary = summary {
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                StatusPill(status: status)
                    .padding(.top, 2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private var summary: String? {
        switch workout.trainingType {
        case .strength:
            let count = workout.plannedExercises.count
            if count == 0 { return "No exercises" }
            return "\(count) exercise\(count == 1 ? "" : "s")"
        case .running, .walkingPad:
            var parts: [String] = []
            if let km = workout.plannedDistanceKm { parts.append("\(String(format: "%g", km)) km") }
            if let min = workout.plannedDurationMinutes { parts.append("\(min) min") }
            return parts.isEmpty ? nil : parts.joined(separator: " · ")
        case .tennis, .circuit:
            if let min = workout.plannedDurationMinutes { return "\(min) min" }
            return nil
        case .other:
            return nil
        }
    }
}

// MARK: - Quick-stat tile

private struct WeightTile: View {
    let latest: WeightEntry?
    let previous: WeightEntry?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Weight")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let latest {
                    Text(String(format: "%.1f kg", latest.weightKg))
                        .font(.title3.weight(.semibold))
                    if let previous {
                        let delta = latest.weightKg - previous.weightKg
                        Text(deltaString(delta))
                            .font(.caption)
                            .foregroundStyle(deltaColor(delta))
                    } else {
                        Text("First entry")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("No entries")
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "scalemass")
                .foregroundStyle(.tint)
        }
        .padding(.vertical, 4)
    }

    private func deltaString(_ delta: Double) -> String {
        if abs(delta) < 0.05 { return "± 0.0 kg" }
        let sign = delta > 0 ? "+" : "−"
        return "\(sign)\(String(format: "%.1f", abs(delta))) kg"
    }

    private func deltaColor(_ delta: Double) -> Color {
        if abs(delta) < 0.05 { return .secondary }
        return delta < 0 ? .green : .orange
    }
}

// MARK: - Previews

#Preview("Today — with plan and workouts") {
    let container = try! ModelContainerFactory.makeInMemory()
    let context = ModelContext(container)
    let plan = Plan(name: "Variant A", isActive: true)
    context.insert(plan)
    for weekday in 1...7 {
        let day = PlanDay(weekday: weekday, plan: plan)
        context.insert(day)
    }
    let todayWeekday = isoWeekday(from: Date())
    let todayDay = plan.days.first(where: { $0.weekday == todayWeekday })!
    let push = PlannedWorkout(trainingType: .strength, title: "Push Day", orderIndex: 0, day: todayDay)
    context.insert(push)
    let bench = Exercise(name: "Bench Press", trainingType: .strength)
    context.insert(bench)
    context.insert(PlannedExerciseEntry(exercise: bench, targetSets: 4, targetReps: 6, targetWeightKg: 80, plannedWorkout: push))
    let walk = PlannedWorkout(trainingType: .walkingPad, title: "Walking pad", orderIndex: 1, plannedDurationMinutes: 150, plannedDistanceKm: 6, day: todayDay)
    context.insert(walk)
    context.insert(WeightEntry(weightKg: 88.6, recordedAt: Date()))
    context.insert(WeightEntry(weightKg: 88.9, recordedAt: Date().addingTimeInterval(-86400)))
    try! context.save()
    return TodayHomeView()
        .modelContainer(container)
}

#Preview("Today — rest day") {
    let container = try! ModelContainerFactory.makeInMemory()
    let context = ModelContext(container)
    let plan = Plan(name: "Variant A", isActive: true)
    context.insert(plan)
    for weekday in 1...7 {
        context.insert(PlanDay(weekday: weekday, plan: plan))
    }
    try! context.save()
    return TodayHomeView()
        .modelContainer(container)
}

#Preview("Today — no plan") {
    let container = try! ModelContainerFactory.makeInMemory()
    return TodayHomeView()
        .modelContainer(container)
}
