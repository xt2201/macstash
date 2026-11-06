import Foundation
import AppKit
import Combine

/// Manages version checking, changelog presentation, and seamless updates for MacStash
@MainActor
public final class AutoUpdateManager: ObservableObject {
    public static let shared = AutoUpdateManager()

    @Published public private(set) var currentVersion: String = "2.0.0"
    @Published public private(set) var latestVersion: String = "2.0.0"
    @Published public private(set) var updateAvailable: Bool = false
    @Published public private(set) var releaseNotes: String = ""
    @Published public private(set) var releaseURL: String = ""
    @Published public private(set) var isChecking: Bool = false
    @Published public private(set) var lastCheckDate: Date? = nil

    private let updateFeedURL = URL(string: "https://api.github.com/repos/xt2201/macstash/releases/latest")

    private init() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.currentVersion = version
        }
    }

    public func checkForUpdates(silent: Bool = false) {
        isChecking = true
        lastCheckDate = Date()

        guard let url = updateFeedURL else {
            isChecking = false
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue("MacStash/\(currentVersion)", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isChecking = false
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String else {
                if !silent {
                    DispatchQueue.main.async {
                        self?.showUpToDateAlert()
                    }
                }
                return
            }

            let remoteVersion = tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            let notes = (json["body"] as? String) ?? "Bug fixes and performance improvements."
            let htmlURL = (json["html_url"] as? String) ?? "https://github.com/xt2201/macstash/releases"

            DispatchQueue.main.async {
                self?.latestVersion = remoteVersion
                self?.releaseNotes = notes
                self?.releaseURL = htmlURL

                if self?.isVersion(remoteVersion, greaterThan: self?.currentVersion ?? "2.0.0") == true {
                    self?.updateAvailable = true
                    if !silent {
                        self?.showUpdateAvailableAlert(version: remoteVersion, notes: notes, url: htmlURL)
                    }
                } else if !silent {
                    self?.showUpToDateAlert()
                }
            }
        }.resume()
    }

    private func isVersion(_ v1: String, greaterThan v2: String) -> Bool {
        v1.compare(v2, options: .numeric) == .orderedDescending
    }

    private func showUpToDateAlert() {
        let alert = NSAlert()
        alert.messageText = "MacStash is Up to Date"
        alert.informativeText = "You are currently running the latest version (v\(currentVersion))."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showUpdateAvailableAlert(version: String, notes: String, url: String) {
        let alert = NSAlert()
        alert.messageText = "A New Version of MacStash is Available! (v\(version))"
        alert.informativeText = "Release Notes:\n\n\(notes)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Download & Install")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            if let targetURL = URL(string: url) {
                NSWorkspace.shared.open(targetURL)
            }
        }
    }
}
