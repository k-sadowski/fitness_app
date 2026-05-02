import SwiftUI
import SwiftData
import FitnessCore

struct SettingsRootView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        PlansListView()
                    } label: {
                        Label("Plans", systemImage: "calendar")
                    }
                }

                Section("Coming soon") {
                    DisabledRow(title: "Health & permissions", systemImage: "heart.text.square")
                    DisabledRow(title: "Reminders", systemImage: "bell")
                    DisabledRow(title: "Import plan from markdown", systemImage: "doc.text")
                    DisabledRow(title: "Units", systemImage: "ruler")
                }

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "0.0"
        let build = info?["CFBundleVersion"] as? String ?? "0"
        return "\(short) (\(build))"
    }
}

private struct DisabledRow: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .foregroundStyle(.secondary)
    }
}

#Preview {
    let container = try! ModelContainerFactory.makeInMemory()
    return SettingsRootView()
        .modelContainer(container)
}
