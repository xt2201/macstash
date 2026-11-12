import SwiftUI

private struct WidgetTextScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1
}

extension EnvironmentValues {
    var widgetTextScale: CGFloat {
        get { self[WidgetTextScaleKey.self] }
        set { self[WidgetTextScaleKey.self] = newValue }
    }
}
