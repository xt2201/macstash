import AppKit
import SwiftUI
import MacStashCore

/// NSHostingView wrapper for the Left-Edge utilities (Stash Shelf & Scratchpad).
/// Integrates native macOS NSDraggingDestination protocols to automatically
/// slide out the shelf as soon as a dragged file approaches the screen edge.
public final class StashShelfHostingView: NSHostingView<LeftEdgeContainerView> {
    private let appState: AppState
    private let shelf = StashShelfManager.shared
    private let scratchpad = ScratchpadManager.shared

    public init(rootView: LeftEdgeContainerView, appState: AppState) {
        self.appState = appState
        super.init(rootView: rootView)
        registerForDraggedTypes([
            .fileURL,
            .string,
            .URL,
            .html,
            .tiff,
            .png,
            NSPasteboard.PasteboardType("NSFilenamesPboardType")
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @available(*, unavailable)
    required init(rootView: LeftEdgeContainerView) {
        fatalError("init(rootView:) has not been implemented")
    }

    /// Essential for non-activating panels: ensures all buttons, tabs, and action icons
    /// trigger immediately on the very first mouse-click without requiring an activation click.
    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    public override func hitTest(_ point: NSPoint) -> NSView? {
        guard appState.isEnabled && appState.hasDrawerFeatureActive else {
            return nil
        }

        // Fullscreen suppression
        if appState.settings.suppressInFullscreen && NSApplication.shared.presentationOptions.contains(.fullScreen) {
            return nil
        }

        // Excluded applications suppression
        if let frontApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
           appState.settings.excludedBundleIDs.contains(frontApp) {
            return nil
        }

        // When shelf or scratchpad is actively open, route clicks within drawer bounds
        if shelf.isShelfOpen || shelf.isDropTargetActive || scratchpad.isScratchpadOpen {
            let activeDrawerWidth: CGFloat = scratchpad.isScratchpadOpen
                ? Defaults.LeftEdgeDrawer.scratchpadTotalWidthPoints
                : Defaults.LeftEdgeDrawer.shelfTotalWidthPoints
            let activeHeight: CGFloat = scratchpad.isScratchpadOpen
                ? Defaults.LeftEdgeDrawer.scratchpadTotalHeightPoints
                : Defaults.LeftEdgeDrawer.shelfTotalHeightPoints
            let activeY = (bounds.height - activeHeight) / 2.0
            let isRight = appState.settings.drawerEdgePosition == .right
            let activeX = isRight ? (bounds.maxX - activeDrawerWidth) : bounds.minX
            let activeRect = NSRect(x: activeX, y: activeY, width: activeDrawerWidth, height: activeHeight)
            if activeRect.contains(point) {
                return super.hitTest(point)
            }
            return nil
        }

        // When collapsed, return nil completely so background windows and controls are unobstructed
        return nil
    }

    public override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Esc
            shelf.closeShelf()
            scratchpad.isScratchpadOpen = false
            return
        }
        super.keyDown(with: event)
    }

    // MARK: - Mouse Tracking for Auto-Dismiss

    private var trackingArea: NSTrackingArea?

    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    public override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        let isAnyPinned = (shelf.isShelfOpen && shelf.isPinned) || (scratchpad.isScratchpadOpen && scratchpad.isPinned)
        if !isAnyPinned && !shelf.isDropTargetActive {
            ScreenManager.shared.scheduleLeftEdgeHideTimer()
        }
    }

    public override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        ScreenManager.shared.cancelPendingLeftEdgeHide()
    }

    public override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        ScreenManager.shared.cancelPendingLeftEdgeHide()
    }

    // MARK: - Native Drag Destination

    public override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard appState.isEnabled && appState.settings.isStashShelfEnabled else {
            return []
        }

        if !shelf.isShelfOpen {
            shelf.isShelfOpen = true
            HapticManager.shared.performDetentTick()
        }
        shelf.isDropTargetActive = true
        return .copy
    }

    public override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    public override func draggingExited(_ sender: NSDraggingInfo?) {
        shelf.isDropTargetActive = false
    }

    public override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        shelf.isDropTargetActive = false
        let pasteboard = sender.draggingPasteboard

        // 1. Direct file and web URLs
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
            let fileURLs = urls.filter { $0.isFileURL }
            let webURLs = urls.filter { !$0.isFileURL }

            if !fileURLs.isEmpty {
                shelf.addFileURLs(fileURLs)
            }
            for webURL in webURLs {
                shelf.addTextSnippet(webURL.absoluteString)
            }
            if !fileURLs.isEmpty || !webURLs.isEmpty {
                return true
            }
        }

        // 2. Legacy NSFilenamesPboardType (from older macOS apps or cross-platform drop sources)
        if let filenames = pasteboard.propertyList(forType: NSPasteboard.PasteboardType("NSFilenamesPboardType")) as? [String], !filenames.isEmpty {
            let urls = filenames.map { URL(fileURLWithPath: $0) }
            shelf.addFileURLs(urls)
            return true
        }

        // 3. String content (can be a file path, file:// URL, web link, or text snippet)
        if let strings = pasteboard.readObjects(forClasses: [NSString.self], options: nil) as? [String], let first = strings.first {
            let trimmed = first.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("/") && FileManager.default.fileExists(atPath: trimmed) {
                shelf.addFileURLs([URL(fileURLWithPath: trimmed)])
                return true
            } else if trimmed.hasPrefix("file://"), let fileURL = URL(string: trimmed), fileURL.isFileURL {
                shelf.addFileURLs([fileURL])
                return true
            }
            shelf.addTextSnippet(first)
            return true
        }

        // 4. Direct Image drop (from web browser or clipboard)
        if let images = pasteboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage], let firstImage = images.first {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("MacStashDrops", isDirectory: true)
            try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            let tempURL = tempDir.appendingPathComponent("Stashed_Image_\(Int(Date().timeIntervalSince1970)).png")
            if let tiffData = firstImage.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                if (try? pngData.write(to: tempURL, options: .atomic)) != nil {
                    shelf.addFileURLs([tempURL])
                    return true
                }
            }
        }

        return false
    }
}
