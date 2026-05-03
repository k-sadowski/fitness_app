import SwiftUI
import SwiftData
import Combine
import FitnessCore

enum CardioLogKind {
    case distance      // running, walking pad — distance + duration form
    case tennis        // duration + notes + RPE
    case circuit       // duration + notes + RPE + planned exercises reference
}

struct CardioLogBody: View {
    @Environment(\.modelContext) private var context
    @Bindable var session: WorkoutSession
    let plannedWorkout: PlannedWorkout?
    let kind: CardioLogKind

    @State private var timerStartedAt: Date?
    @State private var accumulatedSeconds: Int = 0
    @State private var tickToken: Int = 0   // forces re-render every second while running

    @State private var distanceText: String = ""
    @State private var rpe: Double = 5
    @State private var rpeEdited: Bool = false

    private var elapsedSeconds: Int {
        if let started = timerStartedAt {
            return accumulatedSeconds + Int(Date().timeIntervalSince(started))
        }
        return accumulatedSeconds
    }

    private var isRunning: Bool { timerStartedAt != nil }

    var body: some View {
        List {
            timerSection

            if kind == .distance {
                distanceSection
            }

            notesSection

            if kind == .tennis || kind == .circuit {
                rpeSection
            }

            if kind == .circuit {
                circuitReferenceSection
            }

            if kind == .distance, let planned = plannedWorkout {
                plannedTargetsSection(planned: planned)
            }
        }
        .onAppear(perform: hydrateFromSession)
        // Keep the view re-rendering once a second while the timer ticks.
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if isRunning { tickToken &+= 1 }
        }
    }

    // MARK: - Sections

    private var timerSection: some View {
        Section {
            VStack(spacing: 12) {
                Text(formatHMS(elapsedSeconds))
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .accessibilityIdentifier("workout-timer")
                HStack(spacing: 12) {
                    Button(action: toggleTimer) {
                        Label(
                            isRunning ? "Pause" : (accumulatedSeconds == 0 && timerStartedAt == nil ? "Start" : "Resume"),
                            systemImage: isRunning ? "pause.fill" : "play.fill"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isRunning ? .orange : .green)

                    if !isRunning && accumulatedSeconds > 0 {
                        Button(role: .destructive, action: resetTimer) {
                            Label("Reset", systemImage: "arrow.counterclockwise")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
    }

    private var distanceSection: some View {
        Section("Distance") {
            HStack {
                TextField("0.0", text: $distanceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .onChange(of: distanceText) { _, _ in syncCardio() }
                Text("km")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            TextField(notesPrompt, text: notesBinding, axis: .vertical)
                .lineLimit(2...6)
        }
    }

    private var rpeSection: some View {
        Section("Effort (RPE)") {
            HStack {
                Slider(value: $rpe, in: 1...10, step: 1) { editing in
                    if !editing {
                        rpeEdited = true
                        syncCardio()
                    }
                }
                Text("\(Int(rpe))")
                    .monospacedDigit()
                    .frame(width: 28, alignment: .trailing)
            }
            Text("How hard did this feel? 1 = trivial, 10 = max effort.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var circuitReferenceSection: some View {
        Group {
            if let planned = plannedWorkout, !planned.plannedExercises.isEmpty {
                Section("Reference (from plan)") {
                    let entries = planned.plannedExercises.sorted { $0.orderIndex < $1.orderIndex }
                    ForEach(entries) { entry in
                        if let ex = entry.exercise {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ex.name)
                                Text(referenceSummary(for: entry))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private func plannedTargetsSection(planned: PlannedWorkout) -> some View {
        Section("Plan") {
            if let km = planned.plannedDistanceKm {
                LabeledContent("Target distance", value: "\(formatDistance(km)) km")
            }
            if let min = planned.plannedDurationMinutes {
                LabeledContent("Target duration", value: "\(min) min")
            }
        }
    }

    // MARK: - Bindings

    private var notesBinding: Binding<String> {
        Binding(
            get: { session.notes ?? "" },
            set: { newValue in
                let trimmed = newValue
                session.notes = trimmed.isEmpty ? nil : trimmed
                try? context.save()
            }
        )
    }

    private var notesPrompt: String {
        switch kind {
        case .distance: return "Optional"
        case .tennis: return "How did it go? (optional)"
        case .circuit: return "Variant, rounds, anything notable"
        }
    }

    // MARK: - Timer control

    private func toggleTimer() {
        if isRunning {
            // Pause: snapshot elapsed into accumulated, then materialize cardio.
            if let started = timerStartedAt {
                accumulatedSeconds += Int(Date().timeIntervalSince(started))
            }
            timerStartedAt = nil
            syncCardio()
        } else {
            timerStartedAt = Date()
            // Materialize a cardio summary right away so Finish lights up after first start.
            syncCardio()
        }
    }

    private func resetTimer() {
        accumulatedSeconds = 0
        timerStartedAt = nil
        // Drop the cardio summary — back to "no content" state.
        if let cardio = session.cardio {
            context.delete(cardio)
            session.cardio = nil
            try? context.save()
        }
    }

    private func hydrateFromSession() {
        if let cardio = session.cardio {
            accumulatedSeconds = cardio.durationSeconds
            if let km = cardio.distanceKm, distanceText.isEmpty {
                distanceText = formatDistance(km)
            }
            if let stored = cardio.rpe {
                rpe = stored
                rpeEdited = true
            }
        } else if distanceText.isEmpty, let planned = plannedWorkout?.plannedDistanceKm {
            distanceText = formatDistance(planned)
        }
    }

    private func syncCardio() {
        let totalSeconds = elapsedSeconds
        guard totalSeconds > 0 else { return }
        let parsedKm = parseDistance()
        let speed: Double? = {
            guard let km = parsedKm, km > 0, totalSeconds > 0 else { return nil }
            return km / (Double(totalSeconds) / 3600.0)
        }()
        let rpeValue: Double? = (kind == .tennis || kind == .circuit) && rpeEdited ? rpe : nil
        if let cardio = session.cardio {
            cardio.durationSeconds = totalSeconds
            cardio.distanceKm = parsedKm
            cardio.averageSpeedKmh = speed
            cardio.rpe = rpeValue
        } else {
            let cardio = CardioSummary(
                durationSeconds: totalSeconds,
                distanceKm: parsedKm,
                averageSpeedKmh: speed,
                rpe: rpeValue,
                session: session
            )
            context.insert(cardio)
        }
        // Mirror primary totals onto the session for History parity with imported workouts.
        session.totalDistanceKm = parsedKm
        try? context.save()
    }

    private func parseDistance() -> Double? {
        guard kind == .distance else { return nil }
        let cleaned = distanceText.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleaned), value >= 0 else { return nil }
        return value == 0 ? nil : value
    }

    private func referenceSummary(for entry: PlannedExerciseEntry) -> String {
        let core = "\(entry.targetSets) × \(entry.targetReps)"
        if let kg = entry.targetWeightKg {
            return "\(core) @ \(formatKg(kg))"
        }
        return core
    }
}

// MARK: - Formatters

private func formatHMS(_ seconds: Int) -> String {
    let h = seconds / 3600
    let m = (seconds % 3600) / 60
    let s = seconds % 60
    if h > 0 {
        return String(format: "%d:%02d:%02d", h, m, s)
    }
    return String(format: "%02d:%02d", m, s)
}

private func formatDistance(_ km: Double) -> String {
    String(format: "%g", km)
}
