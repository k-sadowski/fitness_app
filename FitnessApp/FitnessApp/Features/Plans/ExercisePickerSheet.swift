import SwiftUI
import SwiftData
import FitnessCore

struct ExercisePickerSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allExercises: [Exercise]

    let trainingType: TrainingType
    let onPick: (Exercise) -> Void

    @State private var query: String = ""
    @State private var showingNewSheet: Bool = false

    private var filtered: [Exercise] {
        let pool = allExercises
            .filter { !$0.isArchived && $0.trainingType == trainingType }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return pool }
        return pool.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }

    private var exactMatchExists: Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return allExercises.contains { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }
    }

    var body: some View {
        NavigationStack {
            List {
                let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty && !exactMatchExists {
                    Button {
                        showingNewSheet = true
                    } label: {
                        Label("Create \"\(trimmed)\"", systemImage: "plus.circle.fill")
                    }
                }

                ForEach(filtered) { exercise in
                    Button {
                        onPick(exercise)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.name)
                                .foregroundStyle(.primary)
                            if let desc = exercise.descriptionText, !desc.isEmpty {
                                Text(desc)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search exercises")
            .navigationTitle("Pick \(trainingType.label.lowercased()) exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if filtered.isEmpty && query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ContentUnavailableView(
                        "No exercises yet",
                        systemImage: "dumbbell",
                        description: Text("Type a name above to create one.")
                    )
                }
            }
            .sheet(isPresented: $showingNewSheet) {
                NewExerciseSheet(initialName: query.trimmingCharacters(in: .whitespacesAndNewlines), trainingType: trainingType) { newExercise in
                    onPick(newExercise)
                    dismiss()
                }
            }
        }
    }
}

struct NewExerciseSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let initialName: String
    let trainingType: TrainingType
    let onCreate: (Exercise) -> Void

    @State private var name: String = ""
    @State private var descriptionText: String = ""
    @FocusState private var nameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .focused($nameFocused)
                    LabeledContent("Type") {
                        Label(trainingType.label, systemImage: trainingType.systemImage)
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Description (optional)") {
                    TextField("e.g. brace, sit between the hips, drive through midfoot", text: $descriptionText, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle("New exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create", action: create)
                        .disabled(trimmedName.isEmpty)
                }
            }
            .onAppear {
                if name.isEmpty { name = initialName }
                nameFocused = true
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func create() {
        guard !trimmedName.isEmpty else { return }
        let trimmedDesc = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let exercise = Exercise(
            name: trimmedName,
            trainingType: trainingType,
            descriptionText: trimmedDesc.isEmpty ? nil : trimmedDesc
        )
        context.insert(exercise)
        try? context.save()
        onCreate(exercise)
        dismiss()
    }
}

#Preview("Empty picker") {
    let container = try! ModelContainerFactory.makeInMemory()
    return ExercisePickerSheet(trainingType: .strength) { _ in }
        .modelContainer(container)
}

#Preview("Picker with entries") {
    let container = try! ModelContainerFactory.makeInMemory()
    let context = ModelContext(container)
    context.insert(Exercise(name: "Barbell Back Squat", trainingType: .strength, descriptionText: "Brace, sit between the hips, drive through midfoot."))
    context.insert(Exercise(name: "Bench Press", trainingType: .strength))
    context.insert(Exercise(name: "Romanian Deadlift", trainingType: .strength))
    try! context.save()
    return ExercisePickerSheet(trainingType: .strength) { _ in }
        .modelContainer(container)
}
