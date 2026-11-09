import SwiftUI
import AppKit
import SideDockCore

public struct ColorPickerConfig: Codable, Equatable, Sendable {
    public var lastHex: String

    public init(lastHex: String = "#0A84FF") {
        self.lastHex = lastHex
    }
}

public struct ColorPickerWidgetView: View {
    public let config: ColorPickerConfig
    public let size: WidgetSize

    @State private var currentColorHex: String
    @State private var copied: Bool = false

    public init(config: ColorPickerConfig = ColorPickerConfig(), size: WidgetSize = .medium) {
        self.config = config
        self.size = size
        _currentColorHex = State(initialValue: config.lastHex)
    }

    public var body: some View {
        Group {
            switch size {
            case .small:
                smallView
            case .medium, .large:
                mediumView
            }
        }
    }

    private var smallView: some View {
        Button {
            sampleColor()
        } label: {
            VStack(spacing: 2) {
                Circle()
                    .fill(Color(hex: currentColorHex) ?? .blue)
                    .frame(width: 18, height: 18)
                    .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                Image(systemName: "eyedropper.halffull")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Sample Color on Screen: \(currentColorHex)")
    }

    private var mediumView: some View {
        HStack(spacing: 8) {
            Button {
                sampleColor()
            } label: {
                Circle()
                    .fill(Color(hex: currentColorHex) ?? .blue)
                    .frame(width: 24, height: 24)
                    .overlay(Circle().stroke(Color.primary.opacity(0.25), lineWidth: 1.5))
                    .overlay(
                        Image(systemName: "eyedropper")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(radius: 1)
                    )
            }
            .buttonStyle(.plain)
            .help("Click to sample color from screen")

            Button {
                copyHex()
            } label: {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text(currentColorHex)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                        if copied {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8))
                                .foregroundColor(.green)
                        }
                    }
                    Text("Click to copy HEX")
                        .font(.system(size: 7))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
        .frame(height: 44)
    }

    private func sampleColor() {
        let sampler = NSColorSampler()
        sampler.show { selectedColor in
            Task { @MainActor in
                guard let color = selectedColor?.usingColorSpace(.sRGB) else { return }
                let r = Int(color.redComponent * 255.0)
                let g = Int(color.greenComponent * 255.0)
                let b = Int(color.blueComponent * 255.0)
                let hex = String(format: "#%02X%02X%02X", r, g, b)
                self.currentColorHex = hex
                copyHex()
            }
        }
    }

    private func copyHex() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(currentColorHex, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.copied = false
        }
    }
}

extension Color {
    init?(hex: String) {
        var clean = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("#") {
            clean.removeFirst()
        }
        guard clean.count == 6, let intVal = UInt64(clean, radix: 16) else { return nil }
        let r = Double((intVal >> 16) & 0xFF) / 255.0
        let g = Double((intVal >> 8) & 0xFF) / 255.0
        let b = Double(intVal & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
