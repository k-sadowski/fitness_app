import SwiftUI

enum AppTab: Hashable {
    case today, history, library, metrics, settings
}

private struct AppTabSelectionKey: EnvironmentKey {
    static let defaultValue: Binding<AppTab>? = nil
}

extension EnvironmentValues {
    var appTabSelection: Binding<AppTab>? {
        get { self[AppTabSelectionKey.self] }
        set { self[AppTabSelectionKey.self] = newValue }
    }
}
