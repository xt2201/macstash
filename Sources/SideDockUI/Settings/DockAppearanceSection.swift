import SwiftUI
import SideDockCore
import MacStashCore

public struct DockAppearanceSection: View {
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

    private var theme: Binding<DockTheme> {
        $config.profiles[activeProfileIndex].theme
    }

    public var body: some View {
        DockSettingsCard(title: localized("dock.appearanceTitle"), systemImage: "sparkles.rectangle.stack", accent: .indigo) {
            VStack(alignment: .leading, spacing: 6) {
                Text(localized("dock.themePreset"))
                    .font(.system(size: 12, weight: .medium))

                Picker("", selection: Binding(
                    get: { theme.wrappedValue.preset },
                    set: { theme.wrappedValue.preset = $0; onSave(true) }
                )) {
                    Text("Liquid Glass").tag(DockThemePreset.liquidGlass)
                    Text("macOS Glass").tag(DockThemePreset.macosGlass)
                    Text("Classic Shelf").tag(DockThemePreset.classicShelf)
                    Text("Floating Pill").tag(DockThemePreset.floatingPill)
                    Text("High Contrast").tag(DockThemePreset.highContrast)
                    Text("Clear").tag(DockThemePreset.clear)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(localized("dock.backdropStyle"))
                    .font(.system(size: 12, weight: .medium))

                Picker("", selection: Binding(
                    get: { theme.wrappedValue.backdropStyle },
                    set: { theme.wrappedValue.backdropStyle = $0; onSave(true) }
                )) {
                    Text(localized("dock.backdropAuto")).tag(DockBackdropStyle.autoSystem)
                    Text(localized("dock.backdropLight")).tag(DockBackdropStyle.lightGlass)
                    Text(localized("dock.backdropDark")).tag(DockBackdropStyle.darkGlass)
                    Text(localized("dock.backdropLiquid")).tag(DockBackdropStyle.liquidGlass)
                    Text(localized("dock.backdropClear")).tag(DockBackdropStyle.clear)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(localized("dock.indicatorStyle"))
                    .font(.system(size: 12, weight: .medium))

                Picker("", selection: Binding(
                    get: { theme.wrappedValue.indicatorStyle },
                    set: { theme.wrappedValue.indicatorStyle = $0; onSave(false) }
                )) {
                    Text("Dot").tag(DockIndicatorStyle.dot)
                    Text("Pill").tag(DockIndicatorStyle.pill)
                    Text("Glow").tag(DockIndicatorStyle.glow)
                    Text("None").tag(DockIndicatorStyle.none)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(localized("dock.cornerRadius")).font(.system(size: 12, weight: .medium))
                    Spacer()
                    Text("\(Int(theme.wrappedValue.cornerRadius)) px")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                Slider(value: Binding(
                    get: { theme.wrappedValue.cornerRadius },
                    set: { theme.wrappedValue.cornerRadius = $0; onSave(false) }
                ), in: 4.0...32.0, step: 1.0)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(localized("dock.widgetTextScale")).font(.system(size: 12, weight: .medium))
                    Spacer()
                    Text("\(String(format: "%.2f", theme.wrappedValue.widgetTextScale))x")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                Slider(value: Binding(
                    get: { theme.wrappedValue.widgetTextScale },
                    set: { theme.wrappedValue.widgetTextScale = $0; onSave(false) }
                ), in: 0.85...1.30, step: 0.05)
            }

            Toggle(localized("dock.reduceMotion"), isOn: Binding(
                get: { theme.wrappedValue.reduceMotion },
                set: { theme.wrappedValue.reduceMotion = $0; onSave(false) }
            ))
        }
    }
}
