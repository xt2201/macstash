import AppKit
import os.log
import SideDockCore
import SideDockWidgets
import SideDockUI

extension SideDockManager {
    public func pinRunningApp(_ app: RunningAppInfo) {
        guard let url = app.bundleURL else { return }
        let bid = app.bundleIdentifier ?? url.deletingPathExtension().lastPathComponent
        let face = AppWidgetFaceRegistry.defaultWidgetKind(forBundleID: bid)
        let appItem = AppItem(
            bundleIdentifier: bid,
            displayName: app.localizedName,
            appPath: url.path,
            widgetFaceKind: face
        )
        configStore.updateConfig(immediate: true) { cfg in
            guard let pIdx = cfg.profiles.firstIndex(where: { $0.id == cfg.activeProfileId }) else { return }
            let alreadyPinned = cfg.profiles[pIdx].items.contains { item in
                if case .app(let existing) = item { return existing.bundleIdentifier == bid }
                return false
            }
            if !alreadyPinned {
                cfg.profiles[pIdx].items.append(.app(appItem))
            }
        }
        self.config = configStore.config
        updateDockLayout()
    }

    public func hideFromRunningApps(_ bundleID: String) {
        guard !bundleID.isEmpty else { return }
        configStore.updateConfig(immediate: true) { cfg in
            guard let pIdx = cfg.profiles.firstIndex(where: { $0.id == cfg.activeProfileId }) else { return }
            if !cfg.profiles[pIdx].layoutConfig.hiddenRunningBundleIDs.contains(bundleID) {
                cfg.profiles[pIdx].layoutConfig.hiddenRunningBundleIDs.append(bundleID)
            }
        }
        self.config = configStore.config
        updateDockLayout()
    }

    public func hideOtherApps(exceptBundleID: String) {
        for app in NSWorkspace.shared.runningApplications
        where app.activationPolicy == .regular &&
              app.bundleIdentifier != exceptBundleID &&
              app.bundleIdentifier != Bundle.main.bundleIdentifier {
            app.hide()
        }
    }

    public func updateFolderPreferences(id: UUID, style: FolderPresentationStyle, sortOrder: FolderSortOrder) {
        configStore.updateConfig { cfg in
            guard let pIdx = cfg.profiles.firstIndex(where: { $0.id == cfg.activeProfileId }),
                  let iIdx = cfg.profiles[pIdx].items.firstIndex(where: { $0.id == id }),
                  case .folder(var folder) = cfg.profiles[pIdx].items[iIdx] else { return }
            folder.presentationStyle = style
            folder.sortOrder = sortOrder
            cfg.profiles[pIdx].items[iIdx] = .folder(folder)
        }
        self.config = configStore.config
    }

    public func addQuickItem(_ item: DockItem) {
        configStore.updateConfig(immediate: true) { cfg in
            guard let pIdx = cfg.profiles.firstIndex(where: { $0.id == cfg.activeProfileId }) else { return }
            cfg.profiles[pIdx].items.append(item)
        }
        self.config = configStore.config
        updateDockLayout()
    }

    public func performDockInteractionFeedback() {
        guard activeProfile.layoutConfig.dockSoundFeedback else { return }
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        NSSound(named: "Tink")?.play()
    }
}
