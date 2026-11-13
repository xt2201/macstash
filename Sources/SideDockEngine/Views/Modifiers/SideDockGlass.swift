//
//  SideDockGlass.swift
//  MacStash
//
//  Drop-in replacement for `.glassEffect(...)` that gates Liquid Glass on
//  macOS 26+ and falls back to the same SkyLight private-API backdrop blur
//  the dock chrome uses on macOS 13.5–25. Apply `.sideDockGlass(in: shape)`
//  on every surface that should follow the platform behavior.
//

import AppKit
import SwiftUI

enum SideDockGlassStyle {
    case regular
    case clear
}

extension View {
    @ViewBuilder
    func sideDockGlass<S: Shape>(_ style: SideDockGlassStyle = .regular, in shape: S) -> some View {
        modifier(SideDockGlassModifier(style: style, shape: AnyShape(shape)))
    }

    @ViewBuilder
    func sideDockGlass(_ style: SideDockGlassStyle = .regular) -> some View {
        modifier(SideDockGlassModifier(style: style, shape: AnyShape(Capsule())))
    }

    @ViewBuilder
    func sideDockGlassBorder<S: InsettableShape>(in shape: S, lineWidth: CGFloat = 1) -> some View {
        modifier(SideDockGlassBorderModifier(shape: shape, lineWidth: lineWidth))
    }
}

let sideDockGlassBorderGradient = LinearGradient(
    colors: [
        Color.white.opacity(0.35),
        Color.white.opacity(0.12),
        Color.white.opacity(0.05),
        Color.white.opacity(0.12),
        Color.white.opacity(0.28),
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

private struct SideDockGlassBorderModifier<S: InsettableShape>: ViewModifier {
    let shape: S
    let lineWidth: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
        content.overlay {
            if !SideDockPreferences.shared.effectiveDisablesGlassLook {
                shape.strokeBorder(sideDockGlassBorderGradient, lineWidth: lineWidth)
            }
        }
    }
}

private struct SideDockGlassModifier: ViewModifier {
    let style: SideDockGlassStyle
    let shape: AnyShape

    @ViewBuilder
    func body(content: Content) -> some View {
        if FeatureGate.shared.isAvailable(.liquidGlass), #available(macOS 26.0, *) {
            content.glassEffect(style.glass, in: shape)
        } else {
            content.background(SkyLightGlassFallback(style: style, shape: shape))
        }
    }
}

@available(macOS 26.0, *)
private extension SideDockGlassStyle {
    var glass: Glass {
        switch self {
        case .regular: return .regular
        case .clear: return .clear
        }
    }
}

private struct SkyLightGlassFallback: View {
    let style: SideDockGlassStyle
    let shape: AnyShape

    var body: some View {
        ZStack {
            SkyLightHostBlurInstaller()
            shape.fill(.primary.opacity(tintOpacity))
        }
    }

    private var tintOpacity: Double {
        switch style {
        case .regular: return 0.18
        case .clear: return 0.04
        }
    }
}

private struct SkyLightHostBlurInstaller: NSViewRepresentable {
    var blurRadius: Int = 30

    func makeNSView(context: Context) -> InstallerView {
        InstallerView(blurRadius: blurRadius)
    }

    func updateNSView(_ view: InstallerView, context: Context) {
        view.blurRadius = blurRadius
        view.applyToHostWindow()
    }

    final class InstallerView: NSView {
        var blurRadius: Int

        init(blurRadius: Int) {
            self.blurRadius = blurRadius
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            applyToHostWindow()
        }

        func applyToHostWindow() {
            guard let window, window.windowNumber > 0 else { return }
            _ = CGSSetWindowBackgroundBlurRadius(
                CGSMainConnectionID(),
                window.windowNumber,
                blurRadius
            )
        }
    }
}
