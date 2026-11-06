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
            GroupBox(label: Label("About MacStash", systemImage: "info.circle")) {
                HStack(spacing: 16) {
                    StashBrandLogoView(size: 52)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("MacStash")
                            .font(.system(size: 16, weight: .bold))
                        Text("Version 2.1.0 (Universal arm64 / x86_64)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("Tactile Hot Corner Dials & Display Controls for macOS")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(8)
            }

            GroupBox(label: Label("Diagnostics & Logging", systemImage: "stethoscope")) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable Detailed Debug Logging", isOn: $appState.settings.debugLoggingEnabled)
                    Text("Logs subsystem output to macOS Unified Logging System (com.macstash.app).")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    HStack {
                        Button("Open Logs in Console") {
                            openConsoleApp()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button("Open User Guide") {
                            openUserGuide()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(8)
            }

            GroupBox(label: Label("Configuration Backup & Migration", systemImage: "arrow.triangle.2.circlepath")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Button("Export Settings to JSON...") {
                            exportSettings()
                        }
                        .buttonStyle(.bordered)

                        Button("Import Settings from JSON...") {
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
                        Text("Settings successfully restored and verified!")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
                .padding(8)
            }

            HStack {
                Spacer()
                Button(role: .destructive, action: { showingResetConfirmation = true }) {
                    Label("Factory Reset Application", systemImage: "trash")
                }
                .confirmationDialog(
                    "Factory Reset MacStash?",
                    isPresented: $showingResetConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Erase All Data and Defaults", role: .destructive) {
                        appState.resetToDefaults()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This resets all profiles, display bindings, and corner actions to original factory condition.")
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
        if let url = URL(string: "https://www.stashformac.com") {
            NSWorkspace.shared.open(url)
        }
    }

    private func exportSettings() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "MacStash-Settings-Backup.json"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                let data = try appState.persistence.exportJSON(settings: appState.settings)
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
                let imported = try appState.persistence.importJSON(data: data)
                Task { @MainActor in
                    appState.settings = imported
                    showImportSuccess = true
                    importErrorMessage = nil
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
