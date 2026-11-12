import Foundation
import AppKit
import os.log

public enum LaunchpadAppCategory: String, CaseIterable, Sendable {
    case all = "All"
    case productivity = "Productivity"
    case developer = "Developer"
    case utilities = "Utilities"
    case internet = "Internet"
    case media = "Media"

    public static func classify(utiCategory: String?) -> LaunchpadAppCategory {
        guard let cat = utiCategory?.lowercased() else { return .utilities }
        if cat.contains("developer") { return .developer }
        if cat.contains("productivity") || cat.contains("business") || cat.contains("education") { return .productivity }
        if cat.contains("social") || cat.contains("news") || cat.contains("browser") { return .internet }
        if cat.contains("music") || cat.contains("video") || cat.contains("photo") || cat.contains("graphics") || cat.contains("entertainment") { return .media }
        return .utilities
    }
}

public struct LaunchpadAppEntry: Identifiable, Equatable, Sendable {
    public var id: String { path }
    public let name: String
    public let bundleIdentifier: String
    public let path: String
    public let category: LaunchpadAppCategory

    public init(name: String, bundleIdentifier: String, path: String, category: LaunchpadAppCategory = .utilities) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.path = path
        self.category = category
    }
}

public actor LaunchpadService {
    public static let shared = LaunchpadService()
    private static let logger = Logger(subsystem: "com.macstash.app", category: "launchpad")

    private var cachedApps: [LaunchpadAppEntry] = []

    public func installedApps(forceRefresh: Bool = false) -> [LaunchpadAppEntry] {
        if !forceRefresh && !cachedApps.isEmpty {
            return cachedApps
        }

        let searchDirs = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities",
            (NSHomeDirectory() as NSString).appendingPathComponent("Applications")
        ]

        var seenPaths = Set<String>()
        var found: [LaunchpadAppEntry] = []

        for dir in searchDirs {
            let dirURL = URL(fileURLWithPath: dir)
            guard let items = try? FileManager.default.contentsOfDirectory(
                at: dirURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else { continue }

            for url in items where url.pathExtension == "app" {
                let path = url.path
                guard seenPaths.insert(path).inserted else { continue }
                let bundle = Bundle(url: url)
                let bid = bundle?.bundleIdentifier ?? url.deletingPathExtension().lastPathComponent
                let utiCat = bundle?.infoDictionary?["LSApplicationCategoryType"] as? String
                let name = FileManager.default.displayName(atPath: path)
                    .replacingOccurrences(of: ".app", with: "")
                found.append(LaunchpadAppEntry(
                    name: name,
                    bundleIdentifier: bid,
                    path: path,
                    category: LaunchpadAppCategory.classify(utiCategory: utiCat)
                ))
            }
        }

        found.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        cachedApps = found
        Self.logger.debug("Indexed \(found.count) applications for Launchpad")
        return found
    }
}
