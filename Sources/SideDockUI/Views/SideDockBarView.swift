import SwiftUI
import AppKit
import UniformTypeIdentifiers
import SideDockCore
import SideDockWidgets
import MacStashCore
import MacStashDesignSystem

public struct SideDockBarView: View {
    public let profile: DockProfile
    public let profiles: [DockProfile]
    public let runningApps: [RunningAppInfo]
    public let runtimeState: DockRuntimeState
    public let callbacks: DockInteractionCallbacks

    @State private var isDraggingDock: Bool = false
    @State private var cursorAxisPos: CGFloat? = nil
    @State private var tileCenters: [UUID: CGFloat] = [:]
    @State private var runningCenters: [pid_t: CGFloat] = [:]
    @State private var draggedItemID: UUID? = nil
    @State private var runningWindowRects: [pid_t: CGRect] = [:]

    private let magnificationEngine = DockMagnificationEngine()

    public init(
        profile: DockProfile,
        profiles: [DockProfile],
        runningApps: [RunningAppInfo] = [],
        runtimeState: DockRuntimeState = DockRuntimeState(),
        callbacks: DockInteractionCallbacks
    ) {
        self.profile = profile
        self.profiles = profiles
        self.runningApps = runningApps
        self.runtimeState = runtimeState
        self.callbacks = callbacks
    }

    private func localized(_ key: String) -> String {
        LocalizationService.shared.localized(key)
    }

    private var baseTileSize: CGFloat {
        CGFloat(profile.layoutConfig.baseTileSize * profile.layoutConfig.scale)
    }

    private var tileSpacing: CGFloat {
        CGFloat(profile.layoutConfig.tileSpacing * profile.layoutConfig.scale)
    }

    private var placement: DockPlacement { profile.layoutConfig.placement }
    private var isVertical: Bool { placement.isVertical }

    private var pinnedBundleIDs: Set<String> {
        Set(profile.items.compactMap { item in
            if case .app(let app) = item { return app.bundleIdentifier }
            return nil
        })
    }

    private var unpinnedRunningApps: [RunningAppInfo] {
        let hidden = Set(profile.layoutConfig.hiddenRunningBundleIDs)
        return runningApps.filter { app in
            guard let bid = app.bundleIdentifier else { return true }
            return !pinnedBundleIDs.contains(bid) && !hidden.contains(bid)
        }
    }

    private var runningByBundleID: [String: RunningAppInfo] {
        var map: [String: RunningAppInfo] = [:]
        for app in runningApps {
            if let bid = app.bundleIdentifier { map[bid] = app }
        }
        return map
    }

