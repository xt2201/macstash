import Foundation
import AppKit
import Combine
import Sparkle
import MacStashCore

/// Manages version checking, changelog presentation, and seamless updates for MacStash via Sparkle 2
@MainActor
public final class AutoUpdateManager: NSObject, ObservableObject, SPUUpdaterDelegate {
    public static let shared = AutoUpdateManager()

    @Published public private(set) var currentVersion: String = "2.3.2"
    @Published public private(set) var latestVersion: String = "2.3.2"
    @Published public private(set) var updateAvailable: Bool = false
    @Published public private(set) var releaseNotes: String = ""
    @Published public private(set) var releaseURL: String = ""
    @Published public private(set) var isChecking: Bool = false
    @Published public private(set) var lastCheckDate: Date? = nil
    @Published public private(set) var canCheckForUpdates: Bool = true

    private var updaterController: SPUStandardUpdaterController?

    public override init() {
        super.init()

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.currentVersion = version
            self.latestVersion = version
        }

        let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || NSClassFromString("XCTestCase") != nil

        if !isRunningTests {
            let controller = SPUStandardUpdaterController(
                startingUpdater: true,
                updaterDelegate: self,
                userDriverDelegate: nil
            )
            self.updaterController = controller
            self.canCheckForUpdates = controller.updater.canCheckForUpdates
        }
    }

    public func checkForUpdates(silent: Bool = false) {
        guard let controller = updaterController else {
            AppLogger.updates.notice("Update controller not initialized (e.g. running in test harness).")
            return
        }

        isChecking = true
        lastCheckDate = Date()
        AppLogger.updates.info("Initiating update check (silent: \(silent, privacy: .public)).")

        if silent {
            controller.updater.checkForUpdatesInBackground()
        } else {
            controller.checkForUpdates(nil)
        }
    }

    // MARK: - SPUUpdaterDelegate

    public func updater(_ updater: SPUUpdater, didFinishUpdateCycleFor updateCheck: SPUUpdateCheck, error: (any Error)?) {
        isChecking = false
        if let error = error {
            let nsError = error as NSError
            if nsError.domain == "SUSparkleErrorDomain" && nsError.code == 1001 {
                AppLogger.updates.info("Update cycle finished: app is up to date.")
            } else {
                AppLogger.updates.error("Update cycle finished with error: \(error.localizedDescription, privacy: .public)")
            }
        } else {
            AppLogger.updates.info("Update cycle finished successfully.")
        }
    }

    public func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        latestVersion = item.displayVersionString
        updateAvailable = true
        releaseNotes = item.itemDescription ?? ""
        if let url = item.fileURL ?? item.infoURL {
            releaseURL = url.absoluteString
        }
        AppLogger.updates.info("Found valid update version \(item.displayVersionString, privacy: .public).")
    }

    public func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        updateAvailable = false
        AppLogger.updates.info("No updates found. Running latest version.")
    }

    public func updater(_ updater: SPUUpdater, didAbortWithError error: any Error) {
        isChecking = false
        AppLogger.updates.error("Update check aborted with error: \(error.localizedDescription, privacy: .public)")
    }
}
