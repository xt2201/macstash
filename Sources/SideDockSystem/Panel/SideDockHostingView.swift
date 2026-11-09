import AppKit
import SwiftUI

public final class SideDockHostingView<Content: View>: NSHostingView<Content> {
    public override func hitTest(_ point: NSPoint) -> NSView? {
        guard let view = super.hitTest(point) else {
            return nil
        }

        if view === self {
            return nil
        }

        return view
    }
}
