import SwiftUI
import SwiftData
import FitnessCore

struct RootTabView: View {
    @State private var selection: AppTab = .today

    var body: some View {
        TabView(selection: $selection) {
            TodayHomeView()
                .tabItem { Label("Today", systemImage: "figure.run.circle.fill") }
                .tag(AppTab.today)

            HistoryPlaceholderView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(AppTab.history)

            LibraryPlaceholderView()
                .tabItem { Label("Library", systemImage: "dumbbell.fill") }
                .tag(AppTab.library)

            MetricsHomeView()
                .tabItem { Label("Metrics", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(AppTab.metrics)

            SettingsRootView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        .environment(\.appTabSelection, $selection)
    }
}

// MARK: - Placeholder tabs

private struct HistoryPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "History",
                systemImage: "clock.arrow.circlepath",
                description: Text("Logged workouts will appear here.")
            )
            .navigationTitle("History")
        }
    }
}

private struct LibraryPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Library",
                systemImage: "dumbbell.fill",
                description: Text("Your exercises will live here.")
            )
            .navigationTitle("Library")
        }
    }
}

// MARK: - Metrics tab (weight slice)

struct MetricsHomeView: View {
    @Query(sort: \WeightEntry.recordedAt, order: .reverse) private var entries: [WeightEntry]
    @State private var showingLogSheet = false

    var body: some View {
        NavigationStack {
            List {
                Section("Weight") {
                    if let latest = entries.first {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formatKg(latest.weightKg))
                                .font(.title.weight(.semibold))
                            Text(latest.recordedAt, style: .date)
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    } else {
                        Text("No entries yet — tap + to log your first weight.")
                            .foregroundStyle(.secondary)
                    }
                    NavigationLink("All weight entries") {
                        WeightHistoryView()
                    }
                }
            }
            .navigationTitle("Metrics")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingLogSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Log weight")
                }
            }
            .sheet(isPresented: $showingLogSheet) {
                WeightLogSheet(suggestedWeight: entries.first?.weightKg)
            }
        }
    }
}

struct WeightHistoryView: View {
    @Query(sort: \WeightEntry.recordedAt, order: .reverse) private var entries: [WeightEntry]
    @Environment(\.modelContext) private var context

    var body: some View {
        List {
            ForEach(entries) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatKg(entry.weightKg))
                            .font(.headline)
                        Text(entry.recordedAt, format: .dateTime.day().month().year().hour().minute())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if entry.source == .healthkit {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.pink)
                            .font(.caption)
                            .accessibilityLabel("From Apple Health")
                    }
                }
            }
            .onDelete(perform: delete)
        }
        .navigationTitle("Weight")
        .overlay {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No weight entries",
                    systemImage: "scalemass",
                    description: Text("Logged weights will appear here.")
                )
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(entries[index])
        }
        try? context.save()
    }
}

struct WeightLogSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var weightText: String = ""
    @State private var note: String = ""
    @FocusState private var weightFocused: Bool

    let suggestedWeight: Double?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("Weight", text: $weightText)
                            .keyboardType(.decimalPad)
                            .focused($weightFocused)
                        Text("kg")
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Note (optional)") {
                    TextField("e.g. before breakfast", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                }
            }
            .navigationTitle("Log weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log", action: save)
                        .disabled(parsedWeight == nil)
                }
            }
            .onAppear {
                if let suggestedWeight {
                    weightText = String(format: "%.1f", suggestedWeight)
                }
                weightFocused = true
            }
        }
    }

    private var parsedWeight: Double? {
        let cleaned = weightText.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleaned), value > 0, value < 500 else { return nil }
        return value
    }

    private func save() {
        guard let value = parsedWeight else { return }
        let entry = WeightEntry(
            weightKg: value,
            recordedAt: Date(),
            source: .manual,
            note: note.isEmpty ? nil : note
        )
        context.insert(entry)
        try? context.save()
        dismiss()
    }
}

// MARK: - Helpers

private func formatKg(_ kg: Double) -> String {
    String(format: "%.1f kg", kg)
}

// MARK: - Previews

#Preview("Tab root") {
    let container = try! ModelContainerFactory.makeInMemory()
    try! Seeder.seedIfNeeded(in: ModelContext(container))
    return RootTabView()
        .modelContainer(container)
}

#Preview("Metrics — empty") {
    let container = try! ModelContainerFactory.makeInMemory()
    return MetricsHomeView()
        .modelContainer(container)
}

#Preview("Metrics — with entries") {
    let container = try! ModelContainerFactory.makeInMemory()
    let context = ModelContext(container)
    context.insert(WeightEntry(weightKg: 88.6, recordedAt: Date()))
    context.insert(WeightEntry(weightKg: 88.9, recordedAt: Date().addingTimeInterval(-86400)))
    try! context.save()
    return MetricsHomeView()
        .modelContainer(container)
}

#Preview("Weight log sheet") {
    let container = try! ModelContainerFactory.makeInMemory()
    return WeightLogSheet(suggestedWeight: 88.4)
        .modelContainer(container)
}
