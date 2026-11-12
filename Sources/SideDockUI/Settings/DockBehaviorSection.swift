import SwiftUI
import AppKit
import SideDockCore
import MacStashCore

public struct DockBehaviorSection: View {
    @Binding public var config: SideDockFileConfig
    public let activeProfileIndex: Int
    public let onSave: (Bool) -> Void

    @State private var newHiddenBundleID: String = ""

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
        DockSettingsCard(title: localized("dock.behaviorTitle"), systemImage: "bolt.horizontal", accent: .blue) {
            Toggle(localized("dock.magnificationEnabled"), isOn: Binding(
                get: { layout.wrappedValue.magnificationEnabled },
                set: { layout.wrappedValue.magnificationEnabled = $0; onSave(false) }
            ))

            if layout.wrappedValue.magnificationEnabled {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(localized("dock.magnificationScale")).font(.system(size: 12, weight: .medium))
                        Spacer()
                        Text("\(String(format: "%.2f", layout.wrappedValue.magnificationScale))x")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: Binding(
                        get: { layout.wrappedValue.magnificationScale },
                        set: { layout.wrappedValue.magnificationScale = $0; onSave(false) }
                    ), in: 1.05...2.0, step: 0.05)
                }
            }

            Toggle(localized("dock.showTooltips"), isOn: Binding(
                get: { layout.wrappedValue.showTooltips },
                set: { layout.wrappedValue.showTooltips = $0; onSave(false) }
            ))

            Toggle(localized("dock.showBadges"), isOn: Binding(
                get: { layout.wrappedValue.showNotificationBadges },
                set: { layout.wrappedValue.showNotificationBadges = $0; onSave(false) }
            ))

            Toggle(localized("dock.showWindowPreviews"), isOn: Binding(
                get: { layout.wrappedValue.showWindowPreviewsOnHover },
                set: { layout.wrappedValue.showWindowPreviewsOnHover = $0; onSave(false) }
            ))

            Toggle(localized("dock.showMinimizedWindows"), isOn: Binding(
                get: { layout.wrappedValue.showMinimizedWindows },
                set: { layout.wrappedValue.showMinimizedWindows = $0; onSave(false) }
            ))

            Toggle(localized("dock.bounceOnLaunch"), isOn: Binding(
                get: { layout.wrappedValue.bounceOnLaunch },
                set: { layout.wrappedValue.bounceOnLaunch = $0; onSave(false) }
            ))

            Toggle(localized("dock.soundFeedback"), isOn: Binding(
                get: { layout.wrappedValue.dockSoundFeedback },
                set: { layout.wrappedValue.dockSoundFeedback = $0; onSave(false) }
            ))

            Toggle(localized("dock.windowSwitcherEnabled"), isOn: $config.windowSwitcherEnabled)
                .onChange(of: config.windowSwitcherEnabled) { _, _ in onSave(true) }

            if config.windowSwitcherEnabled {
                Toggle(localized("dock.windowSwitcherCmdTab"), isOn: $config.windowSwitcherInterceptCmdTab)
                    .onChange(of: config.windowSwitcherInterceptCmdTab) { _, _ in onSave(true) }
            }

            Divider()

            Toggle(localized("dock.autoHide"), isOn: Binding(
                get: { layout.wrappedValue.autoHide },
                set: { layout.wrappedValue.autoHide = $0; onSave(true) }
            ))

            if layout.wrappedValue.autoHide {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(localized("dock.revealDelay")).font(.system(size: 12, weight: .medium))
                        Spacer()
                        Text("\(String(format: "%.1f", layout.wrappedValue.revealDelaySeconds)) s")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: Binding(
                        get: { layout.wrappedValue.revealDelaySeconds },
                        set: { layout.wrappedValue.revealDelaySeconds = $0; onSave(false) }
                    ), in: 0.0...3.0, step: 0.1)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(localized("dock.edgeZone")).font(.system(size: 12, weight: .medium))
                        Spacer()
                        Text("\(Int(layout.wrappedValue.edgeTriggerThickness)) px")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: Binding(
                        get: { layout.wrappedValue.edgeTriggerThickness },
                        set: { layout.wrappedValue.edgeTriggerThickness = $0; onSave(false) }
                    ), in: 2.0...20.0, step: 1.0)
                }
            }

            Toggle(localized("dock.hideInFullscreen"), isOn: Binding(
                get: { layout.wrappedValue.hideInFullscreen },
                set: { layout.wrappedValue.hideInFullscreen = $0; onSave(false) }
            ))
            Toggle(localized("dock.hideOnHover"), isOn: Binding(
                get: { layout.wrappedValue.hideOnWindowHover },
                set: { layout.wrappedValue.hideOnWindowHover = $0; onSave(false) }
            ))
            Toggle(localized("dock.reserveSpace"), isOn: Binding(
                get: { layout.wrappedValue.reserveDockSpace },
                set: { layout.wrappedValue.reserveDockSpace = $0; onSave(false) }
            ))
            Toggle(localized("dock.showRunningApps"), isOn: Binding(
                get: { layout.wrappedValue.showRunningApps },
                set: { layout.wrappedValue.showRunningApps = $0; onSave(false) }
            ))
            Toggle(localized("dock.coordinateNativeDock"), isOn: Binding(
                get: { layout.wrappedValue.coordinateNativeDockAutoHide },
                set: { layout.wrappedValue.coordinateNativeDockAutoHide = $0; onSave(true) }
            ))

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text(localized("dock.hiddenRunningApps"))
                    .font(.system(size: 12, weight: .medium))

                HStack(spacing: 8) {
                    TextField("com.example.helper", text: $newHiddenBundleID)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11))
                    Button(localized("dock.add")) {
                        let trimmed = newHiddenBundleID.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        if !layout.wrappedValue.hiddenRunningBundleIDs.contains(trimmed) {
                            layout.wrappedValue.hiddenRunningBundleIDs.append(trimmed)
                            onSave(false)
                        }
                        newHiddenBundleID = ""
                    }
                    .disabled(newHiddenBundleID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if !layout.wrappedValue.hiddenRunningBundleIDs.isEmpty {
                    FlowHiddenAppsChips(
                        bundleIDs: layout.wrappedValue.hiddenRunningBundleIDs,
                        onRemove: { bid in
                            layout.wrappedValue.hiddenRunningBundleIDs.removeAll { $0 == bid }
                            onSave(false)
                        }
                    )
                }
            }
        }
    }
}

private struct FlowHiddenAppsChips: View {
    let bundleIDs: [String]
    let onRemove: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(bundleIDs, id: \.self) { bid in
                    HStack(spacing: 4) {
                        Text(bid)
                            .font(.system(size: 10.5))
                        Button {
                            onRemove(bid)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.primary.opacity(0.08)))
                }
            }
        }
    }
}
