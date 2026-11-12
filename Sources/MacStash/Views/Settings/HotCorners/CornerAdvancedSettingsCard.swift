import SwiftUI
import AppKit
import MacStashCore
import MacStashDesignSystem

public struct CornerAdvancedSettingsCard: View {
    @ObservedObject var appState: AppState
    @State private var newExcludedBundleID: String = ""

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 18) {
            // Trigger Precision & Gestures
            SettingsCard(
                title: appState.localized("corners.triggerPrecision"),
                systemImage: "scope",
                accentColor: .teal
            ) {
                sliderRow(
                    title: appState.localized("corners.hitZoneSensitivity"),
                    valueText: "\(Int(appState.cornerSensitivityRadius)) px",
                    value: Binding(
                        get: { Double(appState.cornerSensitivityRadius) },
                        set: { appState.cornerSensitivityRadius = CGFloat($0) }
                    ),
                    range: Double(Defaults.HotCorner.minHitZoneSizePoints)...Double(Defaults.HotCorner.maxHitZoneSizePoints),
                    step: 2,
                    hint: appState.localized("corners.hitZoneHint")
                )

                Divider()

                sliderRow(
                    title: appState.localized("corners.dwellDelay"),
                    valueText: String(format: "%.2fs", appState.cornerDwellDelay),
                    value: $appState.cornerDwellDelay,
                    range: Defaults.HotCorner.minDwellDelaySeconds...Defaults.HotCorner.maxDwellDelaySeconds,
                    step: 0.02,
                    hint: appState.localized("corners.dwellDelayHint")
                )

                Divider()

                sliderRow(
                    title: appState.localized("corners.autoDismissDelay"),
                    valueText: String(format: "%.2fs", appState.settings.cornerHideDelaySeconds),
                    value: $appState.settings.cornerHideDelaySeconds,
                    range: Defaults.HotCorner.minHideDelaySeconds...Defaults.HotCorner.maxHideDelaySeconds,
                    step: 0.05,
                    hint: appState.localized("corners.autoDismissHint")
                )

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Toggle(appState.localized("corners.scrollAdjustment"), isOn: $appState.scrollAdjustmentEnabled)
                        .font(.system(size: 12.5, weight: .medium))
                    Text(appState.localized("corners.scrollAdjustmentHint"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            // Suppression & Display Selection
            SettingsCard(
                title: appState.localized("corners.suppressionRules"),
                systemImage: "hand.raised.fill",
                accentColor: .orange
            ) {
                Toggle(appState.localized("corners.suppressDragging"), isOn: $appState.settings.suppressWhenMousePressed)
                    .font(.system(size: 12.5, weight: .medium))

                Toggle(appState.localized("corners.suppressFullScreen"), isOn: $appState.settings.suppressInFullscreen)
                    .font(.system(size: 12.5, weight: .medium))

                VStack(alignment: .leading, spacing: 3) {
                    Toggle(appState.localized("corners.onlyOuterCorners"), isOn: $appState.onlyOuterCorners)
                        .font(.system(size: 12.5, weight: .medium))
                    Text(appState.localized("corners.onlyOuterCornersHint"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(appState.localized("corners.displayTarget"))
                            .font(.system(size: 12.5, weight: .medium))
                        Spacer()
                        Picker("", selection: $appState.cornerDisplayTarget) {
                            ForEach(HotCornerDisplayTarget.allCases) { target in
                                Text(target.localizedDisplayName(using: appState.effectiveLanguage)).tag(target)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 240)
                    }

                    Text(appState.localized("corners.displayTargetHint"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            // Excluded Applications
            SettingsCard(
                title: appState.localized("corners.excludedApps"),
                systemImage: "nosign",
                accentColor: .red
            ) {
                Text(appState.localized("corners.excludedAppsDesc"))
                    .font(.system(size: 11.5))
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    TextField(appState.localized("corners.bundleIDPlaceholder"), text: $newExcludedBundleID)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))

                    Menu(appState.localized("corners.chooseApp")) {
                        let running = AppPickerHelper.runningUserApps()
                        if !running.isEmpty {
                            Section(appState.localized("corners.runningApps")) {
                                ForEach(running) { picked in
                                    Button(picked.name) {
                                        addExcludedBundleID(picked.bundleIdentifier)
                                    }
                                }
                            }
                        }
                        Divider()
                        Button(appState.localized("corners.browseApps")) {
                            AppPickerHelper.browseForApplication { picked in
                                if let picked {
                                    addExcludedBundleID(picked.bundleIdentifier)
                                }
                            }
                        }
                    }
                    .menuStyle(.borderedButton)
                    .fixedSize()

                    Button(appState.localized("corners.add")) {
                        addExcludedBundleID(newExcludedBundleID)
                        newExcludedBundleID = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newExcludedBundleID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if appState.settings.excludedBundleIDs.isEmpty {
                    Text(appState.localized("corners.noExcludedApps"))
                        .font(.system(size: 11.5))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                } else {
                    VStack(spacing: 6) {
                        ForEach(appState.settings.excludedBundleIDs, id: \.self) { bundleID in
                            HStack(spacing: 10) {
                                if let icon = appIcon(for: bundleID) {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 18, height: 18)
                                } else {
                                    Image(systemName: "app.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                        .frame(width: 18, height: 18)
                                }

                                VStack(alignment: .leading, spacing: 1) {
                                    if let appName = appName(for: bundleID) {
                                        Text(appName)
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    Text(bundleID)
                                        .font(.system(size: 10.5, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Button {
                                    appState.settings.excludedBundleIDs.removeAll { $0 == bundleID }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.primary.opacity(0.04))
                            )
                        }
                    }
                }
            }
        }
    }

    private func sliderRow(
        title: String,
        valueText: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        hint: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 12.5, weight: .medium))
                Spacer()
                Text(valueText)
                    .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }

            Slider(value: value, in: range, step: step)

            Text(hint)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }

    private func addExcludedBundleID(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !appState.settings.excludedBundleIDs.contains(trimmed) {
            appState.settings.excludedBundleIDs.append(trimmed)
            appState.saveSettings()
        }
    }

    private func appName(for bundleID: String) -> String? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        return FileManager.default.displayName(atPath: url.path)
    }

    private func appIcon(for bundleID: String) -> NSImage? {
        AppIconCache.shared.icon(forBundleID: bundleID, targetSize: NSSize(width: 18, height: 18))
    }
}
