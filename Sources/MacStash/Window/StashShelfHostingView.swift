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
        guard appState.isEnabled && (appState.settings.isStashShelfEnabled || appState.settings.isScratchpadEnabled) else {
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
            let activeDrawerWidth: CGFloat = scratchpad.isScratchpadOpen ? 370.0 : 335.0
            let activeHeight: CGFloat = scratchpad.isScratchpadOpen ? 400.0 : 485.0
            let activeY = (bounds.height - activeHeight) / 2.0
            let activeRect = NSRect(x: bounds.minX, y: activeY, width: activeDrawerWidth, height: activeHeight)
            if activeRect.contains(point) {
                return super.hitTest(point)
            }
            return nil
        }

        // When collapsed, hit test the peek handle zone along the left edge
        let handleHeight: CGFloat = 84.0
        let handleY = (bounds.height - handleHeight) / 2.0
        let triggerRect = NSRect(x: bounds.minX, y: handleY, width: 44.0, height: handleHeight)

        if triggerRect.contains(point) {
            return super.hitTest(point)
        }

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

        // 1. Direct file URLs
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
            shelf.addFileURLs(urls)
            return true
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

        return false
    }
}
