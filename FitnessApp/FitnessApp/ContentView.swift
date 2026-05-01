import SwiftUI
import SwiftData
import FitnessCore

struct ContentView: View {
    @Query(filter: #Predicate<Plan> { $0.isActive }) private var activePlans: [Plan]

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Active plan")
                .font(.headline)
            Text(activePlans.first?.name ?? "—")
                .font(.title.weight(.semibold))
            Text("\(activePlans.first?.days.count ?? 0) plan days")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    let container = try! ModelContainerFactory.makeInMemory()
    try! Seeder.seedIfNeeded(in: ModelContext(container))
    return ContentView()
        .modelContainer(container)
}
