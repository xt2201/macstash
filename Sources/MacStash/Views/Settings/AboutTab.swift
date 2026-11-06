import SwiftUI
import AppKit
import MacStashCore

public struct AboutTab: View {
    @ObservedObject var appState: AppState
    @State private var importErrorMessage: String?
    @State private var showImportSuccess: Bool = false
    @State private var showingResetConfirmation: Bool = false

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            GroupBox(label: Label(appState.localized("about.title"), systemImage: "info.circle")) {
                HStack(spacing: 16) {
                    StashBrandLogoView(size: 52)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("MacStash")
                            .font(.system(size: 16, weight: .bold))
                        Text(appState.localized("about.version"))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text(appState.localized("about.subtitle"))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: {
                        appState.updater.checkForUpdates(silent: false)
                    }) {
                        Label(appState.updater.isChecking ? "Checking..." : "Check for Updates...", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(appState.updater.isChecking)
                }
                .padding(8)
            }

            GroupBox(label: Label(appState.localized("about.diagnostics"), systemImage: "stethoscope")) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(appState.localized("about.debugLogging"), isOn: $appState.settings.debugLoggingEnabled)
                    Text(appState.localized("about.debugHint"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    HStack {
                        Button(appState.localized("about.openConsole")) {
                            openConsoleApp()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button(appState.localized("about.openGuide")) {
                            openUserGuide()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(8)
            }

            GroupBox(label: Label(appState.localized("about.backupRestore"), systemImage: "arrow.triangle.2.circlepath")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Button(appState.localized("about.exportJSON")) {
                            exportSettings()
                        }
                        .buttonStyle(.bordered)

                        Button(appState.localized("about.importJSON")) {
                            importSettings()
                        }
                        .buttonStyle(.bordered)
                    }

                    if let err = importErrorMessage {
                        Text("Import Error: \(err)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.red)
                    }

                    if showImportSuccess {
                        Text(appState.localized("about.importSuccess"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
                .padding(8)
            }

            HStack {
                Spacer()
                Button(role: .destructive, action: { showingResetConfirmation = true }) {
                    Label(appState.localized("about.resetAllButton"), systemImage: "trash")
                }
                .confirmationDialog(
                    appState.localized("general.resetAlertTitle"),
                    isPresented: $showingResetConfirmation,
                    titleVisibility: .visible
                ) {
                    Button(appState.localized("general.resetConfirm"), role: .destructive) {
                        appState.resetToDefaults()
                    }
                    Button(appState.localized("general.cancel"), role: .cancel) {}
                } message: {
                    Text(appState.localized("general.resetAlertMessage"))
                }
            }
        }
    }

    private func openConsoleApp() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Console") {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        }
    }

    private func openUserGuide() {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.openHelp()
        }
    }

    private struct FullBackupPayload: Codable {
        let settings: AppSettings
        let appProfiles: [AppProfile]?
    }

    private func exportSettings() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "MacStash-Settings-Backup.json"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                let payload = FullBackupPayload(settings: appState.settings, appProfiles: appState.appProfiles)
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(payload)
                try data.write(to: url, options: .atomic)
            } catch {
                AppLogger.settings.error("Failed to export settings JSON: \(error.localizedDescription)")
            }
        }
    }

    private func importSettings() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                let data = try Data(contentsOf: url)
                if let payload = try? JSONDecoder().decode(FullBackupPayload.self, from: data) {
                    Task { @MainActor in
                        appState.settings = payload.settings
                        if let profs = payload.appProfiles, !profs.isEmpty {
                            appState.appProfiles = profs
                            appState.saveSettings()
                        }
                        showImportSuccess = true
                        importErrorMessage = nil
                    }
                } else {
                    let imported = try appState.persistence.importJSON(data: data)
                    Task { @MainActor in
                        appState.settings = imported
                        showImportSuccess = true
                        importErrorMessage = nil
                    }
                }
            } catch {
                Task { @MainActor in
                    importErrorMessage = error.localizedDescription
                    showImportSuccess = false
                }
            }
        }
    }
}
