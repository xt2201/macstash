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
        registerForDraggedTypes([.fileURL, .string, .URL])
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
            let activeDrawerWidth: CGFloat = 330.0
            let activeRect = NSRect(x: bounds.minX, y: bounds.minY, width: activeDrawerWidth, height: bounds.height)
            if activeRect.contains(point) {
                return super.hitTest(point)
            }
            return nil
        }

        // When collapsed, only hit test the subtle peek tab along the left edge
        let edgeHitZone: CGFloat = 22.0
        let triggerRect = NSRect(x: bounds.minX, y: bounds.minY, width: edgeHitZone, height: bounds.height)

        if triggerRect.contains(point) {
            return super.hitTest(point)
        }

        return nil
    }

    // MARK: - Native Drag Destination

    public override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard appState.isEnabled && appState.settings.isStashShelfEnabled else {
            return []
        }

        shelf.isShelfOpen = true
        shelf.isDropTargetActive = true
        HapticManager.shared.performDetentTick()
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

        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
            shelf.addFileURLs(urls)
            return true
        }

        if let strings = pasteboard.readObjects(forClasses: [NSString.self], options: nil) as? [String], let first = strings.first {
            shelf.addTextSnippet(first)
            return true
        }

        return false
    }
}
