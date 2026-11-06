import AppKit
import SwiftUI

/// Custom NSHostingView that dynamically passes clicks and hover through to underlying apps
/// unless the cursor is directly touching the corner vertex (within cornerSensitivityRadius)
public final class PassThroughHostingView<Content: View>: NSHostingView<Content> {
    public let corner: CornerPosition
    public var isExpanded: Bool = false
    private let appState: AppState

    public init(rootView: Content, corner: CornerPosition, appState: AppState) {
        self.corner = corner
        self.appState = appState
        super.init(rootView: rootView)
    }

    @MainActor required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @MainActor required init(rootView: Content) {
        fatalError("Use init(rootView:corner:appState:) instead")
    }

    public override func hitTest(_ point: NSPoint) -> NSView? {
        // If already expanded, accept interactions over the full dial view
        if isExpanded || appState.activeCorner == corner {
            return super.hitTest(point)
        }

        // When collapsed: only accept if mouse is within tight radius from the extreme corner
        let vertex = cornerVertex(in: bounds, corner: corner)
        let distance = hypot(point.x - vertex.x, point.y - vertex.y)

        if distance <= appState.cornerSensitivityRadius {
            return super.hitTest(point)
        }

        // Return nil so macOS passes all clicks, scrolls, and hovers directly down to underlying apps
        return nil
    }

    private func cornerVertex(in rect: NSRect, corner: CornerPosition) -> NSPoint {
        // NSHostingView is flipped by default (y = 0 is top)
        switch corner {
        case .topLeft:
            return NSPoint(x: rect.minX, y: rect.minY)
        case .topRight:
            return NSPoint(x: rect.maxX, y: rect.minY)
        case .bottomLeft:
            return NSPoint(x: rect.minX, y: rect.maxY)
        case .bottomRight:
            return NSPoint(x: rect.maxX, y: rect.maxY)
        }
    }
}
