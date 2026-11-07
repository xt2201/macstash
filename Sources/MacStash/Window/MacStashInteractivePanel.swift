import AppKit

/// A specialized NSPanel subclass for MacStash floating interactive overlays
/// (such as Stash Shelf, Quick Scratchpad, Edge Sliders, and Radial Palette).
///
/// Provides configurable key window behavior (to allow TextEditor and keyboard input)
/// while remaining unobtrusive and non-activating for other applications when idle.
public final class MacStashInteractivePanel: NSPanel {
    /// Controls whether this panel can become the key window.
    /// Set to true when an interactive drawer (like Scratchpad text editor) is actively opened.
    public var allowsKeyWindow: Bool = false

    public override var canBecomeKey: Bool {
        return allowsKeyWindow
    }

    public override var canBecomeMain: Bool {
        return false
    }

    public override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.acceptsMouseMovedEvents = true
        self.ignoresMouseEvents = true
        self.isMovable = false
        self.isMovableByWindowBackground = false
    }
}
