import AppKit
import SwiftUI

/// Reusable NSHostingView subclass that automatically accepts first-mouse events.
/// This prevents clicks on floating panels from being consumed or discarded as window-activation clicks.
public final class InteractiveHostingView<Content: View>: NSHostingView<Content> {
    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}
