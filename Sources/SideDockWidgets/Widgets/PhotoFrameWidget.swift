import SwiftUI
import AppKit
import ImageIO
import os.log
import SideDockCore

public struct PhotoFrameConfig: Codable, Equatable, Sendable {
    public var folderPath: String
    public var intervalSeconds: Double

    public init(
        folderPath: String = "~/Pictures",
        intervalSeconds: Double = 15.0
    ) {
        self.folderPath = folderPath
        self.intervalSeconds = max(3.0, min(300.0, intervalSeconds))
    }
}

public actor PhotoFrameLoader {
    public static let shared = PhotoFrameLoader()
    private static let logger = Logger(subsystem: "com.macstash.app", category: "photoframe")
    private static let supportedExtensions: Set<String> = ["jpg", "jpeg", "png", "heic", "webp", "tiff"]

    public func listImageURLs(in folderPath: String) -> [URL] {
        let expanded = (folderPath as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expanded)
        do {
            let items = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
            return items.filter { Self.supportedExtensions.contains($0.pathExtension.lowercased()) }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
        } catch {
            Self.logger.debug("PhotoFrame directory scan skipped for \(expanded, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    public func loadThumbnail(at url: URL, maxPixelSize: CGFloat = 240) -> NSImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let cgImg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return NSImage(cgImage: cgImg, size: NSSize(width: cgImg.width, height: cgImg.height))
    }
}

public struct PhotoFrameWidgetView: View {
    public let config: PhotoFrameConfig
    public let size: WidgetSize

    @State private var imageURLs: [URL] = []
    @State private var currentIndex: Int = 0
    @State private var currentImage: NSImage?
    @State private var rotationTimer: Timer?

    public init(config: PhotoFrameConfig = PhotoFrameConfig(), size: WidgetSize = .medium) {
        self.config = config
        self.size = size
    }

    public var body: some View {
        ZStack {
            if let img = currentImage {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: tileWidth, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                HStack(spacing: 5) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 15))
                        .foregroundColor(.accentColor)
                    if size != .small {
                        Text("Photos")
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: tileWidth, height: 40)
            }
        }
        .onAppear {
            startSlideshow()
        }
        .onDisappear {
            rotationTimer?.invalidate()
            rotationTimer = nil
        }
    }

    private var tileWidth: CGFloat {
        switch size {
        case .small: return 42
        case .medium: return 84
        case .large: return 132
        }
    }

    private func startSlideshow() {
        rotationTimer?.invalidate()
        Task {
            let urls = await PhotoFrameLoader.shared.listImageURLs(in: config.folderPath)
            await MainActor.run {
                self.imageURLs = urls
                self.currentIndex = 0
            }
            await loadCurrentImage()
        }

        rotationTimer = Timer.scheduledTimer(withTimeInterval: config.intervalSeconds, repeats: true) { _ in
            Task { @MainActor in
                guard !self.imageURLs.isEmpty else { return }
                self.currentIndex = (self.currentIndex + 1) % self.imageURLs.count
                await self.loadCurrentImage()
            }
        }
    }

    private func loadCurrentImage() async {
        guard currentIndex < imageURLs.count else { return }
        let url = imageURLs[currentIndex]
        let thumb = await PhotoFrameLoader.shared.loadThumbnail(at: url, maxPixelSize: 260)
        await MainActor.run {
            self.currentImage = thumb
        }
    }
}

public struct PhotoFrameExpandedView: View {
    public let config: PhotoFrameConfig
    @State private var imageURLs: [URL] = []
    @State private var currentIndex: Int = 0
    @State private var currentImage: NSImage?

    public init(config: PhotoFrameConfig) {
        self.config = config
    }

    public var body: some View {
        VStack(spacing: 10) {
            HStack {
                Label("Photo Frame", systemImage: "photo.on.rectangle.angled")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                if !imageURLs.isEmpty {
                    Text("\(currentIndex + 1) / \(imageURLs.count)")
                        .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }

            if let img = currentImage {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 280, maxHeight: 190)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                Text("No images found in \(config.folderPath)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(width: 260, height: 120)
            }

            HStack {
                Button { step(-1) } label: { Image(systemName: "chevron.left") }
                    .buttonStyle(.bordered)
                    .disabled(imageURLs.count <= 1)
                Spacer()
                if currentIndex < imageURLs.count {
                    Button("Open") {
                        NSWorkspace.shared.open(imageURLs[currentIndex])
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                Spacer()
                Button { step(1) } label: { Image(systemName: "chevron.right") }
                    .buttonStyle(.bordered)
                    .disabled(imageURLs.count <= 1)
            }
        }
        .padding(14)
        .frame(width: 310)
        .task {
            imageURLs = await PhotoFrameLoader.shared.listImageURLs(in: config.folderPath)
            await loadCurrent()
        }
    }

    private func step(_ delta: Int) {
        guard !imageURLs.isEmpty else { return }
        currentIndex = ((currentIndex + delta) % imageURLs.count + imageURLs.count) % imageURLs.count
        Task { await loadCurrent() }
    }

    private func loadCurrent() async {
        guard currentIndex < imageURLs.count else { return }
        currentImage = await PhotoFrameLoader.shared.loadThumbnail(at: imageURLs[currentIndex], maxPixelSize: 560)
    }
}