    public var body: some View {
        Group {
            if isVertical {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: tileSpacing) { barItemsContent }
                        .padding(.vertical, 4)
                }
                .frame(maxHeight: 720)
            } else {
                HStack(spacing: tileSpacing) { barItemsContent }
            }
        }
        .padding(.horizontal, isVertical ? 8 : 12)
        .padding(.vertical, isVertical ? 12 : 8)
        .background(SideDockGlassBackdrop(theme: profile.theme))
        .padding(headroomEdgeInsets)
        .coordinateSpace(name: "SideDockBar")
        .onContinuousHover(coordinateSpace: .named("SideDockBar")) { phase in
            switch phase {
            case .active(let loc):
                cursorAxisPos = isVertical ? loc.y : loc.x
            case .ended:
                cursorAxisPos = nil
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            DockTileActions.extractDroppedURLs(from: providers) { urls in
                callbacks.onDropExternalURLs(urls, nil)
            }
            return true
        }
        .contextMenu {
            Button(runtimeState.isEditMode ? localized("dock.doneEditing") : localized("dock.editDock")) {
                callbacks.onToggleEditMode()
            }
            Button(localized("dock.openLaunchpad")) {
                callbacks.onOpenLaunchpad()
            }
            Divider()
            Button(localized("dock.manageProfiles")) {
                callbacks.onOpenSettings()
            }
        }
    }

    private var headroomEdgeInsets: EdgeInsets {
        let headroom: CGFloat = profile.layoutConfig.magnificationEnabled ? 16 : 6
        switch placement {
        case .fixedBottom, .floating: return EdgeInsets(top: headroom, leading: 6, bottom: 0, trailing: 6)
        case .fixedTop: return EdgeInsets(top: 0, leading: 6, bottom: headroom, trailing: 6)
        case .fixedLeft: return EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: headroom)
        case .fixedRight: return EdgeInsets(top: 6, leading: headroom, bottom: 6, trailing: 0)
        }
    }

    @ViewBuilder
    private var barItemsContent: some View {
        if placement == .floating { dragHandle }

        if profile.layoutConfig.showProfileSwitcher && profiles.count > 1 {
            profileSwitcherMenu
        }

        if runtimeState.isEditMode {
            editModeToolbar
        }

        ForEach(profile.items) { item in
            tileRow(for: item)
        }

        if profile.layoutConfig.showRunningApps && !unpinnedRunningApps.isEmpty {
            sectionDivider
            ForEach(unpinnedRunningApps.prefix(10)) { app in
                runningAppButton(app)
            }
        }

        if profile.layoutConfig.showMinimizedWindows && !runtimeState.minimizedWindows.isEmpty {
            sectionDivider
            ForEach(runtimeState.minimizedWindows.prefix(6)) { win in
                minimizedWindowButton(win)
            }
        }
    }

    private var editModeToolbar: some View {
        HStack(spacing: 4) {
            Menu {
                Button(localized("dock.addSeparator")) { callbacks.onAddQuickItem(.separator(UUID())) }
                Button("Add Spacer") { callbacks.onAddQuickItem(.spacer(UUID(), 20)) }
                Button("Add Launchpad") { callbacks.onAddQuickItem(.launchpad(UUID())) }
                Button("Add Trash") { callbacks.onAddQuickItem(.trash(UUID())) }
                Divider()
                Button(localized("dock.manageProfiles")) { callbacks.onOpenSettings() }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.accentColor)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            Button {
                callbacks.onToggleEditMode()
            } label: {
                Text(localized("dock.done"))
                    .font(.system(size: 10.5, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.accentColor))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func tileRow(for item: DockItem) -> some View {
        let runningInfo: RunningAppInfo? = {
            if case .app(let app) = item { return runningByBundleID[app.bundleIdentifier] }
            return nil
        }()
        let badge: String? = {
            guard profile.layoutConfig.showNotificationBadges else { return nil }
            if case .app(let app) = item { return runtimeState.badgesByBundleID[app.bundleIdentifier] }
            return nil
        }()
        let scale = magnificationScale(for: item)
        let lift = magnificationEngine.liftOffset(scale: scale, baseTileSize: baseTileSize)

        DockTileView(
            item: item,
            placement: placement,
            baseTileSize: baseTileSize,
            tileSpacing: tileSpacing,
            magnificationScale: scale,
            liftOffset: lift,
            isRunning: runningInfo != nil,
            isActiveApp: runningInfo?.isActive ?? false,
            badgeLabel: badge,
            indicatorStyle: profile.theme.indicatorStyle,
            showTooltips: profile.layoutConfig.showTooltips,
            isEditMode: runtimeState.isEditMode,
            isBouncing: runtimeState.bouncingItemID == item.id,
            trashItemCount: runtimeState.trashItemCount,
            reduceMotion: profile.theme.reduceMotion,
            runningApps: runningApps,
            badgesByBundleID: runtimeState.badgesByBundleID,
            callbacks: callbacks
        )
        .background(
            GeometryReader { geo in
                let frame = geo.frame(in: .named("SideDockBar"))
                let center = isVertical ? frame.midY : frame.midX
                Color.clear
                    .onAppear { tileCenters[item.id] = center }
                    .onChange(of: center) { _, newCenter in tileCenters[item.id] = newCenter }
            }
        )
        .onDrag {
            draggedItemID = item.id
            return NSItemProvider(object: item.id.uuidString as NSString)
        }
        .onDrop(of: [.text, .fileURL], delegate: DockTileDropDelegate(
            targetID: item.id,
            draggedID: $draggedItemID,
            onMoveItem: callbacks.onMoveItem,
            onDropURLs: { urls in
                let targetIdx = profile.items.firstIndex(where: { $0.id == item.id })
                callbacks.onDropExternalURLs(urls, targetIdx)
            }
        ))
    }

    private func magnificationScale(for item: DockItem) -> CGFloat {
        guard profile.layoutConfig.magnificationEnabled,
              !profile.theme.reduceMotion,
              item.isInteractive else { return 1.0 }
        switch item {
        case .widget, .smartStack: return 1.0
        default: break
        }
        guard let center = tileCenters[item.id] else { return 1.0 }
        return magnificationEngine.scaleFactor(
            tileCenter: center,
            cursorAxisPosition: cursorAxisPos,
            baseTileSize: baseTileSize,
            maxMagnification: profile.layoutConfig.magnificationScale
        )
    }

    private func runningMagnificationScale(for pid: pid_t) -> CGFloat {
        guard profile.layoutConfig.magnificationEnabled,
              !profile.theme.reduceMotion,
              let center = runningCenters[pid] else { return 1.0 }
        return magnificationEngine.scaleFactor(
            tileCenter: center,
            cursorAxisPosition: cursorAxisPos,
            baseTileSize: baseTileSize,
            maxMagnification: profile.layoutConfig.magnificationScale
        )
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.18))
            .frame(width: isVertical ? baseTileSize * 0.6 : 1, height: isVertical ? 1 : baseTileSize * 0.6)
            .padding(isVertical ? .vertical : .horizontal, 2)
    }

    private var dragHandle: some View {
        Image(systemName: isVertical ? "line.3.horizontal" : "ellipsis")
            .rotationEffect(isVertical ? .zero : .degrees(90))
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.secondary.opacity(0.8))
            .frame(width: isVertical ? 44 : 16, height: isVertical ? 16 : 44)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(isDraggingDock ? 0.14 : 0.05))
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { _ in
                        if !isDraggingDock {
                            isDraggingDock = true
                            callbacks.onDragBegin?()
                        } else {
                            callbacks.onDragUpdate?()
                        }
                    }
                    .onEnded { _ in
                        isDraggingDock = false
                        callbacks.onDragEnd?()
                    }
            )
            .help(localized("dock.dragToMove"))
    }

    private var profileSwitcherMenu: some View {
        Menu {
            ForEach(profiles) { prof in
                Button { callbacks.onSelectProfile(prof.id) } label: {
                    HStack {
                        Text(prof.name)
                        if prof.id == profile.id { Image(systemName: "checkmark") }
                    }
                }
            }
            Divider()
            Button(localized("dock.manageProfiles")) { callbacks.onOpenSettings() }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "square.stack.3d.up.fill").font(.system(size: 10))
                Text(profile.name).font(.system(size: 10.5, weight: .semibold))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.primary.opacity(0.08)))
            .overlay(Capsule().strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.6))
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private func runningAppButton(_ app: RunningAppInfo) -> some View {
        let scale = runningMagnificationScale(for: app.processIdentifier)
        let lift = magnificationEngine.liftOffset(scale: scale, baseTileSize: baseTileSize)
        let effective = baseTileSize * scale
        let iconSize = effective * 0.84
        let badge = profile.layoutConfig.showNotificationBadges
            ? (app.bundleIdentifier.flatMap { runtimeState.badgesByBundleID[$0] })
            : nil
        let rect = runningWindowRects[app.processIdentifier] ?? .zero
        let offsetSize: CGSize = {
            switch placement {
            case .fixedBottom, .floating: return CGSize(width: 0, height: -lift)
            case .fixedTop: return CGSize(width: 0, height: lift)
            case .fixedLeft: return CGSize(width: lift, height: 0)
            case .fixedRight: return CGSize(width: -lift, height: 0)
            }
        }()

        return Button {
            if let url = app.bundleURL { NSWorkspace.shared.open(url) }
        } label: {
            VStack(spacing: 3) {
                ZStack(alignment: .topTrailing) {
                    if let url = app.bundleURL {
                        Image(nsImage: AppIconCache.shared.icon(forPath: url.path, targetSize: NSSize(width: iconSize, height: iconSize)))
                            .resizable()
                            .interpolation(.high)
                            .frame(width: iconSize, height: iconSize)
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    } else {
                        Image(systemName: "app.fill").frame(width: iconSize, height: iconSize)
                    }
                    DockBadgeView(label: badge).offset(x: 4, y: -4)
                }
                .frame(width: effective, height: effective)

                DockRunningIndicatorView(
                    isRunning: true,
                    isActive: app.isActive,
                    style: profile.theme.indicatorStyle,
                    isVertical: isVertical
                )
            }
            .offset(offsetSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            GeometryReader { geo in
                let barFrame = geo.frame(in: .named("SideDockBar"))
                let center = isVertical ? barFrame.midY : barFrame.midX
                Color.clear
                    .onAppear {
                        runningWindowRects[app.processIdentifier] = geo.frame(in: .global)
                        runningCenters[app.processIdentifier] = center
                    }
                    .onChange(of: geo.frame(in: .global)) { _, newRect in
                        runningWindowRects[app.processIdentifier] = newRect
                        runningCenters[app.processIdentifier] = center
                    }
            }
        )
        .onHover { hovered in
            if hovered {
                if profile.layoutConfig.showTooltips {
                    callbacks.onHoverTooltipChanged(app.localizedName, rect)
                }
                callbacks.onHoverAppChanged(app.bundleIdentifier, app.localizedName, rect)
            } else {
                callbacks.onHoverTooltipChanged(nil, nil)
                callbacks.onHoverAppChanged(nil, nil, nil)
            }
        }
        .contextMenu {
            let bid = app.bundleIdentifier ?? ""
            let path = app.bundleURL?.path ?? ""
            AppTileContextMenuContent(
                bundleID: bid,
                displayName: app.localizedName,
                appPath: path,
                isPinned: false,
                isRunning: true,
                isEditMode: runtimeState.isEditMode,
                onOpen: { if let url = app.bundleURL { NSWorkspace.shared.open(url) } },
                onShowInFinder: { if !path.isEmpty { NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "") } },
                onShowAllWindows: { callbacks.onShowAppWindows(bid, app.localizedName, rect) },
                onKeepInDock: { callbacks.onPinRunningApp(app) },
                onHide: { NSRunningApplication(processIdentifier: app.processIdentifier)?.hide() },
                onHideOthers: { callbacks.onHideOtherApps(bid) },
                onQuit: { NSRunningApplication(processIdentifier: app.processIdentifier)?.terminate() },
                onForceQuit: { NSRunningApplication(processIdentifier: app.processIdentifier)?.forceTerminate() },
                onExecuteCuratedAction: { callbacks.onExecuteAction($0) },
                onHideFromRunningApps: !bid.isEmpty ? { callbacks.onHideRunningApp(bid) } : nil,
                onToggleEditMode: callbacks.onToggleEditMode
            )
        }
    }

    private func minimizedWindowButton(_ win: MinimizedWindowSummary) -> some View {
        Button {
            callbacks.onRestoreMinimizedWindow(win)
        } label: {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: baseTileSize * 0.88, height: baseTileSize * 0.88)
                    .overlay(
                        Image(systemName: "macwindow")
                            .font(.system(size: baseTileSize * 0.38))
                            .foregroundColor(.secondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.14), lineWidth: 0.7)
                    )

                if let path = win.appPath {
                    Image(nsImage: AppIconCache.shared.icon(forPath: path, targetSize: NSSize(width: 16, height: 16)))
                        .resizable()
                        .frame(width: 16, height: 16)
                        .offset(x: 2, y: 2)
                }
            }
            .frame(width: baseTileSize, height: baseTileSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered in
            if hovered && profile.layoutConfig.showTooltips {
                callbacks.onHoverTooltipChanged(win.windowTitle.isEmpty ? win.appName : win.windowTitle, .zero)
            } else {
                callbacks.onHoverTooltipChanged(nil, nil)
            }
        }
    }
}

private struct DockTileDropDelegate: DropDelegate {
    let targetID: UUID
    @Binding var draggedID: UUID?
    let onMoveItem: (UUID, UUID) -> Void
    let onDropURLs: ([URL]) -> Void

    func dropEntered(info: DropInfo) {
        guard let dragged = draggedID, dragged != targetID else { return }
        onMoveItem(dragged, targetID)
    }

    func performDrop(info: DropInfo) -> Bool {
        if draggedID != nil {
            draggedID = nil
            return true
        }
        let providers = info.itemProviders(for: [.fileURL])
        guard !providers.isEmpty else { return false }
        DockTileActions.extractDroppedURLs(from: providers) { urls in
            onDropURLs(urls)
        }
        return true
    }
}
