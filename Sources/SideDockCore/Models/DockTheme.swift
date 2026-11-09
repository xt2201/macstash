import Foundation

public enum DockBackdropStyle: String, Codable, Sendable, CaseIterable {
    case lightGlass
    case darkGlass
    case clear
    case liquidGlass
    case autoSystem
}

public struct DockTheme: Codable, Equatable, Sendable {
    public var backdropStyle: DockBackdropStyle
    public var cornerRadius: Double
    public var glassBlurRadius: Double
    public var borderOpacity: Double
    public var shadowRadius: Double
    public var reduceMotion: Bool

    public init(
        backdropStyle: DockBackdropStyle = .autoSystem,
        cornerRadius: Double = 18.0,
        glassBlurRadius: Double = 24.0,
        borderOpacity: Double = 0.25,
        shadowRadius: Double = 16.0,
        reduceMotion: Bool = false
    ) {
        self.backdropStyle = backdropStyle
        self.cornerRadius = max(4.0, min(36.0, cornerRadius))
        self.glassBlurRadius = max(0.0, min(60.0, glassBlurRadius))
        self.borderOpacity = max(0.0, min(1.0, borderOpacity))
        self.shadowRadius = max(0.0, min(40.0, shadowRadius))
        self.reduceMotion = reduceMotion
    }
}
