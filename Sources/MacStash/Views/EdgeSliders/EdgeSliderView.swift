import SwiftUI
import MacStashCore

/// EdgeBar vertical slider view that slides out from the physical screen edge.
/// Dynamically supports both Left and Right screen edges independently (Dual Edge Bars).
/// In default mode: hosts the full vertical slider with tactile transport controls and album artwork capsule.
/// On hovering the audio section: smoothly morphs into an expanded Dynamic Island with live waveform visualizer,
/// interactive scrubber bar, and an edge-most Volume Logo button that reveals the matching vertical volume slider.
public struct EdgeSliderView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var nowPlaying = NowPlayingManager.shared
    @ObservedObject public var interactionState: EdgeSliderInteractionState
    public let edge: EdgePosition
    public let displayID: CGDirectDisplayID

    @State private var isDragging: Bool = false
    @State private var dragValue: Float = 0.5
    @State private var isTopHovered: Bool = false
    @State private var isVolumeColumnShowing: Bool = false
    @State private var collapseWorkItem: DispatchWorkItem?
    @State private var volumeCloseWorkItem: DispatchWorkItem?

    @State private var isPrevHovered: Bool = false
    @State private var isRewindHovered: Bool = false
    @State private var isPlayHovered: Bool = false
    @State private var isForwardHovered: Bool = false
    @State private var isNextHovered: Bool = false

    private let sliderWidth: CGFloat = 56

    public init(
        appState: AppState,
        edge: EdgePosition = .right,
        displayID: CGDirectDisplayID = 0,
        interactionState: EdgeSliderInteractionState = EdgeSliderInteractionState()
    ) {
        self.appState = appState
        self.edge = edge
        self.displayID = displayID
        self.interactionState = interactionState
    }

    private var action: ControlAction {
        edge == .left ? appState.activeProfile.leftEdgeAction : appState.activeProfile.rightEdgeAction
    }

    private var shouldShowMediaIsland: Bool {
        (action == .volume && appState.settings.edgeBarShowMediaControls) || action == .mediaPlayback
    }

    private func currentValue(for targetAction: ControlAction) -> Float {
        if isDragging {
            return dragValue
        }
        if targetAction == .volume && appState.audio.isMuted {
            return 0.0
        }
        if targetAction == action, let live = (edge == .left ? appState.liveLeftSliderValue : appState.liveRightSliderValue) {
            return live
        }
        return Float(appState.getValue(for: targetAction, displayID: displayID))
    }

    private var isExpanded: Bool {
        let active = edge == .left ? appState.isLeftSliderActive : appState.isRightSliderActive
        return isDragging || (active && (appState.activeDisplayID == displayID || appState.activeDisplayID == 0))
    }

    private var baselineBottomInset: CGFloat {
        if shouldShowMediaIsland && nowPlaying.hasMedia {
            return 60.0
        }
        return 110.0
    }

    public var body: some View {
        let isPlacementActive = appState.settings.edgeSliderPlacement == .both
            || (edge == .left && appState.settings.edgeSliderPlacement == .left)
            || (edge == .right && appState.settings.edgeSliderPlacement == .right)
        let isVisible = appState.isEnabled && appState.isEdgeSlidersEnabled && isPlacementActive && action != .none
        let shouldReduceMotion = appState.settings.respectReduceMotion && NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

        ZStack(alignment: edge == .right ? .bottomTrailing : .bottomLeading) {
            if isVisible {
                sliderContent
                    .offset(x: isExpanded ? (edge == .right ? -8 : 8) : (edge == .right ? 88 : -88))
                    .opacity(isExpanded ? 1.0 : 0.0)
                    .animation(
                        shouldReduceMotion
                            ? .easeInOut(duration: 0.12)
                            : .spring(response: 0.28 * appState.settings.animationSpeedMultiplier, dampingFraction: 0.82),
                        value: isExpanded
                    )
            }
        }
        .padding(.bottom, baselineBottomInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: edge == .right ? .bottomTrailing : .bottomLeading)
        .onChange(of: isExpanded) { _, newValue in
            if !newValue {
                cancelCollapse()
                cancelVolumeClose()
                isVolumeColumnShowing = false
                interactionState.reset()
            }
        }
        .macStashTheme(appState.resolvedColorScheme)
    }

    // MARK: - Main Content Switcher

    @ViewBuilder
    private var sliderContent: some View {
        let isMuted = action == .volume && appState.audio.isMuted
        let isVolumeWithMedia = action == .volume && nowPlaying.hasMedia
        let effectiveTint: Color = isVolumeWithMedia ? nowPlaying.artworkTint : (isMuted ? Color.red : (action.accentColors.first ?? .clear))
        let secondaryTint: Color = isVolumeWithMedia ? nowPlaying.artworkSecondaryTint : (action.accentColors.last ?? .blue)

        let showVolumeColumn = isVolumeColumnShowing || interactionState.isVolumeButtonHovered || interactionState.isVolumeColumnHovered || isDragging
        let volumeTint: Color = appState.audio.isMuted ? .red : (nowPlaying.hasMedia ? nowPlaying.artworkTint : (ControlAction.volume.accentColors.first ?? .blue))
        let volumeSecondaryTint: Color = nowPlaying.hasMedia ? nowPlaying.artworkSecondaryTint : (ControlAction.volume.accentColors.last ?? .cyan)

        if interactionState.isMediaExpanded && shouldShowMediaIsland {
            // Mode B: Expanded Dynamic Island Media Mode with Edge-most Volume Button & Dropped-in Volume Slider
            VStack(alignment: edge == .right ? .trailing : .leading, spacing: 6) {
                if showVolumeColumn {
                    verticalVolumeGlassColumn(tint: volumeTint, secondaryTint: volumeSecondaryTint, isMuted: appState.audio.isMuted)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: edge == .right ? .bottomTrailing : .bottomLeading)),
                            removal: .opacity.combined(with: .scale(scale: 0.95, anchor: edge == .right ? .bottomTrailing : .bottomLeading))
                        ))
                        .onHover { hovering in
                            interactionState.isVolumeColumnHovered = hovering
                            if hovering {
                                cancelCollapse()
                                cancelVolumeClose()
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    isVolumeColumnShowing = true
                                    interactionState.isVolumeColumnVisible = true
                                }
                            } else {
                                scheduleVolumeClose()
                                scheduleCollapse()
                            }
                        }
                }

                EdgeMediaIslandView(
                    appState: appState,
                    edge: edge,
                    isVolumeHovered: volumeButtonHoveredBinding
                )
                .onHover { hovering in
                    interactionState.isIslandHovered = hovering
                    if hovering {
                        cancelCollapse()
                        ScreenManager.shared.cancelEdgeHideTimer(edge: edge)
                    } else if !isDragging && isExpanded {
                        scheduleCollapse()
                        scheduleVolumeClose()
                        ScreenManager.shared.scheduleEdgeHideTimer(edge: edge)
                    }
                }
            }
            .frame(width: 312, alignment: edge == .right ? .trailing : .leading)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.95, anchor: edge == .right ? .bottomTrailing : .bottomLeading).combined(with: .opacity),
                removal: .scale(scale: 0.95, anchor: edge == .right ? .bottomTrailing : .bottomLeading).combined(with: .opacity)
            ))
            .animation(.spring(response: 0.30, dampingFraction: 0.80), value: interactionState.isMediaExpanded)
        } else {
            // Mode A: Standard Baseline Vertical Edge Bar (Version 2.15.0 Experience)
            verticalBaselineColumn(tint: effectiveTint, secondaryTint: secondaryTint, isMuted: isMuted)
                .frame(width: sliderWidth, alignment: edge == .right ? .trailing : .leading)
                .transition(.opacity)
                .onHover { hovering in
                    if hovering {
                        cancelCollapse()
                        ScreenManager.shared.cancelEdgeHideTimer(edge: edge)
                    } else if !isDragging && isExpanded {
                        ScreenManager.shared.scheduleEdgeHideTimer(edge: edge)
                    }
                }
                .animation(.spring(response: 0.32, dampingFraction: 0.78), value: interactionState.isMediaExpanded)
        }
    }

    private var volumeButtonHoveredBinding: Binding<Bool> {
        Binding(
            get: { interactionState.isVolumeButtonHovered },
            set: { hovering in
                interactionState.isVolumeButtonHovered = hovering
                if hovering {
                    cancelCollapse()
                    cancelVolumeClose()
                    withAnimation(.easeInOut(duration: 0.18)) {
                        isVolumeColumnShowing = true
                        interactionState.isVolumeColumnVisible = true
                    }
                } else {
                    scheduleVolumeClose()
                }
            }
        )
    }

    // MARK: - Mode A: Baseline Vertical Glass Column

    @ViewBuilder
    private func verticalBaselineColumn(tint: Color, secondaryTint: Color, isMuted: Bool) -> some View {
        VStack(spacing: 6) {
            // Action Toggle Icon Button
            topActionButton(for: action, tint: tint, isMuted: isMuted)
                .padding(.top, 6)

            // Slider Track / Drawer Card
            if action == .scratchpad {
                scratchpadCard
                    .padding(.horizontal, 4)
                readoutLabel(for: action, isMuted: isMuted, tint: tint)
                    .padding(.bottom, 8)
            } else if action == .stashShelf {
                stashShelfCard
                    .padding(.horizontal, 4)
                readoutLabel(for: action, isMuted: isMuted, tint: tint)
                    .padding(.bottom, 8)
            } else {
                verticalSliderTrack(for: action, tint: tint, secondaryTint: secondaryTint, isMuted: isMuted, height: (shouldShowMediaIsland && nowPlaying.hasMedia) ? 110 : 138)
                    .padding(.horizontal, 4)
                readoutLabel(for: action, isMuted: isMuted, tint: tint)
                    .padding(.bottom, (shouldShowMediaIsland && nowPlaying.hasMedia) ? 2 : 8)
            }

            // Vertical Media Controls & Artwork (Shown when media is active)
            if shouldShowMediaIsland && nowPlaying.hasMedia {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.primary.opacity(0.18), Color.primary.opacity(0.03)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 34, height: 1)
                    .padding(.vertical, 2)

                verticalMediaControls

                artworkCapsuleThumbnail
                    .padding(.bottom, 6)
            }
        }
        .frame(width: sliderWidth)
        .liquidGlass(
            cornerRadius: 20,
            tint: tint,
            specularIntensity: 1.1,
            causticOpacity: 0.18,
            shadowRadius: 16,
            backdropOpacity: appState.settings.dialOpacity
        )
    }

    // MARK: - Mode B: Dropped-in Vertical Volume Slider (Matched Tint)

    @ViewBuilder
    private func verticalVolumeGlassColumn(tint: Color, secondaryTint: Color, isMuted: Bool) -> some View {
        VStack(spacing: 6) {
            topActionButton(for: .volume, tint: tint, isMuted: isMuted)
                .padding(.top, 6)

            verticalSliderTrack(for: .volume, tint: tint, secondaryTint: secondaryTint, isMuted: isMuted, height: 110)
                .padding(.horizontal, 4)

            readoutLabel(for: .volume, isMuted: isMuted, tint: tint)
                .padding(.bottom, 6)
        }
        .frame(width: sliderWidth)
        .liquidGlass(
            cornerRadius: 20,
            tint: tint,
            specularIntensity: 1.15,
            causticOpacity: 0.22,
            shadowRadius: 14,
            backdropOpacity: appState.settings.dialOpacity
        )
    }

    // MARK: - Action Top Button

    @ViewBuilder
    private func topActionButton(for targetAction: ControlAction, tint: Color, isMuted: Bool) -> some View {
        Button(action: {
            appState.toggleAction(targetAction, displayID: displayID)
        }) {
            Image(systemName: iconName(for: targetAction, isMuted: isMuted))
                .font(.system(size: 14.5, weight: .semibold))
                .foregroundStyle(
                    isMuted
                        ? AnyShapeStyle(Color.red)
                        : AnyShapeStyle(LinearGradient(colors: targetAction == .volume && nowPlaying.hasMedia ? [nowPlaying.artworkTint, nowPlaying.artworkSecondaryTint] : targetAction.accentColors, startPoint: .top, endPoint: .bottom))
                )
                .frame(width: 32, height: 32)
                .circularLiquidGlass(
                    tint: tint,
                    specularIntensity: 0.9,
                    causticOpacity: 0.18,
                    isHighlighted: isTopHovered
                )
                .scaleEffect(isTopHovered ? 1.06 : 1.0)
                .animation(.spring(response: 0.18, dampingFraction: 0.72), value: isTopHovered)
        }
        .buttonStyle(.plain)
        .onHover { isTopHovered = $0 }
        .help(topHelpText(for: targetAction, isMuted: isMuted))
    }

    // MARK: - Vertical Slider Track

    @ViewBuilder
    private func verticalSliderTrack(for targetAction: ControlAction, tint: Color, secondaryTint: Color, isMuted: Bool, height: CGFloat) -> some View {
        GeometryReader { geo in
            let trackH = max(1, geo.size.height)

            ZStack {
                LiquidVerticalTrack(
                    progress: Double(currentValue(for: targetAction)),
                    primaryTint: tint,
                    secondaryTint: secondaryTint,
                    trackWidth: 16,
                    isMuted: isMuted
                )

                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        interactionState.isSliderDragging = true
                        let progress = 1.0 - (gesture.location.y / trackH)
                        let clamped: Float
                        if targetAction == .keepAwake {
                            switch progress {
                            case ..<0.1: clamped = 0.0
                            case ..<0.3: clamped = 0.2
                            case ..<0.5: clamped = 0.4
                            case ..<0.7: clamped = 0.6
                            case ..<0.9: clamped = 0.8
                            default: clamped = 1.0
                            }
                        } else {
                            clamped = max(0.0, min(1.0, Float(progress)))
                        }
                        dragValue = clamped
                        if targetAction == action {
                            if edge == .left {
                                appState.liveLeftSliderValue = clamped
                            } else {
                                appState.liveRightSliderValue = clamped
                            }
                        }
                        if targetAction == .mediaPlayback {
                            nowPlaying.previewInteractiveScrub(toFraction: Double(clamped))
                        } else {
                            appState.setValue(for: targetAction, value: Double(clamped), displayID: displayID)
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                        interactionState.isSliderDragging = false
                        if targetAction == action {
                            if edge == .left {
                                appState.liveLeftSliderValue = nil
                            } else {
                                appState.liveRightSliderValue = nil
                            }
                        }
                        if targetAction == .mediaPlayback {
                            nowPlaying.previewInteractiveScrub(toFraction: Double(dragValue))
                            nowPlaying.commitInteractiveScrub()
                        }
                        appState.saveSettings()
                    }
            )
        }
        .frame(width: 48, height: height)
    }

    // MARK: - Vertical Media Transport Controls

    @ViewBuilder
    private var verticalMediaControls: some View {
        VStack(spacing: 6) {
            // Previous Track Button
            Button(action: { nowPlaying.previousTrack() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isPrevHovered ? .primary : .secondary)
                    .frame(width: 26, height: 20)
                    .circularLiquidGlass(tint: .clear, specularIntensity: 0.8, causticOpacity: 0.15, isHighlighted: isPrevHovered)
            }
            .buttonStyle(.plain)
            .help(appState.localized("corners.media.previous"))
            .onHover { isPrevHovered = $0 }

            // Play / Pause Toggle Button
            Button(action: { nowPlaying.togglePlayPause() }) {
                Image(systemName: nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)
                    .offset(x: nowPlaying.isPlaying ? 0 : 0.8)
                    .frame(width: 30, height: 28)
                    .circularLiquidGlass(
                        tint: nowPlaying.isPlaying ? nowPlaying.artworkTint : .clear,
                        specularIntensity: 1.2,
                        causticOpacity: 0.35,
                        isHighlighted: isPlayHovered
                    )
            }
            .buttonStyle(.plain)
            .help(nowPlaying.isPlaying ? appState.localized("corners.media.pause") : appState.localized("corners.media.play"))
            .onHover { isPlayHovered = $0 }

            // Next Track Button
            Button(action: { nowPlaying.nextTrack() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isNextHovered ? .primary : .secondary)
                    .frame(width: 26, height: 20)
                    .circularLiquidGlass(tint: .clear, specularIntensity: 0.8, causticOpacity: 0.15, isHighlighted: isNextHovered)
            }
            .buttonStyle(.plain)
            .help(appState.localized("corners.media.next"))
            .onHover { isNextHovered = $0 }
        }
    }

    // MARK: - Artwork Capsule Thumbnail

    @ViewBuilder
    private var artworkCapsuleThumbnail: some View {
        ZStack {
            if let artwork = nowPlaying.artworkImage {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(nowPlaying.isPlaying ? nowPlaying.artworkTint.opacity(0.65) : Color.white.opacity(0.20), lineWidth: 1.2)
                    )
                    .shadow(color: nowPlaying.isPlaying ? nowPlaying.artworkTint.opacity(0.40) : Color.black.opacity(0.30), radius: 5, x: 0, y: 2)
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(0.12))
                    .frame(width: 36, height: 36)
                    .overlay(Image(systemName: "music.note").font(.system(size: 13, weight: .semibold)).foregroundColor(.white.opacity(0.70)))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 1))
            }

            if nowPlaying.isPlaying {
                Circle()
                    .fill(nowPlaying.artworkTint)
                    .frame(width: 6, height: 6)
                    .shadow(color: nowPlaying.artworkTint, radius: 2)
                    .offset(x: 12, y: -12)
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            if hovering {
                cancelCollapse()
                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                    interactionState.isMediaExpanded = true
                }
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                interactionState.isMediaExpanded.toggle()
            }
        }
        .help(nowPlaying.hasMedia ? "\(nowPlaying.title) • \(nowPlaying.artist)" : appState.localized("edge.noMedia"))
    }

    // MARK: - Collapse & Volume Grace Timer Helpers

    private func cancelCollapse() {
        collapseWorkItem?.cancel()
        collapseWorkItem = nil
    }

    private func scheduleCollapse() {
        cancelCollapse()
        let item = DispatchWorkItem {
            Task { @MainActor in
                let activeScrub = nowPlaying.isInteractiveScrubbing
                if !isDragging && !interactionState.isVolumeColumnHovered && !interactionState.isVolumeButtonHovered && !interactionState.isIslandHovered && !activeScrub {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        interactionState.isMediaExpanded = false
                        isVolumeColumnShowing = false
                        interactionState.isVolumeColumnVisible = false
                    }
                }
            }
        }
        collapseWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.40, execute: item)
    }

    private func cancelVolumeClose() {
        volumeCloseWorkItem?.cancel()
        volumeCloseWorkItem = nil
    }

    private func scheduleVolumeClose() {
        cancelVolumeClose()
        let item = DispatchWorkItem {
            Task { @MainActor in
                if !isDragging && !interactionState.isVolumeButtonHovered && !interactionState.isVolumeColumnHovered && !interactionState.isIslandHovered {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        isVolumeColumnShowing = false
                        interactionState.isVolumeColumnVisible = false
                    }
                }
            }
        }
        volumeCloseWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: item)
    }

    // MARK: - Utility Drawer Cards

    @ViewBuilder
    private var scratchpadCard: some View {
        Button(action: {
            appState.toggleAction(.scratchpad, displayID: displayID)
        }) {
            VStack(spacing: 8) {
                Image(systemName: "note.text")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(LinearGradient(colors: action.accentColors, startPoint: .top, endPoint: .bottom))
                Text(appState.scratchpad.text.isEmpty ? appState.localized("dial.notes") : "\(appState.scratchpad.wordCount)w")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(appState.localized("corners.action.openScratchpad"))
                    .font(.system(size: 8.5, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 48, height: 144)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.06)))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var stashShelfCard: some View {
        Button(action: {
            appState.toggleAction(.stashShelf, displayID: displayID)
        }) {
            VStack(spacing: 8) {
                Image(systemName: "tray.2.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(LinearGradient(colors: action.accentColors, startPoint: .top, endPoint: .bottom))
                Text("\(appState.stashShelf.items.count)")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.primary)
                Text(appState.localized("corners.action.openShelf"))
                    .font(.system(size: 8.5, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 48, height: 144)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.06)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Readout & Metadata Helpers

    @ViewBuilder
    private func readoutLabel(for targetAction: ControlAction, isMuted: Bool, tint: Color = .primary) -> some View {
        if isMuted && targetAction == .volume {
            Text(appState.localized("dial.mute"))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.red)
        } else if targetAction == .timer {
            Text(appState.formattedTimerTime)
                .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .foregroundColor(.primary)
        } else if targetAction == .keepAwake {
            Text(appState.keepAwake.formattedRemaining)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(appState.keepAwake.isActive ? .orange : .secondary)
        } else if targetAction == .stashShelf {
            Text("\(appState.stashShelf.items.count)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .foregroundColor(.primary)
        } else if targetAction == .scratchpad {
            Text(appState.localized("dial.notes"))
                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        } else if targetAction == .mediaPlayback {
            Text(nowPlaying.formattedElapsedTime)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .foregroundColor(nowPlaying.hasMedia ? tint : .primary)
        } else {
            Text("\(Int(round(currentValue(for: targetAction) * 100)))%")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .foregroundColor(targetAction == .volume && nowPlaying.hasMedia ? tint : .primary)
        }
    }

    private func iconName(for targetAction: ControlAction, isMuted: Bool) -> String {
        if isMuted && targetAction == .volume { return "speaker.slash.fill" }
        if targetAction == .timer {
            return appState.isPomodoroRunning ? "pause.fill" : "play.fill"
        }
        if targetAction == .mediaPlayback {
            return nowPlaying.isPlaying ? "pause.fill" : "play.fill"
        }
        return targetAction.systemImage
    }

    private func topHelpText(for targetAction: ControlAction, isMuted: Bool) -> String {
        if targetAction == .volume {
            return isMuted ? appState.localized("menubar.unmute") : appState.localized("menubar.mute")
        }
        if targetAction == .timer {
            return appState.isPomodoroRunning ? appState.localized("menubar.pause") : appState.localized("menubar.start")
        }
        if targetAction == .mediaPlayback {
            return nowPlaying.isPlaying ? appState.localized("corners.media.pause") : appState.localized("corners.media.play")
        }
        return "\(targetAction.localizedDisplayName(using: appState.effectiveLanguage)) — \(appState.localized("edge.toggleAction"))"
    }
}
