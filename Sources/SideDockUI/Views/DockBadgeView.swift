import SwiftUI
import SideDockCore

public struct DockBadgeView: View {
    public let label: String?

    public init(label: String?) {
        self.label = label
    }

    public var body: some View {
        if let text = label, !text.isEmpty {
            Text(text)
                .font(.system(size: text.count > 2 ? 8.5 : 9.5, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.white)
                .padding(.horizontal, text.count == 1 ? 0 : 4.5)
                .frame(minWidth: 16, minHeight: 16)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.red.gradient)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(Color.white.opacity(0.45), lineWidth: 0.7)
                )
                .shadow(color: Color.black.opacity(0.28), radius: 2, y: 1)
                .transition(.scale.combined(with: .opacity))
        }
    }
}

public struct DockRunningIndicatorView: View {
    public let isRunning: Bool
    public let isActive: Bool
    public let style: DockIndicatorStyle
    public let isVertical: Bool

    public init(isRunning: Bool, isActive: Bool = false, style: DockIndicatorStyle, isVertical: Bool) {
        self.isRunning = isRunning
        self.isActive = isActive
        self.style = style
        self.isVertical = isVertical
    }

    public var body: some View {
        Group {
            if !isRunning || style == .none {
                Color.clear
                    .frame(width: isVertical ? 4 : 6, height: isVertical ? 6 : 4)
            } else {
                switch style {
                case .dot:
                    Circle()
                        .fill(isActive ? Color.accentColor : Color.primary.opacity(0.85))
                        .frame(width: isActive ? 5 : 4, height: isActive ? 5 : 4)
                case .pill:
                    Capsule(style: .continuous)
                        .fill(isActive ? Color.accentColor : Color.primary.opacity(0.85))
                        .frame(width: isVertical ? 3 : (isActive ? 12 : 8), height: isVertical ? (isActive ? 12 : 8) : 3)
                case .glow:
                    Circle()
                        .fill(isActive ? Color.accentColor : Color.white)
                        .frame(width: 4.5, height: 4.5)
                        .shadow(color: (isActive ? Color.accentColor : Color.white).opacity(0.9), radius: 3.5)
                case .none:
                    Color.clear.frame(width: 4, height: 4)
                }
            }
        }
    }
}
