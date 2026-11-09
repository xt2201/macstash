import SwiftUI
import AppKit
import SideDockCore
import SideDockWidgets

public struct SideDockBarView: View {
    public let profile: DockProfile
    public let profiles: [DockProfile]
    public let runningApps: [RunningAppInfo]
    public let onSelectProfile: (UUID) -> Void
    public let onRemoveItem: (UUID) -> Void
    public let onResizeWidget: (UUID, WidgetSize) -> Void
    public let onDragFloating: (CGPoint) -> Void
    public let onOpenSettings: () -> Void

    public init(
        profile: DockProfile,
        profiles: [DockProfile],
        runningApps: [RunningAppInfo] = [],
        onSelectProfile: @escaping (UUID) -> Void,
        onRemoveItem: @escaping (UUID) -> Void,
        onResizeWidget: @escaping (UUID, WidgetSize) -> Void,
        onDragFloating: @escaping (CGPoint) -> Void,
        onOpenSettings: @escaping () -> Void
    ) {
        self.profile = profile
        self.profiles = profiles
        self.runningApps = runningApps
        self.onSelectProfile = onSelectProfile
        self.onRemoveItem = onRemoveItem
        self.onResizeWidget = onResizeWidget
        self.onDragFloating = onDragFloating
        self.onOpenSettings = onOpenSettings
    }

    public var body: some View {
        Group {
            if profile.layoutConfig.placement.isVertical {
                verticalBarContent
            } else {
                horizontalBarContent
            }
        }
        .padding(.horizontal, profile.layoutConfig.placement.isVertical ? 6 : 10)
        .padding(.vertical, profile.layoutConfig.placement.isVertical ? 10 : 6)
        .background(SideDockGlassBackdrop(theme: profile.theme))
        .scaleEffect(CGFloat(profile.layoutConfig.scale))
    }

    private var horizontalBarContent: some View {
        HStack(spacing: CGFloat(profile.layoutConfig.tileSpacing)) {
            // Drag Handle for Floating Layout
            if profile.layoutConfig.placement == .floating {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.7))
                    .frame(width: 14, height: 44)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 1)
                            .onChanged { value in
                                onDragFloating(value.location)
                            }
                    )
                    .help("Drag to move dock")
            }

            // Profile Switcher Pill
            if profile.layoutConfig.showProfileSwitcher && profiles.count > 1 {
                profileSwitcherMenu
            }

            // Dock Items (Apps, Folders, Widgets, Separators)
            ForEach(profile.items) { item in
                DockTileView(
                    item: item,
                    onRemove: { onRemoveItem(item.id) },
                    onResize: { newSize in onResizeWidget(item.id, newSize) }
                )
            }

            // Running Apps Section
            if profile.layoutConfig.showRunningApps && !runningApps.isEmpty {
                Rectangle()
                    .fill(Color.primary.opacity(0.18))
                    .frame(width: 1, height: 26)
                    .padding(.horizontal, 2)

                ForEach(runningApps.prefix(8)) { app in
                    runningAppButton(app)
                }
            }
        }
    }

    private var verticalBarContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: CGFloat(profile.layoutConfig.tileSpacing)) {
                // Drag Handle for Floating Layout
                if profile.layoutConfig.placement == .floating {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.7))
                        .frame(width: 44, height: 14)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 1)
                                .onChanged { value in
                                    onDragFloating(value.location)
                                }
                        )
                        .help("Drag to move dock")
                }

                // Profile Switcher Pill
                if profile.layoutConfig.showProfileSwitcher && profiles.count > 1 {
                    profileSwitcherMenu
                }

                // Dock Items (Apps, Folders, Widgets, Separators)
                ForEach(profile.items) { item in
                    DockTileView(
                        item: item,
                        onRemove: { onRemoveItem(item.id) },
                        onResize: { newSize in onResizeWidget(item.id, newSize) }
                    )
                }

                // Running Apps Section
                if profile.layoutConfig.showRunningApps && !runningApps.isEmpty {
                    Rectangle()
                        .fill(Color.primary.opacity(0.18))
                        .frame(width: 26, height: 1)
                        .padding(.vertical, 2)

                    ForEach(runningApps.prefix(8)) { app in
                        runningAppButton(app)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxHeight: 700)
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
            Button("Manage Profiles...") {
                onOpenSettings()
            }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 10))
                Text(profile.name)
                    .font(.system(size: 10, weight: .semibold))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.primary.opacity(0.08)))
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

                // Running indicator dot
                Circle()
                    .fill(Color.primary.opacity(0.8))
                    .frame(width: 4, height: 4)
            }
            .frame(width: 38, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(app.localizedName)
    }
}
