import AppKit
import SwiftUI

public final class SideDockHostingView<Content: View>: NSHostingView<Content> {
    /// Essential for non-activating panels: ensures all buttons, tiles, widgets, and menus
    /// trigger immediately on the very first mouse-click without requiring an activation click.
    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    public override func hitTest(_ point: NSPoint) -> NSView? {
        let localPoint = superview != nil ? convert(point, from: superview) : point
        guard bounds.contains(localPoint) else {
            return nil
        }
        return super.hitTest(point)
    }
}
