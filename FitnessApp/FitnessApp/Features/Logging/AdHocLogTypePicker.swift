import SwiftUI
import FitnessCore

struct AdHocLogTypePicker: View {
    @Environment(\.dismiss) private var dismiss
    let onPick: (TrainingType) -> Void

    private static let pickable: [TrainingType] = [.strength, .running, .walkingPad, .tennis, .circuit]

    var body: some View {
        NavigationStack {
            List {
                ForEach(Self.pickable, id: \.self) { type in
                    Button {
                        onPick(type)
                        dismiss()
                    } label: {
                        Label(type.label, systemImage: type.systemImage)
                    }
                }
            }
            .navigationTitle("Log workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AdHocLogTypePicker { _ in }
}
