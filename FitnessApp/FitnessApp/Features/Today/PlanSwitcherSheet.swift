import SwiftUI
import SwiftData
import FitnessCore

struct PlanSwitcherSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTabSelection) private var tabSelection
    @Query(sort: \Plan.name) private var plans: [Plan]

    var body: some View {
        NavigationStack {
            List {
                Section("Plans") {
                    if plans.isEmpty {
                        Text("No plans yet.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(plans) { plan in
                        Button {
                            try? PlanActivator.activate(plan, in: context)
                            dismiss()
                        } label: {
                            HStack {
                                Text(plan.name.isEmpty ? "Untitled plan" : plan.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if plan.isActive {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                        .accessibilityLabel("Active")
                                }
                            }
                        }
                    }
                }

                Section {
                    Button {
                        dismiss()
                        tabSelection?.wrappedValue = .settings
                    } label: {
                        Label("Manage plans", systemImage: "gearshape")
                    }
                }
            }
            .navigationTitle("Switch plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

#Preview("Switcher with two plans") {
    let container = try! ModelContainerFactory.makeInMemory()
    let context = ModelContext(container)
    context.insert(Plan(name: "Variant A — tennis Wed only", isActive: true))
    context.insert(Plan(name: "Variant B1 — tennis Wed + Sat", isActive: false))
    context.insert(Plan(name: "Home cardio fallback", isActive: false))
    try! context.save()
    return Text("Host").sheet(isPresented: .constant(true)) {
        PlanSwitcherSheet()
    }
    .modelContainer(container)
}
