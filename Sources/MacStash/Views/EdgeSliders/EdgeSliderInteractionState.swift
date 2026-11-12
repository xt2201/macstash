import SwiftUI

/// Shared main-actor state bridging SwiftUI hover/expansion state in `EdgeSliderView`
/// with AppKit event routing and hit testing in `EdgeSliderHostingView`.
@MainActor
public final class EdgeSliderInteractionState: ObservableObject {
    @Published public var isMediaExpanded: Bool = false
    @Published public var isVolumeButtonHovered: Bool = false
    @Published public var isVolumeColumnHovered: Bool = false
    @Published public var isIslandHovered: Bool = false
    @Published public var isSliderDragging: Bool = false

    public var isVolumeColumnVisible: Bool = false

    public init() {}

    public func reset() {
        isMediaExpanded = false
        isVolumeButtonHovered = false
        isVolumeColumnHovered = false
        isIslandHovered = false
        isSliderDragging = false
        isVolumeColumnVisible = false
    }
}
