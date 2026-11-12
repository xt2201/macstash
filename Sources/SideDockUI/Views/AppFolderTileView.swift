import SwiftUI
import AppKit
import SideDockCore
import MacStashCore
import MacStashDesignSystem

public struct AppFolderTileView: View {
    public let folder: AppFolderItem
    public let tileSize: CGFloat
    public let runningApps: [RunningAppInfo]
    public let badgesByBundleID: [String: String]
    public let onRemove: () -> Void

    @State private var showPopover: Bool = false

    public init(
        folder: AppFolderItem,
        tileSize: CGFloat,
        runningApps: [RunningAppInfo],
        badgesByBundleID: [String: String],
        onRemove: @escaping () -> Void
    ) {
        self.folder = folder
        self.tileSize = tileSize
        self.runningApps = runningApps
        self.badgesByBundleID = badgesByBundleID
        self.onRemove = onRemove
    }

    private var combinedBadge: String? {
        var total = 0
        var hasText = false
        for app in folder.apps {
            guard let badge = badgesByBundleID[app.bundleIdentifier], !badge.isEmpty else { continue }
            if let num = Int(badge) {
                total += num
            } else {
                hasText = true
            }
        }
        if total > 0 { return "\(total)" }
        return hasText ? "•" : nil
    }

    public var body: some View {
        Button {
            showPopover.toggle()
        } label: {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color.primary.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.14), lineWidth: 0.8)
                    )

                if let custom = folder.customIconPath,
                   FileManager.default.fileExists(atPath: custom),
                   let img = NSImage(contentsOfFile: custom) {
                    Image(nsImage: img)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: tileSize * 0.78, height: tileSize * 0.78)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                } else {
                    let miniSize = max(12, tileSize * 0.34)
                    LazyVGrid(columns: [GridItem(.fixed(miniSize), spacing: 3), GridItem(.fixed(miniSize), spacing: 3)], spacing: 3) {
                        ForEach(folder.apps.prefix(4)) { app in
                            Image(nsImage: iconForApp(app, size: miniSize))
                                .resizable()
                                .interpolation(.high)
                                .frame(width: miniSize, height: miniSize)
                                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                        }
                    }
                    .padding(4)
                }

                DockBadgeView(label: combinedBadge)
                    .offset(x: 4, y: -4)
            }
            .frame(width: tileSize, height: tileSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showPopover, arrowEdge: .top) {
            appFolderPopover
        }
        .contextMenu {
            Button(LocalizationService.shared.localized("dock.remove")) {
                onRemove()
            }
        }
    }

    private var appFolderPopover: some View {
        let pinnedIDs = Set(folder.apps.map(\.bundleIdentifier))
        let extraRunning = folder.showRunningAppsInline
            ? runningApps.filter { app in
                guard let bid = app.bundleIdentifier else { return false }
                return !pinnedIDs.contains(bid)
            }
            : []

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(folder.displayName)
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Text("\(folder.apps.count) apps")
                    .font(.system(size: 10.5))
                    .foregroundColor(.secondary)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 10)], spacing: 10) {
                ForEach(folder.apps) { app in
                    Button {
                        launchApp(app)
                        showPopover = false
                    } label: {
                        VStack(spacing: 4) {
                            ZStack(alignment: .topTrailing) {
                                Image(nsImage: iconForApp(app, size: 36))
                                    .resizable()
                                    .interpolation(.high)
                                    .frame(width: 36, height: 36)
                                DockBadgeView(label: badgesByBundleID[app.bundleIdentifier])
                                    .offset(x: 4, y: -4)
                            }
                            Text(app.displayName)
                                .font(.system(size: 10.5, weight: .medium))
                                .lineLimit(1)
                        }
                        .frame(width: 62)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            if !extraRunning.isEmpty {
                Divider()
                Text("Running Workspace")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(extraRunning.prefix(8)) { app in
                            Button {
                                if let url = app.bundleURL {
                                    NSWorkspace.shared.open(url)
                                    showPopover = false
                                }
                            } label: {
                                VStack(spacing: 3) {
                                    if let url = app.bundleURL {
                                        Image(nsImage: AppIconCache.shared.icon(forPath: url.path, targetSize: NSSize(width: 28, height: 28)))
                                            .resizable()
                                            .frame(width: 28, height: 28)
                                    }
                                    Text(app.localizedName)
                                        .font(.system(size: 9.5))
                                        .lineLimit(1)
                                }
                                .frame(width: 52)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(width: 290)
    }

    private func iconForApp(_ app: AppItem, size: CGFloat) -> NSImage {
        let target = NSSize(width: size, height: size)
        if let custom = app.customIconPath,
           FileManager.default.fileExists(atPath: custom),
           let img = NSImage(contentsOfFile: custom) {
            return img
        }
        if FileManager.default.fileExists(atPath: app.appPath) {
            return AppIconCache.shared.icon(forPath: app.appPath, targetSize: target)
        }
        return AppIconCache.shared.icon(forBundleID: app.bundleIdentifier, targetSize: target)
            ?? NSImage(systemSymbolName: "app.fill", accessibilityDescription: app.displayName)
            ?? NSImage()
    }

    private func launchApp(_ app: AppItem) {
        if FileManager.default.fileExists(atPath: app.appPath) {
            NSWorkspace.shared.open(URL(fileURLWithPath: app.appPath))
        } else if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleIdentifier) {
            NSWorkspace.shared.open(url)
        }
    }
}
