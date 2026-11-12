import AppKit
import SwiftUI
import SideDockCore
import MacStashDesignSystem

@MainActor
public final class WindowPreviewPanelController {
    private var panel: NSPanel?
    private var hoverOpenTask: Task<Void, Never>?
    private var hideTimer: Timer?
    private var isPointerInsidePanel: Bool = false
    private let layoutEngine = DockLayoutEngine()

    public init() {}

    public func handleAppHover(
        bundleID: String?,
        appName: String?,
        anchorScreenRect: CGRect?,
        placement: DockPlacement,
        screenVisibleFrame: CGRect,
        delaySeconds: Double,
        immediate: Bool = false
    ) {
        hoverOpenTask?.cancel()

        guard let bundleID, let anchor = anchorScreenRect, anchor != .zero else {
            scheduleHide()
            return
        }

        hideTimer?.invalidate()
        hideTimer = nil

        hoverOpenTask = Task { [weak self] in
            if !immediate {
                let nanos = UInt64(max(0.08, delaySeconds) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanos)
            }
            guard !Task.isCancelled, let self else { return }
            await self.presentPreviews(
                bundleID: bundleID,
                appName: appName ?? "App",
                anchorScreenRect: anchor,
                placement: placement,
                screenVisibleFrame: screenVisibleFrame
            )
        }
    }

    public func hideImmediately() {
        hoverOpenTask?.cancel()
        hideTimer?.invalidate()
        hideTimer = nil
        WindowHighlightOverlay.shared.hide()
        panel?.orderOut(nil)
    }

    private func scheduleHide() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self, !self.isPointerInsidePanel else { return }
                self.hideImmediately()
            }
        }
    }

    private func presentPreviews(
        bundleID: String,
        appName: String,
        anchorScreenRect: CGRect,
        placement: DockPlacement,
        screenVisibleFrame: CGRect
    ) async {
        let windows = WindowRegistryService.shared.windows(forBundleID: bundleID)
        guard !windows.isEmpty else {
            hideImmediately()
            return
        }

        var thumbnails: [CGWindowID: NSImage] = [:]
        for win in windows.prefix(6) {
            if let img = await WindowRegistryService.shared.captureThumbnail(for: win) {
                thumbnails[win.windowID] = img
            }
        }

        let content = WindowPreviewStripView(
            appName: appName,
            windows: Array(windows.prefix(6)),
            thumbnails: thumbnails,
            onHoverCard: { hovered in
                self.isPointerInsidePanel = hovered != nil
                if let win = hovered {
                    WindowHighlightOverlay.shared.highlight(cgWindowFrame: win.frame)
                } else {
                    WindowHighlightOverlay.shared.hide()
                }
            },
            onSelectWindow: { win in
                WindowRegistryService.shared.focusWindow(win)
                self.hideImmediately()
            },
            onMinimizeWindow: { win in
                WindowRegistryService.shared.minimizeWindow(win)
                self.hideImmediately()
            },
            onCloseWindow: { win in
                WindowRegistryService.shared.closeWindow(win)
                self.hideImmediately()
            }
        )
        .padding(8)

        let host = NSHostingView(rootView: content)
        host.layoutSubtreeIfNeeded()
        let size = host.fittingSize
        let origin = layoutEngine.calculateAnchoredPopoverOrigin(
            anchorRect: anchorScreenRect,
            popoverSize: size,
            placement: placement,
            visibleFrame: screenVisibleFrame,
            gap: 10.0
        )

        if panel == nil {
            let p = NSPanel(
                contentRect: CGRect(origin: origin, size: size),
                styleMask: [.nonactivatingPanel, .borderless],
                backing: .buffered,
                defer: false
            )
            p.isOpaque = false
            p.backgroundColor = .clear
            p.hasShadow = true
            p.level = .popUpMenu
            p.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle, .fullScreenAuxiliary]
            panel = p
        }

        panel?.contentView = host
        panel?.setFrame(CGRect(origin: origin, size: size), display: true)
        panel?.orderFrontRegardless()
    }
}

private struct WindowPreviewStripView: View {
    let appName: String
    let windows: [DockWindowInfo]
    let thumbnails: [CGWindowID: NSImage]
    let onHoverCard: (DockWindowInfo?) -> Void
    let onSelectWindow: (DockWindowInfo) -> Void
    let onMinimizeWindow: (DockWindowInfo) -> Void
    let onCloseWindow: (DockWindowInfo) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(windows) { win in
                WindowPreviewCard(
                    appName: appName,
                    window: win,
                    thumbnail: thumbnails[win.windowID],
                    onHover: { inside in onHoverCard(inside ? win : nil) },
                    onSelect: { onSelectWindow(win) },
                    onMinimize: { onMinimizeWindow(win) },
                    onClose: { onCloseWindow(win) }
                )
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThickMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.16), lineWidth: 0.8)
        )
    }
}

private struct WindowPreviewCard: View {
    let appName: String
    let window: DockWindowInfo
    let thumbnail: NSImage?
    let onHover: (Bool) -> Void
    let onSelect: () -> Void
    let onMinimize: () -> Void
    let onClose: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                if let path = window.appPath {
                    Image(nsImage: AppIconCache.shared.icon(forPath: path, targetSize: NSSize(width: 14, height: 14)))
                        .resizable()
                        .frame(width: 14, height: 14)
                }
                Text(window.title.isEmpty ? appName : window.title)
                    .font(.system(size: 10.5, weight: .semibold))
                    .lineLimit(1)
                Spacer()

                if isHovered {
                    Button(action: onMinimize) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.yellow)
                    }
                    .buttonStyle(.plain)

                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            Button(action: onSelect) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.primary.opacity(0.08))

                    if let thumb = thumbnail {
                        Image(nsImage: thumb)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else if let path = window.appPath {
                        VStack(spacing: 4) {
                            Image(nsImage: AppIconCache.shared.icon(forPath: path, targetSize: NSSize(width: 36, height: 36)))
                                .resizable()
                                .frame(width: 36, height: 36)
                            Text("Preview")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(width: 168, height: 104)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .frame(width: 184)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(isHovered ? Color.accentColor.opacity(0.16) : Color.primary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(isHovered ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1.2)
        )
        .onHover { inside in
            isHovered = inside
            onHover(inside)
        }
    }
}
