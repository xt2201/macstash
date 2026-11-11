import SwiftUI
import AppKit
import SideDockCore
import SideDockWidgets
import MacStashCore

public struct SideDockBarView: View {
    public let profile: DockProfile
    public let profiles: [DockProfile]
    public let runningApps: [RunningAppInfo]
    public let onSelectProfile: (UUID) -> Void
    public let onRemoveItem: (UUID) -> Void
    public let onResizeWidget: (UUID, WidgetSize) -> Void
    public let onDragBegin: (() -> Void)?
    public let onDragUpdate: (() -> Void)?
    public let onDragEnd: (() -> Void)?
    public let onOpenSettings: () -> Void

    @State private var isDraggingDock: Bool = false

    private func localized(_ key: String) -> String {
        LocalizationService.shared.localized(key)
    }

    public init(
        profile: DockProfile,
        profiles: [DockProfile],
        runningApps: [RunningAppInfo] = [],
        onSelectProfile: @escaping (UUID) -> Void,
        onRemoveItem: @escaping (UUID) -> Void,
        onResizeWidget: @escaping (UUID, WidgetSize) -> Void,
        onDragBegin: (() -> Void)? = nil,
        onDragUpdate: (() -> Void)? = nil,
        onDragEnd: (() -> Void)? = nil,
        onOpenSettings: @escaping () -> Void
    ) {
        self.profile = profile
        self.profiles = profiles
        self.runningApps = runningApps
        self.onSelectProfile = onSelectProfile
        self.onRemoveItem = onRemoveItem
        self.onResizeWidget = onResizeWidget
        self.onDragBegin = onDragBegin
        self.onDragUpdate = onDragUpdate
        self.onDragEnd = onDragEnd
        self.onOpenSettings = onOpenSettings
    }

    private var pinnedBundleIDs: Set<String> {
        Set(profile.items.compactMap { item in
            if case .app(let app) = item { return app.bundleIdentifier }
            return nil
        })
    }

    private var unpinnedRunningApps: [RunningAppInfo] {
        runningApps.filter { app in
            guard let bid = app.bundleIdentifier else { return true }
            return !pinnedBundleIDs.contains(bid)
        }
    }

    private var runningBundleIDs: Set<String> {
        Set(runningApps.compactMap(\.bundleIdentifier))
    }

    public var body: some View {
        Group {
            if profile.layoutConfig.placement.isVertical {
                verticalBarContent
            } else {
                horizontalBarContent
            }
        }
        .padding(.horizontal, profile.layoutConfig.placement.isVertical ? 8 : 12)
        .padding(.vertical, profile.layoutConfig.placement.isVertical ? 12 : 7)
        .background(SideDockGlassBackdrop(theme: profile.theme))
        .scaleEffect(CGFloat(profile.layoutConfig.scale))
    }

    private var horizontalBarContent: some View {
        HStack(spacing: CGFloat(profile.layoutConfig.tileSpacing)) {
            if profile.layoutConfig.placement == .floating {
                dragHandle(isVertical: false)
            }

            if profile.layoutConfig.showProfileSwitcher && profiles.count > 1 {
                profileSwitcherMenu
            }

            ForEach(profile.items) { item in
                let running: Bool = {
                    if case .app(let app) = item { return runningBundleIDs.contains(app.bundleIdentifier) }
                    return false
                }()
                DockTileView(
                    item: item,
                    isVertical: false,
                    isRunning: running,
                    reduceMotion: profile.theme.reduceMotion,
                    onRemove: { onRemoveItem(item.id) },
                    onResize: { newSize in onResizeWidget(item.id, newSize) },
                    onConfigure: onOpenSettings
                )
            }

            if profile.layoutConfig.showRunningApps && !unpinnedRunningApps.isEmpty {
                Rectangle()
                    .fill(Color.primary.opacity(0.18))
                    .frame(width: 1, height: 26)
                    .padding(.horizontal, 2)

                ForEach(unpinnedRunningApps.prefix(8)) { app in
                    runningAppButton(app)
                }
            }
        }
    }

    private var verticalBarContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: CGFloat(profile.layoutConfig.tileSpacing)) {
                if profile.layoutConfig.placement == .floating {
                    dragHandle(isVertical: true)
                }

                if profile.layoutConfig.showProfileSwitcher && profiles.count > 1 {
                    profileSwitcherMenu
                }

                ForEach(profile.items) { item in
                    let running: Bool = {
                        if case .app(let app) = item { return runningBundleIDs.contains(app.bundleIdentifier) }
                        return false
                    }()
                    DockTileView(
                        item: item,
                        isVertical: true,
                        isRunning: running,
                        reduceMotion: profile.theme.reduceMotion,
                        onRemove: { onRemoveItem(item.id) },
                        onResize: { newSize in onResizeWidget(item.id, newSize) },
                        onConfigure: onOpenSettings
                    )
                }

                if profile.layoutConfig.showRunningApps && !unpinnedRunningApps.isEmpty {
                    Rectangle()
                        .fill(Color.primary.opacity(0.18))
                        .frame(width: 26, height: 1)
                        .padding(.vertical, 2)

                    ForEach(unpinnedRunningApps.prefix(8)) { app in
                        runningAppButton(app)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxHeight: 700)
    }

    private func dragHandle(isVertical: Bool) -> some View {
        Image(systemName: isVertical ? "line.3.horizontal" : "ellipsis")
            .rotationEffect(isVertical ? .zero : .degrees(90))
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.secondary.opacity(0.8))
            .frame(width: isVertical ? 44 : 16, height: isVertical ? 16 : 44)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(isDraggingDock ? 0.12 : 0.04))
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { _ in
                        if !isDraggingDock {
                            isDraggingDock = true
                            onDragBegin?()
                        } else {
                            onDragUpdate?()
                        }
                    }
                    .onEnded { _ in
                        isDraggingDock = false
                        onDragEnd?()
                    }
            )
            .help(localized("dock.dragToMove"))
    }

    private var profileSwitcherMenu: some View {
        Menu {
            ForEach(profiles) { prof in
                Button {
                    onSelectProfile(prof.id)
                } label: {
                    HStack {
                        Text(prof.name)
                        if prof.id == profile.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            Divider()
            Button(localized("dock.manageProfiles")) {
                onOpenSettings()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 10))
                Text(profile.name)
                    .font(.system(size: 10.5, weight: .semibold))
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
        Button {
            if let url = app.bundleURL {
                NSWorkspace.shared.open(url)
            }
        } label: {
            VStack(spacing: 2) {
                if let url = app.bundleURL {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "app.fill")
                        .frame(width: 32, height: 32)
                }

                Circle()
                    .fill(Color.primary.opacity(0.8))
                    .frame(width: 4, height: 4)
            }
            .frame(width: 40, height: 46)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(app.localizedName)
    }
}
