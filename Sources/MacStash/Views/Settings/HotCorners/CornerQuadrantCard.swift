import SwiftUI
import AppKit
import MacStashCore
import MacStashDesignSystem

public struct CornerQuadrantCard: View {
    @ObservedObject var appState: AppState
    public let selectedProfileIndex: Int
    public let selectedProfile: AppProfile
    @Binding var focusedCorner: CornerPosition?
    @Binding var focusedEdge: EdgePosition?
    @Binding var highlightTarget: HotCornersTab.InteractiveMapTarget?

    public init(
        appState: AppState,
        selectedProfileIndex: Int,
        selectedProfile: AppProfile,
        focusedCorner: Binding<CornerPosition?>,
        focusedEdge: Binding<EdgePosition?>,
        highlightTarget: Binding<HotCornersTab.InteractiveMapTarget?>
    ) {
        self.appState = appState
        self.selectedProfileIndex = selectedProfileIndex
        self.selectedProfile = selectedProfile
        self._focusedCorner = focusedCorner
        self._focusedEdge = focusedEdge
        self._highlightTarget = highlightTarget
    }

    public var body: some View {
        VStack(spacing: 18) {
            // Corner Assignments
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

            // Edge Slider & Now Playing Media
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

            // Utility Drawers & Cursor Palette
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
        }
    }

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
            .frame(minWidth: 160, maxWidth: 225)

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
            .frame(minWidth: 160, maxWidth: 225)

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

    @ViewBuilder
    private func highlightOverlay(for target: HotCornersTab.InteractiveMapTarget, color: Color) -> some View {
        if highlightTarget == target {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(color.opacity(0.45), lineWidth: 1.5)
                .padding(.top, 30)
                .allowsHitTesting(false)
        }
    }

    private func isEdgeEnabled(_ edge: EdgePosition) -> Bool {
        guard appState.isEdgeSlidersEnabled else { return false }
        switch appState.edgeSliderPlacement {
        case .left: return edge == .left
        case .right: return edge == .right
        case .both: return true
        case .none: return false
        }
    }

    private func edgeEnabledBinding(for edge: EdgePosition) -> Binding<Bool> {
        Binding(
            get: { isEdgeEnabled(edge) },
            set: { enabled in
                if enabled {
                    switch (edge, appState.edgeSliderPlacement) {
                    case (.left, .right): appState.edgeSliderPlacement = .both
                    case (.right, .left): appState.edgeSliderPlacement = .both
                    default: break
                    }
                } else {
                    switch (edge, appState.edgeSliderPlacement) {
                    case (.left, .both): appState.edgeSliderPlacement = .right
                    case (.right, .both): appState.edgeSliderPlacement = .left
                    default: break
                    }
                }
            }
        )
    }

    private func effectiveAction(for corner: CornerPosition) -> ControlAction {
        if let profAction = selectedProfile.cornerActions[corner] {
            return profAction
        }
        return appState.settings.cornerActions[corner] ?? .none
    }

    private func effectiveEdgeAction(for edge: EdgePosition) -> ControlAction {
        switch edge {
        case .left: return selectedProfile.leftEdgeAction
        case .right: return selectedProfile.rightEdgeAction
        default: return .none
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

    private func edgeActionBinding(for profileIdx: Int, edge: EdgePosition) -> Binding<ControlAction> {
        if edge == .left {
            return leftEdgeActionBinding(for: profileIdx)
        } else {
            return rightEdgeActionBinding(for: profileIdx)
        }
    }

    private func leftEdgeActionBinding(for profileIdx: Int) -> Binding<ControlAction> {
        Binding(
            get: {
                guard appState.appProfiles.indices.contains(profileIdx) else {
                    return appState.activeProfile.leftEdgeAction
                }
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

    private func rightEdgeActionBinding(for profileIdx: Int) -> Binding<ControlAction> {
        Binding(
            get: {
                guard appState.appProfiles.indices.contains(profileIdx) else {
                    return appState.activeProfile.rightEdgeAction
                }
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

    private func cornerEnabledBinding(for corner: CornerPosition) -> Binding<Bool> {
        Binding(
            get: { appState.settings.cornerEnabled[corner] ?? true },
            set: { appState.settings.cornerEnabled[corner] = $0 }
        )
    }

    private func localizedActionName(_ action: ControlAction) -> String {
        switch action {
        case .volume: return appState.localized("corners.action.volume")
        case .brightness: return appState.localized("corners.action.brightness")
        case .keyboardBrightness: return appState.localized("corners.action.backlight")
        case .timer: return appState.localized("corners.action.timer")
        case .keepAwake: return appState.localized("corners.action.keepAwake")
        case .mediaPlayback: return appState.localized("corners.action.mediaPlayback")
        case .stashShelf: return appState.localized("general.stashShelf")
        case .scratchpad: return appState.localized("general.scratchpad")
        case .none: return appState.localized("corners.action.none")
        @unknown default: return action.displayName
        }
    }
}
