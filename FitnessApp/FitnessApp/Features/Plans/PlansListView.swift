import SwiftUI
import SwiftData
import FitnessCore

struct PlansListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Plan.createdAt) private var plans: [Plan]

    @State private var pendingNavigationPlanID: UUID?
    @State private var renamingPlan: Plan?
    @State private var renameText: String = ""
    @State private var deletingPlan: Plan?

    var body: some View {
        List {
            ForEach(plans) { plan in
                NavigationLink {
                    PlanEditView(plan: plan)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(plan.name.isEmpty ? "Untitled plan" : plan.name)
                                .font(.body)
                            Text(summary(for: plan))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if plan.isActive {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.tint)
                                .accessibilityLabel("Active plan")
                        }
                    }
                }
                .contextMenu {
                    if !plan.isActive {
                        Button {
                            try? PlanActivator.activate(plan, in: context)
                        } label: {
                            Label("Make active", systemImage: "checkmark.circle")
                        }
                    }
                    Button {
                        renameText = plan.name
                        renamingPlan = plan
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        deletingPlan = plan
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Plans")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    let plan = createEmptyPlan()
                    pendingNavigationPlanID = plan.id
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New plan")
            }
        }
        .navigationDestination(item: $pendingNavigationPlanID) { id in
            if let plan = plans.first(where: { $0.id == id }) {
                PlanEditView(plan: plan)
            } else {
                ContentUnavailableView("Plan not found", systemImage: "questionmark.folder")
            }
        }
        .overlay {
            if plans.isEmpty {
                ContentUnavailableView {
                    Label("No plans yet", systemImage: "calendar")
                } description: {
                    Text("Create a plan to schedule your week.")
                } actions: {
                    Button("Create plan") {
                        let plan = createEmptyPlan()
                        pendingNavigationPlanID = plan.id
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .alert("Rename plan", isPresented: renameAlertBinding, presenting: renamingPlan) { plan in
            TextField("Name", text: $renameText)
            Button("Save") {
                let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    plan.name = trimmed
                    try? context.save()
                }
                renamingPlan = nil
            }
            Button("Cancel", role: .cancel) { renamingPlan = nil }
        }
        .confirmationDialog(
            "Delete this plan?",
            isPresented: deleteDialogBinding,
            presenting: deletingPlan
        ) { plan in
            Button("Delete \(plan.name.isEmpty ? "plan" : "\"\(plan.name)\"")", role: .destructive) {
                delete(plan)
                deletingPlan = nil
            }
            Button("Cancel", role: .cancel) { deletingPlan = nil }
        } message: { _ in
            Text("This removes the plan and its planned workouts. Logged sessions stay intact.")
        }
    }

    private var renameAlertBinding: Binding<Bool> {
        Binding(get: { renamingPlan != nil }, set: { if !$0 { renamingPlan = nil } })
    }

    private var deleteDialogBinding: Binding<Bool> {
        Binding(get: { deletingPlan != nil }, set: { if !$0 { deletingPlan = nil } })
    }

    private func summary(for plan: Plan) -> String {
        let totalWorkouts = plan.days.reduce(0) { $0 + $1.plannedWorkouts.count }
        let scheduledDays = plan.days.filter { !$0.plannedWorkouts.isEmpty }.count
        if totalWorkouts == 0 { return "Empty week" }
        return "\(totalWorkouts) workout\(totalWorkouts == 1 ? "" : "s") across \(scheduledDays) day\(scheduledDays == 1 ? "" : "s")"
    }

    private func createEmptyPlan() -> Plan {
        let plan = Plan(name: "New plan", isActive: plans.isEmpty)
        context.insert(plan)
        for weekday in 1...7 {
            let day = PlanDay(weekday: weekday, plan: plan)
            context.insert(day)
        }
        try? context.save()
        return plan
    }

    private func delete(_ plan: Plan) {
        let wasActive = plan.isActive
        context.delete(plan)
        try? context.save()
        if wasActive, let fallback = plans.first(where: { $0.id != plan.id }) {
            try? PlanActivator.activate(fallback, in: context)
        }
    }
}

#Preview("Plans list") {
    let container = try! ModelContainerFactory.makeInMemory()
    let context = ModelContext(container)
    try! Seeder.seedIfNeeded(in: context)
    let variant = Plan(name: "Variant A — tennis Wed only", isActive: false)
    context.insert(variant)
    for weekday in 1...7 {
        let day = PlanDay(weekday: weekday, plan: variant)
        context.insert(day)
    }
    try! context.save()
    return NavigationStack { PlansListView() }
        .modelContainer(container)
}

#Preview("Plans list — empty") {
    let container = try! ModelContainerFactory.makeInMemory()
    return NavigationStack { PlansListView() }
        .modelContainer(container)
}
