//
//  MarketplaceClient.swift
//  MacStash
//
//  Talks to widgets.macstash.com/api/widgets — the marketplace manifest that
//  lists community-submitted widget bundles available for install.
//

import CryptoKit
import Foundation

struct MarketplaceWidget: Decodable, Identifiable, Equatable {
    let identifier: String
    let title: String
    let author: String
    let version: String
    let downloadURL: URL
    let sha256: String?
    let previewURL: URL?
    let description: String?
    let systemImageName: String?

    var id: String { identifier }
}

@MainActor
final class MarketplaceClient {
    static let shared = MarketplaceClient()

    private static let manifestURL = URL(string: "https://widgets.macstash.com/api/widgets")!

    private let session: URLSession
    private var cached: [MarketplaceWidget]?

    private init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 12
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    /// Returns available online marketplace widgets (disabled in MacStash offline mode).
    func fetch(forceRefresh: Bool = false) async throws -> [MarketplaceWidget] {
        return []
    }

    /// Downloads a widget's `.stashwidget` archive into a temp directory
    /// and returns the URL of the bundle inside it, ready for
    /// `ExternalWidgetLoader.installBundle(from:)`. Supports either a
    /// `.zip` containing the bundle or a raw `.stashwidget` package.
    /// If the manifest provided a `sha256`, the downloaded payload is
    /// verified against it before being unpacked.
    func download(_ widget: MarketplaceWidget) async throws -> URL {
        try await downloadBundle(from: widget.downloadURL, expectedSHA256: widget.sha256)
    }

    /// Same staging behavior as `download(_:)` but takes a bare URL —
    /// used by the `macstash-dock://install-widget?url=...` URL scheme handler
    /// where there's no MarketplaceWidget struct on hand. Pass an
    /// `expectedSHA256` (hex) to refuse installs whose downloaded
    /// payload doesn't match.
    func downloadBundle(from url: URL, expectedSHA256: String? = nil) async throws -> URL {
        let (tempFile, response) = try await session.download(from: url)
        try Self.validateHTTP(response)

        let workDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacStash-Marketplace-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)

        let lastPath = url.lastPathComponent
        let suffix = lastPath.hasSuffix(".zip") ? ".zip" : ".stashwidget"
        let destination = workDir.appendingPathComponent("payload\(suffix)")
        try FileManager.default.moveItem(at: tempFile, to: destination)

        if let expectedSHA256 {
            let actual = try Self.sha256(of: destination)
            guard actual.caseInsensitiveCompare(expectedSHA256) == .orderedSame else {
                throw MarketplaceError.sha256Mismatch(expected: expectedSHA256, actual: actual)
            }
        }

        let stagedBundle: URL
        if suffix == ".zip" {
            stagedBundle = try unpackZip(at: destination, into: workDir)
        } else {
            stagedBundle = destination
        }

        guard FileManager.default.fileExists(atPath: stagedBundle.path) else {
            throw MarketplaceError.bundleMissing
        }

        return stagedBundle
    }

    private func unpackZip(at zipURL: URL, into workDir: URL) throws -> URL {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", zipURL.path, "-d", workDir.path]
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw MarketplaceError.unzipFailed(Int(process.terminationStatus))
        }

        guard let bundle = findWidgetBundle(in: workDir) else {
            throw MarketplaceError.bundleMissing
        }
        return bundle
    }

    private func findWidgetBundle(in directory: URL) -> URL? {
        let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil)
        while let item = enumerator?.nextObject() as? URL {
            if item.pathExtension == "stashwidget" { return item }
        }
        return nil
    }

    private static func validateHTTP(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw MarketplaceError.http(http.statusCode)
        }
    }

    private static func sha256(of url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        while autoreleasepool(invoking: {
            let chunk = handle.readData(ofLength: 64 * 1024)
            guard !chunk.isEmpty else { return false }
            hasher.update(data: chunk)
            return true
        }) {}
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

enum MarketplaceError: LocalizedError {
    case http(Int)
    case unzipFailed(Int)
    case bundleMissing
    case sha256Mismatch(expected: String, actual: String)

    var errorDescription: String? {
        switch self {
        case .http(let code):
            "Marketplace responded with HTTP \(code)."
        case .unzipFailed(let code):
            "Couldn't unzip the widget archive (exit code \(code))."
        case .bundleMissing:
            "The downloaded archive doesn't contain a .stashwidget bundle."
        case .sha256Mismatch(let expected, let actual):
            "Download SHA-256 mismatch.\nExpected: \(expected)\nGot: \(actual)"
        }
    }
}
