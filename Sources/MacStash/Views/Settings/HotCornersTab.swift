import SwiftUI
import AppKit
import MacStashCore

public struct HotCornersTab: View {
    @ObservedObject var appState: AppState
    @State private var newExcludedBundleID: String = ""
    @State private var selectedProfileID: UUID?
    @State private var showAddProfileSheet: Bool = false
    @State private var newProfileName: String = ""
    @State private var newProfileBundleID: String = ""

    public init(appState: AppState) {
        self.appState = appState
    }

    private var currentProfile: AppProfile {
        if let id = selectedProfileID, let found = appState.appProfiles.first(where: { $0.id == id }) {
            return found
        }
        return appState.appProfiles.first ?? .defaultProfile
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            GroupBox(label: Label(appState.localized("corners.cornerAssignment"), systemImage: "hand.tap.fill")) {
                VStack(spacing: 12) {
                    // Profile Switcher Header
                    HStack {
                        Text(appState.localized("corners.profile"))
                            .font(.system(size: 12, weight: .semibold))

                        Picker("", selection: Binding(
                            get: { currentProfile.id },
                            set: { selectedProfileID = $0 }
                        )) {
                            ForEach(appState.appProfiles) { prof in
                                Text(prof.name + (prof.bundleIdentifier == nil ? " (\(appState.localized("corners.default")))" : ""))
                                    .tag(prof.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 190)

                        Spacer()

                        Button(action: {
                            newProfileName = ""
                            newProfileBundleID = ""
                            showAddProfileSheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.bordered)
                        .help(appState.localized("corners.addProfile"))

                        if currentProfile.bundleIdentifier != nil {
                            Button(action: {
                                deleteProfile(currentProfile)
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 11))
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.bordered)
                            .help(appState.localized("corners.deleteProfile"))
                        }
                    }

                    Divider()

                    cornerRow(profile: currentProfile, corner: .topLeft, title: appState.localized("corners.topLeft"))
                    Divider()
                    cornerRow(profile: currentProfile, corner: .topRight, title: appState.localized("corners.topRight"))
                    Divider()
                    cornerRow(profile: currentProfile, corner: .bottomLeft, title: appState.localized("corners.bottomLeft"))
                    Divider()
                    cornerRow(profile: currentProfile, corner: .bottomRight, title: appState.localized("corners.bottomRight"))
                }
                .padding(8)
            }

            GroupBox(label: Label(appState.localized("corners.edgeSliders"), systemImage: "slider.vertical.3")) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(appState.localized("corners.enableEdgeSliders"), isOn: $appState.isEdgeSlidersEnabled)

                    if appState.isEdgeSlidersEnabled {
                        HStack {
                            Text(appState.localized("corners.rightEdgeAction"))
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Picker("", selection: Binding(
                                get: { currentProfile.rightEdgeAction },
                                set: { updateEdgeAction(profileID: currentProfile.id, action: $0) }
                            )) {
                                ForEach(ControlAction.allCases) { action in
                                    Label(action.localizedDisplayName(using: appState.effectiveLanguage), systemImage: action.systemImageName)
                                        .tag(action)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 220)
                        }

                        Text(appState.localized("corners.edgeSlidersHint"))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        if currentProfile.rightEdgeAction == .volume {
                            Divider()
                                .padding(.vertical, 2)

                            VStack(alignment: .leading, spacing: 8) {
                                Toggle(appState.localized("corners.edgeMediaControls"), isOn: $appState.edgeBarShowMediaControls)
                                    .font(.system(size: 12, weight: .medium))

                                if appState.edgeBarShowMediaControls {
                                    Toggle(appState.localized("corners.edgeVisualizer"), isOn: $appState.edgeBarVisualizerEnabled)
                                        .font(.system(size: 12))
                                        .padding(.leading, 18)

                                    Text(appState.localized("corners.edgeMediaControlsHint"))
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 18)
                                }
                            }
                        }
                    }
                }
                .padding(8)
            }

            GroupBox(label: Label(appState.effectiveLanguage == "vi" ? "Tiện ích mép trái và con trỏ" : "Left Edge Utilities & Cursor Palette", systemImage: "tray.2")) {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle(appState.effectiveLanguage == "vi" ? "Kệ thả tệp Stash Shelf" : "Stash Drop Shelf", isOn: $appState.settings.isStashShelfEnabled)
                    Toggle(appState.effectiveLanguage == "vi" ? "Ghi chú nhanh Scratchpad" : "Quick Scratchpad", isOn: $appState.settings.isScratchpadEnabled)
                    Toggle(appState.effectiveLanguage == "vi" ? "Vòng xoay tại con trỏ chuột" : "Cursor Radial Palette", isOn: $appState.settings.isCursorPaletteEnabled)
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

            GroupBox(label: Label(appState.localized("corners.gestures"), systemImage: "hand.draw")) {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(appState.localized("corners.scrollAdjustment"), isOn: $appState.scrollAdjustmentEnabled)
                    Text(appState.localized("corners.scrollAdjustmentHint"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(8)
            }

            GroupBox(label: Label(appState.localized("corners.suppressionRules"), systemImage: "shield")) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(appState.localized("corners.suppressDragging"), isOn: $appState.settings.suppressWhenMousePressed)
                    Toggle(appState.localized("corners.suppressFullScreen"), isOn: $appState.settings.suppressInFullscreen)
                    Toggle(appState.localized("corners.onlyOuterCorners"), isOn: $appState.onlyOuterCorners)
                    Text(appState.localized("corners.onlyOuterCornersHint"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
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
        .sheet(isPresented: $showAddProfileSheet) {
            VStack(alignment: .leading, spacing: 14) {
                Text(appState.localized("corners.addProfile"))
                    .font(.system(size: 14, weight: .bold))

                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.localized("corners.profileName"))
                        .font(.system(size: 12, weight: .medium))
                    TextField("e.g. Safari, Xcode, Photoshop", text: $newProfileName)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.localized("corners.bundleID"))
                        .font(.system(size: 12, weight: .medium))
                    TextField("com.apple.Safari", text: $newProfileBundleID)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Spacer()
                    Button(appState.localized("corners.cancel")) {
                        showAddProfileSheet = false
                    }
                    .buttonStyle(.bordered)

                    Button(appState.localized("corners.save")) {
                        addProfile()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(16)
            .frame(width: 320)
        }
    }

    private func cornerRow(profile: AppProfile, corner: CornerPosition, title: String) -> some View {
        HStack {
            Toggle(title, isOn: Binding(
                get: { appState.settings.cornerEnabled[corner] ?? true },
                set: {
                    appState.settings.cornerEnabled[corner] = $0
                    appState.saveSettings()
                }
            ))
            .font(.system(size: 12, weight: .medium))

            Spacer()

            Picker("", selection: Binding(
                get: { profile.cornerActions[corner] ?? appState.settings.cornerActions[corner] ?? ControlAction.none },
                set: { newAction in
                    updateCornerAction(profileID: profile.id, corner: corner, action: newAction)
                }
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

    private func updateCornerAction(profileID: UUID, corner: CornerPosition, action: ControlAction) {
        if let idx = appState.appProfiles.firstIndex(where: { $0.id == profileID }) {
            appState.appProfiles[idx].cornerActions[corner] = action
            if appState.activeProfile.id == profileID {
                appState.activeProfile.cornerActions[corner] = action
            }
            if appState.appProfiles[idx].bundleIdentifier == nil {
                appState.settings.cornerActions[corner] = action
            }
            appState.saveSettings()
        }
    }

    private func updateEdgeAction(profileID: UUID, action: ControlAction) {
        if let idx = appState.appProfiles.firstIndex(where: { $0.id == profileID }) {
            appState.appProfiles[idx].rightEdgeAction = action
            if appState.activeProfile.id == profileID {
                appState.activeProfile.rightEdgeAction = action
            }
            appState.saveSettings()
        }
    }

    private func deleteProfile(_ profile: AppProfile) {
        guard profile.bundleIdentifier != nil else { return }
        appState.appProfiles.removeAll(where: { $0.id == profile.id })
        selectedProfileID = appState.appProfiles.first?.id
        appState.saveSettings()
    }

    private func addProfile() {
        let trimmedName = newProfileName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedID = newProfileBundleID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let newProf = AppProfile(
            name: trimmedName,
            bundleIdentifier: trimmedID.isEmpty ? nil : trimmedID
        )
        appState.appProfiles.append(newProf)
        selectedProfileID = newProf.id
        appState.saveSettings()
        showAddProfileSheet = false
    }
}
