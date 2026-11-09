import SwiftUI
import AppKit

/// Unified Brand Identity and Logo Component for MacStash
public struct StashBrandLogoView: View {
    public var size: CGFloat
    public var showWordmark: Bool

    public init(size: CGFloat = 48, showWordmark: Bool = false) {
        self.size = size
        self.showWordmark = showWordmark
    }

    public var body: some View {
        HStack(spacing: size * 0.24) {
            if let icon = loadAppIcon() {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
                    .shadow(color: Color.black.opacity(0.18), radius: size * 0.08, x: 0, y: size * 0.04)
            } else {
                // Procedural Vector Fallback matching the new brand identity
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color(red: 0.10, green: 0.12, blue: 0.16), Color(red: 0.05, green: 0.06, blue: 0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))

                    // Quarter-circle active arc
                    Circle()
                        .stroke(LinearGradient(
                            colors: [Color(red: 0.04, green: 0.52, blue: 1.0), Color(red: 0.0, green: 0.82, blue: 1.0)],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        ), lineWidth: size * 0.12)
                        .frame(width: size * 1.1, height: size * 1.1)
                        .offset(x: -size * 0.35, y: size * 0.35)

                    // Origin pin
                    Circle()
                        .fill(Color(red: 0.0, green: 0.82, blue: 1.0))
                        .frame(width: size * 0.22, height: size * 0.22)
                        .offset(x: size * 0.12, y: -size * 0.12)
                }
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            }

            if showWordmark {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Stash")
                        .font(.system(size: size * 0.48, weight: .bold))
                        .foregroundColor(.primary)

                    Text("FOR macOS")
                        .font(.system(size: max(8, size * 0.18), weight: .bold))
                        .foregroundColor(Color(red: 0.0, green: 0.75, blue: 0.95))
                        .tracking(1.5)
                }
            }
        }
    }

    private func loadAppIcon() -> NSImage? {
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        if let img = NSImage(named: "AppIcon") {
            return img
        }
        return NSApp.applicationIconImage
    }
}
