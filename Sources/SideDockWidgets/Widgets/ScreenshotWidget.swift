import SwiftUI
import AppKit
import SideDockCore

public struct ScreenshotConfig: Codable, Equatable, Sendable {
    public var saveToDesktop: Bool

    public init(saveToDesktop: Bool = true) {
        self.saveToDesktop = saveToDesktop
    }
}

public struct ScreenshotWidgetView: View {
    public let config: ScreenshotConfig
    public let size: WidgetSize

    public init(config: ScreenshotConfig = ScreenshotConfig(), size: WidgetSize = .medium) {
        self.config = config
        self.size = size
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
            captureArea()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.accentColor)
                Text("Capture")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Area Screenshot (Interactive)")
    }

    private var mediumView: some View {
        HStack(spacing: 6) {
            Button {
                captureArea()
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Area")
                        .font(.system(size: 8))
                }
                .frame(width: 38, height: 38)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.06)))
            }
            .buttonStyle(.plain)
            .help("Capture Selected Area")

            Button {
                captureScreen()
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "macwindow")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Screen")
                        .font(.system(size: 8))
                }
                .frame(width: 38, height: 38)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.06)))
            }
            .buttonStyle(.plain)
            .help("Capture Entire Screen")

            Button {
                openScreenshotUtility()
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "record.circle")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.red)
                    Text("Record")
                        .font(.system(size: 8))
                }
                .frame(width: 38, height: 38)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.06)))
            }
            .buttonStyle(.plain)
            .help("Open macOS Screen Recording Toolbar")
        }
        .padding(.horizontal, 4)
        .frame(height: 44)
    }

    private func captureArea() {
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "-c"] // Interactive to clipboard
        try? task.run()
    }

    private func captureScreen() {
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-c"] // Fullscreen to clipboard
        try? task.run()
    }

    private func openScreenshotUtility() {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.screenshot.launcher") {
            NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration())
        } else {
            let task = Process()
            task.launchPath = "/usr/bin/open"
            task.arguments = ["-b", "com.apple.screenshot.launcher"]
            try? task.run()
        }
    }
}
