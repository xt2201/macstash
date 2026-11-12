import SwiftUI
import SideDockCore
import MacStashCore

public struct DockPlacementSection: View {
    @Binding public var config: SideDockFileConfig
    public let activeProfileIndex: Int
    public let onSave: (Bool) -> Void

    public init(config: Binding<SideDockFileConfig>, activeProfileIndex: Int, onSave: @escaping (Bool) -> Void) {
        self._config = config
        self.activeProfileIndex = activeProfileIndex
        self.onSave = onSave
    }

    private func localized(_ key: String) -> String {
        LocalizationService.shared.localized(key)
    }

    private var layout: Binding<DockLayoutConfig> {
        $config.profiles[activeProfileIndex].layoutConfig
    }

    public var body: some View {
        DockSettingsCard(title: localized("dock.configTitle"), systemImage: "dock.rectangle", accent: .teal) {
            Toggle(localized("dock.enableSecondDock"), isOn: $config.isDockVisible)
                .font(.system(size: 13, weight: .semibold))
                .onChange(of: config.isDockVisible) { _, _ in onSave(true) }

            Divider()

            HStack {
                Text(localized("dock.placement"))
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Picker("", selection: Binding(
                    get: { layout.wrappedValue.placement },
                    set: { layout.wrappedValue.placement = $0; onSave(false) }
                )) {
                    Text(localized("dock.placementFixedBottom")).tag(DockPlacement.fixedBottom)
                    Text(localized("dock.placementFloating")).tag(DockPlacement.floating)
                    Text(localized("dock.placementFixedTop")).tag(DockPlacement.fixedTop)
                    Text(localized("dock.placementFixedLeft")).tag(DockPlacement.fixedLeft)
                    Text(localized("dock.placementFixedRight")).tag(DockPlacement.fixedRight)
                }
                .pickerStyle(.menu)
                .frame(minWidth: 160, maxWidth: 225)
            }

            sliderRow(
                title: localized("dock.tileSize"),
                valueText: "\(Int(layout.wrappedValue.baseTileSize)) px",
                value: Binding(
                    get: { layout.wrappedValue.baseTileSize },
                    set: { layout.wrappedValue.baseTileSize = $0; onSave(false) }
                ),
                range: 36.0...68.0,
                step: 2.0
            )

            sliderRow(
                title: localized("dock.scale"),
                valueText: "\(String(format: "%.2f", layout.wrappedValue.scale))x",
                value: Binding(
                    get: { layout.wrappedValue.scale },
                    set: { layout.wrappedValue.scale = $0; onSave(false) }
                ),
                range: 0.7...1.5,
                step: 0.05
            )

            sliderRow(
                title: localized("dock.tileSpacing"),
                valueText: "\(Int(layout.wrappedValue.tileSpacing)) px",
                value: Binding(
                    get: { layout.wrappedValue.tileSpacing },
                    set: { layout.wrappedValue.tileSpacing = $0; onSave(false) }
                ),
                range: 4.0...24.0,
                step: 1.0
            )

            sliderRow(
                title: localized("dock.edgeOffset"),
                valueText: "\(Int(layout.wrappedValue.bottomOffset)) px",
                value: Binding(
                    get: { layout.wrappedValue.bottomOffset },
                    set: { layout.wrappedValue.bottomOffset = $0; onSave(false) }
                ),
                range: 0.0...60.0,
                step: 2.0
            )
        }
    }

    private func sliderRow(
        title: String,
        valueText: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.system(size: 12, weight: .medium))
                Spacer()
                Text(valueText)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: step)
        }
    }
}
