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
        return allowsKeyWindow
    }

    public override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if allowsKeyWindow && event.modifierFlags.contains(.command) {
            let key = event.charactersIgnoringModifiers?.lowercased()
            switch key {
            case "a":
                if NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: self) { return true }
            case "c":
                if NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self) { return true }
            case "v":
                if NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self) { return true }
            case "x":
                if NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self) { return true }
            case "z":
                if event.modifierFlags.contains(.shift) {
                    if NSApp.sendAction(Selector(("redo:")), to: nil, from: self) { return true }
                } else {
                    if NSApp.sendAction(Selector(("undo:")), to: nil, from: self) { return true }
                }
            default:
                break
            }
        }
        return super.performKeyEquivalent(with: event)
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
