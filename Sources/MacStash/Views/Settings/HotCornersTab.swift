import SwiftUI
import AppKit
import MacStashCore

public struct HotCornersTab: View {
    @ObservedObject var appState: AppState
    @State private var newExcludedBundleID: String = ""

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            GroupBox(label: Label(appState.localized("corners.cornerAssignment"), systemImage: "hand.tap.fill")) {
                VStack(spacing: 12) {
                    cornerRow(corner: .topLeft, title: appState.localized("corners.topLeft"))
                    Divider()
                    cornerRow(corner: .topRight, title: appState.localized("corners.topRight"))
                    Divider()
                    cornerRow(corner: .bottomLeft, title: appState.localized("corners.bottomLeft"))
                    Divider()
                    cornerRow(corner: .bottomRight, title: appState.localized("corners.bottomRight"))
                }
                .padding(8)
            }

            GroupBox(label: Label(appState.localized("corners.triggerPrecision"), systemImage: "timer")) {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(appState.localized("corners.hitZoneSensitivity"))
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text("\(Int(appState.settings.cornerSensitivityPoints)) pt")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                        }
                        Slider(
                            value: $appState.settings.cornerSensitivityPoints,
                            in: Defaults.HotCorner.minHitZoneSizePoints...Defaults.HotCorner.maxHitZoneSizePoints,
                            step: 1
                        )
                        Text(appState.localized("corners.hitZoneHint"))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(appState.localized("corners.dwellDelay"))
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text("\(Int(appState.settings.cornerDwellDelaySeconds * 1000)) ms")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                        }
                        Slider(
                            value: $appState.settings.cornerDwellDelaySeconds,
                            in: Defaults.HotCorner.minDwellDelaySeconds...Defaults.HotCorner.maxDwellDelaySeconds,
                            step: 0.05
                        )
                        Text(appState.localized("corners.dwellDelayHint"))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(appState.localized("corners.autoDismissDelay"))
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text("\(Int(appState.settings.cornerHideDelaySeconds * 1000)) ms")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                        }
                        Slider(
                            value: $appState.settings.cornerHideDelaySeconds,
                            in: Defaults.HotCorner.minHideDelaySeconds...Defaults.HotCorner.maxHideDelaySeconds,
                            step: 0.05
                        )
                        Text(appState.localized("corners.autoDismissHint"))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(8)
            }

            GroupBox(label: Label(appState.localized("corners.suppressionRules"), systemImage: "shield")) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(appState.localized("corners.suppressDragging"), isOn: $appState.settings.suppressWhenMousePressed)
                    Toggle(appState.localized("corners.suppressFullScreen"), isOn: $appState.settings.suppressInFullscreen)
                }
                .padding(8)
            }

            GroupBox(label: Label(appState.localized("corners.excludedApps"), systemImage: "xmark.circle")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(appState.localized("corners.excludedAppsDesc"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    if appState.settings.excludedBundleIDs.isEmpty {
                        Text(appState.localized("corners.noExcludedApps"))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(appState.settings.excludedBundleIDs, id: \.self) { bundleID in
                            HStack {
                                Text(bundleID)
                                    .font(.system(size: 12, design: .monospaced))
                                Spacer()
                                Button(action: {
                                    appState.settings.excludedBundleIDs.removeAll(where: { $0 == bundleID })
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 11))
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    HStack {
                        TextField(appState.localized("corners.bundleIDPlaceholder"), text: $newExcludedBundleID)
                            .textFieldStyle(.roundedBorder)
                        Button(appState.localized("corners.add")) {
                            let trimmed = newExcludedBundleID.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty && !appState.settings.excludedBundleIDs.contains(trimmed) {
                                appState.settings.excludedBundleIDs.append(trimmed)
                                newExcludedBundleID = ""
                            }
                        }
                        .disabled(newExcludedBundleID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(8)
            }
        }
    }

    private func cornerRow(corner: CornerPosition, title: String) -> some View {
        HStack {
            Toggle(title, isOn: Binding(
                get: { appState.settings.cornerEnabled[corner] ?? true },
                set: { appState.settings.cornerEnabled[corner] = $0 }
            ))
            .font(.system(size: 12, weight: .medium))

            Spacer()

            Picker("", selection: Binding(
                get: { appState.settings.cornerActions[corner] ?? ControlAction.none },
                set: { appState.settings.cornerActions[corner] = $0 }
            )) {
                ForEach(ControlAction.allCases) { action in
                    Label(action.localizedDisplayName(using: appState.effectiveLanguage), systemImage: action.systemImageName)
                        .tag(action)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 220)
        }
    }
}
