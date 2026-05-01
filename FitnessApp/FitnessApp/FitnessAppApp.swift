import SwiftUI
import SwiftData
import FitnessCore

@main
struct FitnessAppApp: App {
    let container: ModelContainer

    init() {
        do {
            let container = try ModelContainerFactory.makeApp()
            try Seeder.seedIfNeeded(in: ModelContext(container))
            self.container = container
        } catch {
            fatalError("Failed to set up ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(container)
    }
}
