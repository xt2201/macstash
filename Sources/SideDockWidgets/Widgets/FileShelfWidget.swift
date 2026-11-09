import SwiftUI
import AppKit
import SideDockCore

public struct FileShelfConfig: Codable, Equatable, Sendable {
    public var maxFiles: Int

    public init(maxFiles: Int = 20) {
        self.maxFiles = maxFiles
    }
}

public struct ShelvedFile: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let url: URL
    public let name: String

    public init(id: UUID = UUID(), url: URL) {
        self.id = id
        self.url = url
        self.name = url.lastPathComponent
    }
}

public struct FileShelfWidgetView: View {
    public let config: FileShelfConfig
    public let size: WidgetSize
    @State private var shelvedFiles: [ShelvedFile] = []
    @State private var isTargeted: Bool = false

    public init(config: FileShelfConfig = FileShelfConfig(), size: WidgetSize = .small) {
        self.config = config
        self.size = size
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isTargeted ? "tray.and.arrow.down.fill" : "tray.full.fill")
                .font(.system(size: 14))
                .foregroundColor(isTargeted ? .accentColor : .primary)

            if size != .small {
                Text("\(shelvedFiles.count)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))

                if !shelvedFiles.isEmpty {
                    Button {
                        clearShelf()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let fileURL = url {
                    DispatchQueue.main.async {
                        if !self.shelvedFiles.contains(where: { $0.url == fileURL }) {
                            self.shelvedFiles.append(ShelvedFile(url: fileURL))
                        }
                    }
                }
            }
        }
        return true
    }

    private func clearShelf() {
        shelvedFiles.removeAll()
    }
}
