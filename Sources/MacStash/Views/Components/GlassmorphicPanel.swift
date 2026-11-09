import SwiftUI

/// Reusable glassmorphic panel view elevated with Apple Liquid Glass optical shading,
/// specular edge highlights, caustic ambient tint, and soft spatial depth.
public struct GlassmorphicPanel<Content: View>: View {
    public var cornerRadius: CGFloat
    public var tint: Color
    public var specularIntensity: Double
    public var content: () -> Content

    public init(
        cornerRadius: CGFloat = 20,
        tint: Color = .clear,
        specularIntensity: Double = 1.0,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.specularIntensity = specularIntensity
        self.content = content
    }

    public var body: some View {
        content()
            .liquidGlass(
                cornerRadius: cornerRadius,
                tint: tint,
                specularIntensity: specularIntensity,
                causticOpacity: 0.16,
                shadowRadius: 18
            )
    }
}
