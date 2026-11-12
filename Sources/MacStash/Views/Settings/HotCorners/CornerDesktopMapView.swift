import SwiftUI
import AppKit
import MacStashCore
import MacStashDesignSystem

public struct CornerDesktopMapView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var appState: AppState
    public let selectedProfile: AppProfile
    @Binding var focusedCorner: CornerPosition?
    @Binding var focusedEdge: EdgePosition?
    @Binding var highlightTarget: HotCornersTab.InteractiveMapTarget?

    public init(
        appState: AppState,
        selectedProfile: AppProfile,
        focusedCorner: Binding<CornerPosition?>,
        focusedEdge: Binding<EdgePosition?>,
        highlightTarget: Binding<HotCornersTab.InteractiveMapTarget?>
    ) {
        self.appState = appState
        self.selectedProfile = selectedProfile
        self._focusedCorner = focusedCorner
        self._focusedEdge = focusedEdge
        self._highlightTarget = highlightTarget
    }

    public var body: some View {
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

    private func effectiveAction(for corner: CornerPosition) -> ControlAction {
        if let profAction = selectedProfile.cornerActions[corner] {
            return profAction
        }
        return appState.settings.cornerActions[corner] ?? .none
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
        case .mediaPlayback: return appState.localized("corners.action.mediaPlayback")
        case .stashShelf: return appState.localized("general.stashShelf")
        case .scratchpad: return appState.localized("general.scratchpad")
        case .none: return appState.localized("corners.action.none")
        @unknown default: return action.displayName
        }
    }
}
