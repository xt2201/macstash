import SwiftUI
import AppKit
import SideDockCore

public struct SearchConfig: Codable, Equatable, Sendable {
    public var placeholder: String

    public init(placeholder: String = "Search apps...") {
        self.placeholder = placeholder
    }
}

public struct SearchWidgetView: View {
    public let config: SearchConfig
    public let size: WidgetSize
    @State private var queryText: String = ""

    public init(config: SearchConfig = SearchConfig(), size: WidgetSize = .medium) {
        self.config = config
        self.size = size
    }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            TextField(config.placeholder, text: $queryText)
                .textFieldStyle(.plain)
                .font(.system(size: 11))
                .frame(width: size == .small ? 50 : 90)
                .onSubmit {
                    performSearchAndOpen()
                }

            if !queryText.isEmpty {
                Button {
                    queryText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(0.06))
        )
    }

    private func performSearchAndOpen() {
        let trimmed = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: trimmed) ??
            findAppNamed(trimmed) {
            NSWorkspace.shared.open(appURL)
            queryText = ""
            return
        }

        if let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let spotlightURL = URL(string: "spotlight://\(encoded)") {
            NSWorkspace.shared.open(spotlightURL)
        }
        queryText = ""
    }

    private func findAppNamed(_ name: String) -> URL? {
        let commonPaths = [
            "/Applications/\(name).app",
            "/System/Applications/\(name).app",
            "/System/Applications/Utilities/\(name).app"
        ]
        for path in commonPaths {
            if FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }
}
