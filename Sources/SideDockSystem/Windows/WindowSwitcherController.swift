import AppKit
import SwiftUI
import MacStashDesignSystem

@MainActor
public final class WindowSwitcherController: ObservableObject {
    public static let shared = WindowSwitcherController()

    private var panel: SwitcherKeyPanel?
    private nonisolated(unsafe) var flagsMonitor: Any?
    private nonisolated(unsafe) var localFlagsMonitor: Any?
    @Published public var windows: [DockWindowInfo] = []
    @Published public var thumbnails: [CGWindowID: NSImage] = [:]
    @Published public var selectedIndex: Int = 0
    @Published public var isOpen: Bool = false

    public init() {}

    public func toggle() {
        if isOpen {
            stepSelection(1)
        } else {
            open()
        }
    }

    public func open() {
        let current = WindowRegistryService.shared.windows()
        guard !current.isEmpty else { return }

        windows = current
        selectedIndex = current.count > 1 ? 1 : 0
        isOpen = true

        if let selected = windows[safe: selectedIndex] {
            WindowHighlightOverlay.shared.highlight(cgWindowFrame: selected.frame)
        }

        Task {
            for win in current.prefix(12) {
                if let img = await WindowRegistryService.shared.captureThumbnail(for: win, maxSize: CGSize(width: 260, height: 160)) {
                    self.thumbnails[win.windowID] = img
                }
            }
        }

        presentPanel()
        installModifierReleaseMonitor()
    }

    private func installModifierReleaseMonitor() {
        removeModifierReleaseMonitor()
        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let mods = event.modifierFlags.intersection([.option, .command, .control])
            if mods.isEmpty {
                Task { @MainActor in
                    guard let self, self.isOpen else { return }
                    self.commitSelectionAndDismiss()
                }
            }
        }
        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let mods = event.modifierFlags.intersection([.option, .command, .control])
            if mods.isEmpty {
                Task { @MainActor in
                    guard let self, self.isOpen else { return }
                    self.commitSelectionAndDismiss()
                }
            }
            return event
        }
    }

    private func removeModifierReleaseMonitor() {
        if let mon = flagsMonitor {
            NSEvent.removeMonitor(mon)
            flagsMonitor = nil
        }
        if let lmon = localFlagsMonitor {
            NSEvent.removeMonitor(lmon)
            localFlagsMonitor = nil
        }
    }

    public func stepSelection(_ delta: Int) {
        guard !windows.isEmpty else { return }
        selectedIndex = ((selectedIndex + delta) % windows.count + windows.count) % windows.count
        if let win = windows[safe: selectedIndex] {
            WindowHighlightOverlay.shared.highlight(cgWindowFrame: win.frame)
        }
    }

    public func commitSelectionAndDismiss() {
        let target = windows[safe: selectedIndex]
        dismiss()
        if let target {
            WindowRegistryService.shared.focusWindow(target)
        }
    }

    public func dismiss() {
        isOpen = false
        removeModifierReleaseMonitor()
        WindowHighlightOverlay.shared.hide()
        panel?.orderOut(nil)
    }

    public func closeSelectedWindow() {
        guard let target = windows[safe: selectedIndex] else { return }
        WindowRegistryService.shared.closeWindow(target)
        windows.remove(at: selectedIndex)
        if windows.isEmpty {
            dismiss()
        } else {
            selectedIndex = min(selectedIndex, windows.count - 1)
        }
    }

    public func minimizeSelectedWindow() {
        guard let target = windows[safe: selectedIndex] else { return }
        WindowRegistryService.shared.minimizeWindow(target)
        windows.remove(at: selectedIndex)
        if windows.isEmpty {
            dismiss()
        } else {
            selectedIndex = min(selectedIndex, windows.count - 1)
        }
    }

    private func presentPanel() {
        let screen = NSScreen.main ?? NSScreen.screens.first
        let visible = screen?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1200, height: 800)

        let view = WindowSwitcherOverlayView(controller: self)
        let host = NSHostingView(rootView: view)
        host.layoutSubtreeIfNeeded()
        let desiredWidth = min(visible.width - 80, max(440, CGFloat(min(windows.count, 5)) * 210 + 48))
        let desiredHeight: CGFloat = windows.count > 5 ? 360 : 210
        let frame = CGRect(
            x: visible.midX - desiredWidth / 2,
            y: visible.midY - desiredHeight / 2,
            width: desiredWidth,
            height: desiredHeight
        )

        if panel == nil {
            let p = SwitcherKeyPanel(
                contentRect: frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            p.isOpaque = false
            p.backgroundColor = .clear
            p.hasShadow = true
            p.level = .screenSaver
            p.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary]
            p.onKeyEvent = { [weak self] event in
                self?.handleKeyEvent(event) ?? false
            }
            panel = p
        }

        panel?.contentView = host
        panel?.setFrame(frame, display: true)
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: false)
    }

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        switch event.keyCode {
        case 48, 124: // Tab / Right
            stepSelection(event.modifierFlags.contains(.shift) ? -1 : 1)
            return true
        case 123: // Left
            stepSelection(-1)
            return true
        case 36: // Return
            commitSelectionAndDismiss()
            return true
        case 53: // Esc
            dismiss()
            return true
        case 12, 13: // Q / W
            closeSelectedWindow()
            return true
        case 46: // M
            minimizeSelectedWindow()
            return true
        default:
            return false
        }
    }
}

private final class SwitcherKeyPanel: NSPanel {
    var onKeyEvent: ((NSEvent) -> Bool)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func keyDown(with event: NSEvent) {
        if onKeyEvent?(event) == true { return }
        super.keyDown(with: event)
    }
}

private struct WindowSwitcherOverlayView: View {
    @ObservedObject var controller: WindowSwitcherController

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Window Switcher", systemImage: "macwindow.on.rectangle")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Text("Tab / Arrows: Select   Enter: Focus   M: Minimize   W: Close   Esc: Cancel")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 185, maximum: 220), spacing: 12)], spacing: 12) {
                    ForEach(Array(controller.windows.enumerated()), id: \.element.id) { idx, win in
                        let isSelected = idx == controller.selectedIndex
                        Button {
                            controller.selectedIndex = idx
                            controller.commitSelectionAndDismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 6) {
                                    if let path = win.appPath {
                                        Image(nsImage: AppIconCache.shared.icon(forPath: path, targetSize: NSSize(width: 16, height: 16)))
                                            .resizable()
                                            .frame(width: 16, height: 16)
                                    }
                                    Text(win.appName)
                                        .font(.system(size: 11, weight: .bold))
                                        .lineLimit(1)
                                    Spacer()
                                }

                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color.primary.opacity(0.08))
                                    if let thumb = controller.thumbnails[win.windowID] {
                                        Image(nsImage: thumb)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    }
                                }
                                .frame(height: 92)

                                Text(win.title)
                                    .font(.system(size: 10.5))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(isSelected ? Color.accentColor.opacity(0.22) : Color.primary.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(0.1), lineWidth: isSelected ? 1.8 : 0.7)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThickMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.18), lineWidth: 1)
        )
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
