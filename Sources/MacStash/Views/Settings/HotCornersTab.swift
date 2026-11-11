import SwiftUI
import AppKit
import MacStashCore

public struct HotCornersTab: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var appState: AppState

    @State private var selectedProfileID: UUID
    @State private var newExcludedBundleID: String = ""
    @State private var showingAddProfileSheet: Bool = false
    @State private var newProfileName: String = ""
    @State private var newProfileBundleID: String = ""
    @State private var focusedCorner: CornerPosition? = nil
    @State private var focusedEdge: EdgePosition? = nil
    @State private var highlightTarget: InteractiveMapTarget? = nil

    enum InteractiveMapTarget: Equatable {
        case corner(CornerPosition)
        case edgeSlider
        case drawer
    }

    public init(appState: AppState) {
        self.appState = appState
        let defaultID = appState.appProfiles.first(where: { $0.bundleIdentifier == nil })?.id
            ?? appState.appProfiles.first?.id
            ?? UUID()
        self._selectedProfileID = State(initialValue: defaultID)
    }

    private var selectedProfileIndex: Int {
        if let idx = appState.appProfiles.firstIndex(where: { $0.id == selectedProfileID }) {
            return idx
        }
        return 0
    }

    private var selectedProfile: AppProfile {
        guard appState.appProfiles.indices.contains(selectedProfileIndex) else {
            return appState.activeProfile
        }
        return appState.appProfiles[selectedProfileIndex]
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Section 1: Application Profiles Bar
            SettingsCard(
                title: appState.localized("corners.profile"),
                systemImage: "app.badge.checkmark",
                accentColor: .blue
            ) {
                HStack(spacing: 10) {
                    Picker("", selection: $selectedProfileID) {
                        ForEach(appState.appProfiles) { profile in
                            Text(profile.bundleIdentifier == nil ? appState.localized("corners.default") : profile.name)
                                .tag(profile.id)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(maxWidth: 260)

                    Spacer()

                    Button {
                        newProfileName = ""
                        newProfileBundleID = ""
                        showingAddProfileSheet = true
                    } label: {
                        Label(appState.localized("corners.addProfile"), systemImage: "plus")
                            .font(.system(size: 11.5, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    if selectedProfile.bundleIdentifier != nil {
                        Button(role: .destructive) {
                            deleteProfile(selectedProfile)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help(appState.localized("corners.deleteProfile"))
                    }
                }

                if selectedProfile.bundleIdentifier != nil {
                    Divider()
                    HStack(spacing: 12) {
                        Toggle(
                            appState.localized("corners.profileEnabled"),
                            isOn: profileEnabledBinding(for: selectedProfileIndex)
                        )
                        .font(.system(size: 12, weight: .medium))

                        Spacer()

                        if let bundleID = selectedProfile.bundleIdentifier {
                            HStack(spacing: 6) {
                                if let icon = appIcon(for: bundleID) {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                }
                                Text("\(appState.localized("corners.bundleIDShort")): \(bundleID)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

            // Section 2: Interactive Desktop Screen Map
            SettingsCard(
                title: appState.localized("corners.visualPreview"),
                systemImage: "macwindow.on.rectangle",
                accentColor: .cyan
            ) {
                interactiveScreenMap
                Text(appState.localized("corners.previewHint"))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            // Section 3: Corner Assignments
            SettingsCard(
                title: appState.localized("corners.cornerAssignment"),
                systemImage: "inset.filled.topleft.topright.bottomleft.bottomright.rectangle",
                accentColor: .cyan
            ) {
                Toggle(appState.localized("corners.enableCornerDials"), isOn: $appState.isCornerDialsEnabled)
                    .font(.system(size: 13, weight: .semibold))

                Divider()

                VStack(spacing: 10) {
                    cornerAssignmentRow(corner: .topLeft, labelKey: "corners.topLeft")
                    cornerAssignmentRow(corner: .topRight, labelKey: "corners.topRight")
                    cornerAssignmentRow(corner: .bottomLeft, labelKey: "corners.bottomLeft")
                    cornerAssignmentRow(corner: .bottomRight, labelKey: "corners.bottomRight")
                }
                .opacity(appState.isCornerDialsEnabled ? 1.0 : 0.55)
            }

            // Section 4: Edge Slider & Now Playing Media
            SettingsCard(
                title: appState.localized("corners.edgeSliders"),
                systemImage: "slider.vertical.3",
                accentColor: .blue
            ) {
                Toggle(appState.localized("corners.enableEdgeDynamic"), isOn: $appState.isEdgeSlidersEnabled)
                    .font(.system(size: 13, weight: .semibold))

                Divider()

                VStack(spacing: 10) {
                    edgeAssignmentRow(edge: .left, labelKey: "corners.edgeLeft")
                    edgeAssignmentRow(edge: .right, labelKey: "corners.edgeRight")
                }
                .opacity(appState.isEdgeSlidersEnabled ? 1.0 : 0.55)

                Text(appState.localized("corners.edgeSlidersHint"))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                Toggle(appState.localized("corners.edgeMediaControls"), isOn: $appState.edgeBarShowMediaControls)
                    .font(.system(size: 12.5, weight: .medium))
                    .disabled(!appState.isEdgeSlidersEnabled)

                Toggle(appState.localized("corners.edgeVisualizer"), isOn: $appState.edgeBarVisualizerEnabled)
                    .font(.system(size: 12.5, weight: .medium))
                    .disabled(!appState.isEdgeSlidersEnabled || !appState.edgeBarShowMediaControls)
                    .padding(.leading, 18)

                Text(appState.localized("corners.edgeMediaControlsHint"))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .overlay(highlightOverlay(for: .edgeSlider, color: .blue))

            // Section 5: Utility Drawers & Cursor Palette
            SettingsCard(
                title: appState.localized("corners.drawerSection"),
                systemImage: "tray.2.fill",
                accentColor: .purple
            ) {
                Toggle(appState.localized("corners.stashShelfToggle"), isOn: $appState.settings.isStashShelfEnabled)
                    .font(.system(size: 12.5, weight: .medium))

                Toggle(appState.localized("corners.scratchpadToggle"), isOn: $appState.settings.isScratchpadEnabled)
                    .font(.system(size: 12.5, weight: .medium))

                VStack(alignment: .leading, spacing: 6) {
                    Text(appState.localized("corners.drawerPosition"))
                        .font(.system(size: 12.5, weight: .medium))
                    Picker("", selection: $appState.drawerEdgePosition) {
                        Text(appState.localized("corners.edgeLeft")).tag(EdgePosition.left)
                        Text(appState.localized("corners.edgeRight")).tag(EdgePosition.right)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Divider()

                Toggle(appState.localized("corners.cursorPaletteToggle"), isOn: $appState.settings.isCursorPaletteEnabled)
                    .font(.system(size: 12.5, weight: .medium))

                Text(appState.localized("corners.drawerTip"))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .overlay(highlightOverlay(for: .drawer, color: .purple))

            // Section 6: Trigger Precision & Gestures
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

            // Section 7: Suppression & Display Selection
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

            // Section 8: Excluded Applications
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
        .sheet(isPresented: $showingAddProfileSheet) {
            addProfileSheet
        }
        .onAppear {
            if !appState.appProfiles.contains(where: { $0.id == selectedProfileID }),
               let first = appState.appProfiles.first {
                selectedProfileID = first.id
            }
        }
    }

    // MARK: - Interactive Screen Diagram

    private var interactiveScreenMap: some View {
        ZStack {
            // Desktop wallpaper backdrop simulation
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color(red: 0.08, green: 0.11, blue: 0.18), Color(red: 0.12, green: 0.17, blue: 0.28)]
                            : [Color(red: 0.86, green: 0.91, blue: 0.98), Color(red: 0.78, green: 0.86, blue: 0.96)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.16), lineWidth: 1.2)
                )

            // Simulated macOS menu bar & notch
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.black.opacity(0.75))
                        .frame(width: 44, height: 10)
                    Spacer()
                }
                .padding(.top, 2)
                Spacer()
            }

            // 4 Corner Nodes
            VStack {
                HStack {
                    mapCornerNode(.topLeft)
                    Spacer()
                    mapCornerNode(.topRight)
                }
                Spacer()
                HStack {
                    mapCornerNode(.bottomLeft)
                    Spacer()
                    mapCornerNode(.bottomRight)
                }
            }
            .padding(10)

            // Edge Slider Nodes (Dual Edges: Left & Right)
            if appState.isEdgeSlidersEnabled {
                HStack {
                    if appState.edgeSliderPlacement == .both || appState.edgeSliderPlacement == .left {
                        mapEdgeSliderNode(for: .left)
                            .padding(.vertical, 36)
                            .padding(.horizontal, 6)
                    }
                    Spacer()
                    if appState.edgeSliderPlacement == .both || appState.edgeSliderPlacement == .right {
                        mapEdgeSliderNode(for: .right)
                            .padding(.vertical, 36)
                            .padding(.horizontal, 6)
                    }
                }
            }

            // Drawer Node (Left or Right)
            if appState.settings.isStashShelfEnabled || appState.settings.isScratchpadEnabled {
                let sameEdgeAsSlider = appState.isEdgeSlidersEnabled && (appState.drawerEdgePosition == appState.edgeSliderPosition)
                HStack {
                    if appState.drawerEdgePosition == .right { Spacer() }
                    mapDrawerNode
                        .padding(.leading, appState.drawerEdgePosition == .left ? (sameEdgeAsSlider ? 38 : 6) : 0)
                        .padding(.trailing, appState.drawerEdgePosition == .right ? (sameEdgeAsSlider ? 38 : 6) : 0)
                    if appState.drawerEdgePosition == .left { Spacer() }
                }
            }

            // Center Dock + Cursor Palette Pill Summary
            VStack(spacing: 6) {
                if appState.settings.isCursorPaletteEnabled {
                    HStack(spacing: 5) {
                        Image(systemName: "dial.medium.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text(appState.localized("corners.cursorPaletteToggle"))
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .overlay(Capsule().strokeBorder(Color.purple.opacity(0.4), lineWidth: 0.8))
                }
            }
        }
        .frame(height: 176)
    }

    private func mapCornerNode(_ corner: CornerPosition) -> some View {
        let action = effectiveAction(for: corner)
        let enabled = appState.isCornerDialsEnabled && action != .none && (appState.settings.cornerEnabled[corner] ?? true)
        let tint = action.accentColors.first ?? .secondary
        let isHighlighted = focusedCorner == corner

        return Button {
            withAnimation(.easeInOut(duration: 0.16)) {
                focusedCorner = corner
                focusedEdge = nil
                highlightTarget = .corner(corner)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: action.systemImage)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(enabled ? .white : .secondary)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(enabled ? tint : Color.primary.opacity(0.12)))

                VStack(alignment: .leading, spacing: 1) {
                    Text(localizedCornerName(corner))
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(localizedShortAction(action))
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundColor(enabled ? .primary : .secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(isHighlighted ? tint : Color.primary.opacity(0.12), lineWidth: isHighlighted ? 1.6 : 0.8)
            )
            .opacity(enabled ? 1.0 : 0.55)
        }
        .buttonStyle(.plain)
    }

    private func mapEdgeSliderNode(for edge: EdgePosition) -> some View {
        let action = edge == .left ? selectedProfile.leftEdgeAction : selectedProfile.rightEdgeAction
        let tint = action.accentColors.first ?? .blue
        let isHighlighted = (focusedEdge == edge) || (highlightTarget == .edgeSlider && focusedEdge == nil)
        return Button {
            withAnimation(.easeInOut(duration: 0.16)) {
                focusedCorner = nil
                focusedEdge = edge
                highlightTarget = .edgeSlider
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: action.systemImage)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(tint)
                RoundedRectangle(cornerRadius: 2)
                    .fill(tint.opacity(0.7))
                    .frame(width: 4, height: 24)
                if (action == .volume && appState.edgeBarShowMediaControls) || action == .mediaPlayback {
                    Image(systemName: "music.note")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.pink)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .background(Capsule().fill(.ultraThinMaterial))
            .overlay(Capsule().strokeBorder(tint.opacity(isHighlighted ? 0.9 : 0.35), lineWidth: 1.0))
        }
        .buttonStyle(.plain)
    }

    private var mapDrawerNode: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.16)) {
                focusedCorner = nil
                focusedEdge = nil
                highlightTarget = .drawer
            }
        } label: {
            VStack(spacing: 4) {
                if appState.settings.isStashShelfEnabled {
                    Image(systemName: "tray.2.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.orange)
                }
                if appState.settings.isScratchpadEnabled {
                    Image(systemName: "note.text")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.yellow)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.ultraThinMaterial))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.purple.opacity(highlightTarget == .drawer ? 0.9 : 0.35), lineWidth: 1.0)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers & Rows

    private func cornerAssignmentRow(corner: CornerPosition, labelKey: String) -> some View {
        let action = effectiveAction(for: corner)
        let tint = action.accentColors.first ?? .secondary
        let isFocused = focusedCorner == corner
        let isCornerOn = appState.settings.cornerEnabled[corner] ?? true

        return HStack(spacing: 10) {
            Image(systemName: action.systemImage)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isCornerOn && action != .none ? .white : .secondary)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isCornerOn && action != .none ? tint : Color.primary.opacity(0.1))
                )

            Text(appState.localized(labelKey))
                .font(.system(size: 12.5, weight: .medium))

            Spacer()

            Picker("", selection: actionBinding(for: selectedProfileIndex, corner: corner)) {
                ForEach(ControlAction.allCases) { act in
                    Text(localizedActionName(act)).tag(act)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 225)

            Toggle("", isOn: cornerEnabledBinding(for: corner))
                .toggleStyle(.switch)
                .labelsHidden()
                .controlSize(.mini)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isFocused ? tint.opacity(0.12) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(isFocused ? tint.opacity(0.45) : Color.clear, lineWidth: 1.0)
        )
    }

    private func edgeAssignmentRow(edge: EdgePosition, labelKey: String) -> some View {
        let action = effectiveEdgeAction(for: edge)
        let tint = action.accentColors.first ?? .secondary
        let isFocused = focusedEdge == edge
        let isEdgeOn = isEdgeEnabled(edge)

        return HStack(spacing: 10) {
            Image(systemName: action.systemImage)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isEdgeOn && action != .none ? .white : .secondary)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isEdgeOn && action != .none ? tint : Color.primary.opacity(0.1))
                )

            Text(appState.localized(labelKey))
                .font(.system(size: 12.5, weight: .medium))

            Spacer()

            Picker("", selection: edgeActionBinding(for: selectedProfileIndex, edge: edge)) {
                ForEach(ControlAction.allCases) { act in
                    Text(localizedActionName(act)).tag(act)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 225)

            Toggle("", isOn: edgeEnabledBinding(for: edge))
                .toggleStyle(.switch)
                .labelsHidden()
                .controlSize(.mini)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isFocused ? tint.opacity(0.12) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(isFocused ? tint.opacity(0.45) : Color.clear, lineWidth: 1.0)
        )
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
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }
            Slider(value: value, in: range, step: step)
            Text(hint)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func highlightOverlay(for target: InteractiveMapTarget, color: Color) -> some View {
        if highlightTarget == target {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(color.opacity(0.45), lineWidth: 1.5)
                .padding(.top, 30)
                .allowsHitTesting(false)
        }
    }

    private var addProfileSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(appState.localized("corners.addProfile"))
                .font(.system(size: 15, weight: .bold))

            VStack(alignment: .leading, spacing: 6) {
                Text(appState.localized("corners.profileName"))
                    .font(.system(size: 12, weight: .medium))
                TextField("Safari / Final Cut Pro", text: $newProfileName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(appState.localized("corners.bundleID"))
                    .font(.system(size: 12, weight: .medium))

                HStack(spacing: 8) {
                    TextField("com.apple.Safari", text: $newProfileBundleID)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))

                    Menu(appState.localized("corners.chooseApp")) {
                        let running = AppPickerHelper.runningUserApps()
                        if !running.isEmpty {
                            Section(appState.localized("corners.runningApps")) {
                                ForEach(running) { picked in
                                    Button(picked.name) {
                                        if newProfileName.trimmingCharacters(in: .whitespaces).isEmpty {
                                            newProfileName = picked.name
                                        }
                                        newProfileBundleID = picked.bundleIdentifier
                                    }
                                }
                            }
                        }
                        Divider()
                        Button(appState.localized("corners.browseApps")) {
                            AppPickerHelper.browseForApplication { picked in
                                if let picked {
                                    if newProfileName.trimmingCharacters(in: .whitespaces).isEmpty {
                                        newProfileName = picked.name
                                    }
                                    newProfileBundleID = picked.bundleIdentifier
                                }
                            }
                        }
                    }
                    .menuStyle(.borderedButton)
                    .fixedSize()
                }
            }

            HStack {
                Spacer()
                Button(appState.localized("corners.cancel")) {
                    showingAddProfileSheet = false
                }
                .keyboardShortcut(.cancelAction)

                Button(appState.localized("corners.save")) {
                    addProfile()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(
                    newProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    newProfileBundleID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
            }
            .padding(.top, 6)
        }
        .padding(20)
        .frame(width: 420)
        .macStashTheme(appState.resolvedColorScheme)
    }

    // MARK: - Bindings & Mutations

    private func effectiveAction(for corner: CornerPosition) -> ControlAction {
        if let profAction = selectedProfile.cornerActions[corner] {
            return profAction
        }
        return appState.settings.cornerActions[corner] ?? .none
    }

    private func effectiveEdgeAction(for edge: EdgePosition) -> ControlAction {
        switch edge {
        case .left:
            return selectedProfile.leftEdgeAction
        case .right:
            return selectedProfile.rightEdgeAction
        default:
            return .none
        }
    }

    private func actionBinding(for profileIdx: Int, corner: CornerPosition) -> Binding<ControlAction> {
        Binding(
            get: {
                guard appState.appProfiles.indices.contains(profileIdx) else {
                    return appState.settings.cornerActions[corner] ?? .none
                }
                return appState.appProfiles[profileIdx].cornerActions[corner]
                    ?? appState.settings.cornerActions[corner]
                    ?? .none
            },
            set: { newValue in
                guard appState.appProfiles.indices.contains(profileIdx) else { return }
                appState.appProfiles[profileIdx].cornerActions[corner] = newValue
                let updated = appState.appProfiles[profileIdx]
                if updated.bundleIdentifier == nil {
                    appState.settings.cornerActions[corner] = newValue
                }
                if appState.activeProfile.id == updated.id {
                    appState.activeProfile = updated
                }
                appState.saveSettings()
            }
        )
    }

    private func rightEdgeActionBinding(for profileIdx: Int) -> Binding<ControlAction> {
        Binding(
            get: {
                guard appState.appProfiles.indices.contains(profileIdx) else { return .volume }
                return appState.appProfiles[profileIdx].rightEdgeAction
            },
            set: { newValue in
                guard appState.appProfiles.indices.contains(profileIdx) else { return }
                appState.appProfiles[profileIdx].rightEdgeAction = newValue
                let updated = appState.appProfiles[profileIdx]
                if appState.activeProfile.id == updated.id {
                    appState.activeProfile = updated
                }
                appState.saveSettings()
            }
        )
    }

    private func leftEdgeActionBinding(for profileIdx: Int) -> Binding<ControlAction> {
        Binding(
            get: {
                guard appState.appProfiles.indices.contains(profileIdx) else { return .brightness }
                return appState.appProfiles[profileIdx].leftEdgeAction
            },
            set: { newValue in
                guard appState.appProfiles.indices.contains(profileIdx) else { return }
                appState.appProfiles[profileIdx].leftEdgeAction = newValue
                let updated = appState.appProfiles[profileIdx]
                if appState.activeProfile.id == updated.id {
                    appState.activeProfile = updated
                }
                appState.saveSettings()
            }
        )
    }

    private func edgeActionBinding(for profileIdx: Int, edge: EdgePosition) -> Binding<ControlAction> {
        switch edge {
        case .left:
            return leftEdgeActionBinding(for: profileIdx)
        case .right:
            return rightEdgeActionBinding(for: profileIdx)
        default:
            return .constant(.none)
        }
    }

    private func isEdgeEnabled(_ edge: EdgePosition) -> Bool {
        switch edge {
        case .left:
            return appState.edgeSliderPlacement == .both || appState.edgeSliderPlacement == .left
        case .right:
            return appState.edgeSliderPlacement == .both || appState.edgeSliderPlacement == .right
        default:
            return false
        }
    }

    private func edgeEnabledBinding(for edge: EdgePosition) -> Binding<Bool> {
        Binding(
            get: { isEdgeEnabled(edge) },
            set: { isEnabled in
                let currentLeft = isEdgeEnabled(.left)
                let currentRight = isEdgeEnabled(.right)
                let newLeft = edge == .left ? isEnabled : currentLeft
                let newRight = edge == .right ? isEnabled : currentRight

                if newLeft && newRight {
                    appState.edgeSliderPlacement = .both
                } else if newLeft {
                    appState.edgeSliderPlacement = .left
                } else if newRight {
                    appState.edgeSliderPlacement = .right
                } else {
                    appState.edgeSliderPlacement = .none
                }
            }
        )
    }

    private func profileEnabledBinding(for profileIdx: Int) -> Binding<Bool> {
        Binding(
            get: {
                guard appState.appProfiles.indices.contains(profileIdx) else { return true }
                return appState.appProfiles[profileIdx].isEnabled
            },
            set: { newValue in
                guard appState.appProfiles.indices.contains(profileIdx) else { return }
                appState.appProfiles[profileIdx].isEnabled = newValue
                if appState.activeProfile.id == appState.appProfiles[profileIdx].id, !newValue,
                   let def = appState.appProfiles.first(where: { $0.bundleIdentifier == nil }) {
                    appState.activeProfile = def
                }
                appState.saveSettings()
            }
        )
    }

    private func cornerEnabledBinding(for corner: CornerPosition) -> Binding<Bool> {
        Binding(
            get: { appState.settings.cornerEnabled[corner] ?? true },
            set: { newValue in
                appState.settings.cornerEnabled[corner] = newValue
            }
        )
    }

    private func addProfile() {
        let trimmedName = newProfileName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBundle = newProfileBundleID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedBundle.isEmpty else { return }

        let base = appState.appProfiles.first(where: { $0.bundleIdentifier == nil }) ?? AppProfile.defaultProfile
        let created = AppProfile(
            name: trimmedName,
            bundleIdentifier: trimmedBundle,
            cornerActions: base.cornerActions,
            leftEdgeAction: base.leftEdgeAction,
            rightEdgeAction: base.rightEdgeAction,
            isEnabled: true
        )
        appState.appProfiles.append(created)
        selectedProfileID = created.id
        appState.saveSettings()
        showingAddProfileSheet = false
    }

    private func deleteProfile(_ profile: AppProfile) {
        guard profile.bundleIdentifier != nil else { return }
        appState.appProfiles.removeAll { $0.id == profile.id }
        if appState.activeProfile.id == profile.id {
            appState.activeProfile = appState.appProfiles.first(where: { $0.bundleIdentifier == nil }) ?? .defaultProfile
        }
        selectedProfileID = appState.appProfiles.first?.id ?? UUID()
        appState.saveSettings()
    }

    private func addExcludedBundleID(_ rawID: String) {
        let clean = rawID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, !appState.settings.excludedBundleIDs.contains(clean) else { return }
        appState.settings.excludedBundleIDs.append(clean)
    }

    private func appIcon(for bundleID: String) -> NSImage? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return nil }
        return NSWorkspace.shared.icon(forFile: url.path)
    }

    private func appName(for bundleID: String) -> String? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return nil }
        return FileManager.default.displayName(atPath: url.path)
    }

    private func localizedCornerName(_ corner: CornerPosition) -> String {
        switch corner {
        case .topLeft: return appState.localized("corners.topLeft")
        case .topRight: return appState.localized("corners.topRight")
        case .bottomLeft: return appState.localized("corners.bottomLeft")
        case .bottomRight: return appState.localized("corners.bottomRight")
        }
    }

    private func localizedShortAction(_ action: ControlAction) -> String {
        switch action {
        case .volume: return appState.localized("palette.volume")
        case .brightness: return appState.localized("palette.brightness")
        case .keyboardBrightness: return appState.localized("corners.action.backlight")
        case .timer: return appState.localized("palette.timer")
        case .keepAwake: return appState.localized("corners.action.keepAwake")
        case .stashShelf: return appState.localized("corners.action.stashShelf")
        case .scratchpad: return appState.localized("corners.action.scratchpad")
        case .mediaPlayback: return appState.localized("corners.action.mediaPlayback")
        case .none: return appState.localized("menubar.off")
        }
    }

    private func localizedActionName(_ action: ControlAction) -> String {
        action.localizedDisplayName(using: appState.effectiveLanguage)
    }
}
