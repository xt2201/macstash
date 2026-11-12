import Foundation

public enum DockBackdropStyle: String, Codable, Sendable, CaseIterable {
    case lightGlass
    case darkGlass
    case clear
    case liquidGlass
    case autoSystem
}

public enum DockThemePreset: String, Codable, Sendable, CaseIterable {
    case liquidGlass
    case macosGlass
    case classicShelf
    case floatingPill
    case highContrast
    case clear
}

public enum DockIndicatorStyle: String, Codable, Sendable, CaseIterable {
    case dot
    case pill
    case glow
    case none
}

public enum FolderPresentationStyle: String, Codable, Sendable, CaseIterable {
    case popoverGrid
    case popoverList
    case fan
}

public struct DockTheme: Codable, Equatable, Sendable {
    public var backdropStyle: DockBackdropStyle
    public var preset: DockThemePreset
    public var indicatorStyle: DockIndicatorStyle
    public var cornerRadius: Double
    public var glassBlurRadius: Double
    public var borderOpacity: Double
    public var shadowRadius: Double
    public var tintHex: String?
    public var widgetTextScale: Double
    public var reduceMotion: Bool

    public init(
        backdropStyle: DockBackdropStyle = .autoSystem,
        preset: DockThemePreset = .liquidGlass,
        indicatorStyle: DockIndicatorStyle = .dot,
        cornerRadius: Double = 18.0,
        glassBlurRadius: Double = 24.0,
        borderOpacity: Double = 0.25,
        shadowRadius: Double = 16.0,
        tintHex: String? = nil,
        widgetTextScale: Double = 1.0,
        reduceMotion: Bool = false
    ) {
        self.backdropStyle = backdropStyle
        self.preset = preset
        self.indicatorStyle = indicatorStyle
        self.cornerRadius = max(4.0, min(36.0, cornerRadius))
        self.glassBlurRadius = max(0.0, min(60.0, glassBlurRadius))
        self.borderOpacity = max(0.0, min(1.0, borderOpacity))
        self.shadowRadius = max(0.0, min(40.0, shadowRadius))
        self.tintHex = tintHex
        self.widgetTextScale = max(0.8, min(1.35, widgetTextScale))
        self.reduceMotion = reduceMotion
    }

    private enum CodingKeys: String, CodingKey {
        case backdropStyle, preset, indicatorStyle, cornerRadius, glassBlurRadius
        case borderOpacity, shadowRadius, tintHex, widgetTextScale, reduceMotion
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let backdrop = try c.decodeIfPresent(DockBackdropStyle.self, forKey: .backdropStyle) ?? .autoSystem
        let preset = try c.decodeIfPresent(DockThemePreset.self, forKey: .preset) ?? Self.defaultPreset(for: backdrop)
        let indicator = try c.decodeIfPresent(DockIndicatorStyle.self, forKey: .indicatorStyle) ?? .dot
        let radius = try c.decodeIfPresent(Double.self, forKey: .cornerRadius) ?? 18.0
        let blur = try c.decodeIfPresent(Double.self, forKey: .glassBlurRadius) ?? 24.0
        let border = try c.decodeIfPresent(Double.self, forKey: .borderOpacity) ?? 0.25
        let shadow = try c.decodeIfPresent(Double.self, forKey: .shadowRadius) ?? 16.0
        let tint = try c.decodeIfPresent(String.self, forKey: .tintHex)
        let textScale = try c.decodeIfPresent(Double.self, forKey: .widgetTextScale) ?? 1.0
        let reduce = try c.decodeIfPresent(Bool.self, forKey: .reduceMotion) ?? false

        self.init(
            backdropStyle: backdrop,
            preset: preset,
            indicatorStyle: indicator,
            cornerRadius: radius,
            glassBlurRadius: blur,
            borderOpacity: border,
            shadowRadius: shadow,
            tintHex: tint,
            widgetTextScale: textScale,
            reduceMotion: reduce
        )
    }

    private static func defaultPreset(for style: DockBackdropStyle) -> DockThemePreset {
        switch style {
        case .clear: return .clear
        case .lightGlass, .darkGlass, .autoSystem: return .macosGlass
        case .liquidGlass: return .liquidGlass
        }
    }
}
