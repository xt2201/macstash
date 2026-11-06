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
            GroupBox(label: Label("Corner Assignment", systemImage: "hand.tap.fill")) {
                VStack(spacing: 12) {
                    cornerRow(corner: .topLeft, title: "Top-Left Corner")
                    Divider()
                    cornerRow(corner: .topRight, title: "Top-Right Corner")
                    Divider()
                    cornerRow(corner: .bottomLeft, title: "Bottom-Left Corner")
                    Divider()
                    cornerRow(corner: .bottomRight, title: "Bottom-Right Corner")
                }
                .padding(8)
            }

            GroupBox(label: Label("Trigger Precision & Timing", systemImage: "timer")) {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Hit-Zone Sensitivity:")
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
                        Text("Smaller values require moving closer to the extreme edge, preventing accidental triggers.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Dwell Activation Delay:")
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
                        Text("Time the cursor must pause at the corner before the dial emerges.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Auto-Hide Delay:")
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
                        Text("Grace period before the dial smoothly hides after cursor leaves the zone.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(8)
            }

            GroupBox(label: Label("Intelligent Suppression", systemImage: "shield")) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Suppress while dragging files or windows", isOn: $appState.settings.suppressWhenMousePressed)
                    Toggle("Suppress when frontmost app is in Full Screen", isOn: $appState.settings.suppressInFullscreen)
                }
                .padding(8)
            }

            GroupBox(label: Label("Excluded Applications", systemImage: "xmark.circle")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Corner dials will stay inactive while these applications are active:")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    if appState.settings.excludedBundleIDs.isEmpty {
                        Text("No excluded applications configured.")
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
                        TextField("e.g. com.apple.FinalCut", text: $newExcludedBundleID)
                            .textFieldStyle(.roundedBorder)
                        Button("Add") {
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
                    Label(action.displayName, systemImage: action.systemImageName)
                        .tag(action)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 220)
        }
    }
}
