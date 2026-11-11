import SwiftUI
import AppKit
import UniformTypeIdentifiers
import MacStashCore

public struct AboutTab: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var updater = AutoUpdateManager.shared

    @State private var statusBannerText: String? = nil
    @State private var statusBannerIsError: Bool = false
    @State private var showResetConfirmation: Bool = false

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Section 1: Hero App Identity & Updates
            SettingsCard(
                title: appState.localized("about.title"),
                systemImage: "sparkles.rectangle.stack.fill",
                accentColor: .blue
            ) {
                HStack(spacing: 16) {
                    StashBrandLogoView(size: 56, showWordmark: false)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("MacStash")
                                .font(.system(size: 18, weight: .bold))

                            if updater.updateAvailable {
                                StatusBadgePill(
                                    text: "\(appState.localized("about.updateAvailable")) v\(updater.latestVersion)",
                                    color: .orange
                                )
                            } else {
                                StatusBadgePill(
                                    text: appState.localized("about.upToDate"),
                                    color: .green
                                )
                            }
                        }

                        Text(appState.localized("about.version"))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)

                        Text(appState.localized("about.subtitle"))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(appState.localized("about.lastChecked")) \(formattedLastCheckDate)")
                            .font(.system(size: 11.5))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button {
                        updater.checkForUpdates(silent: false)
                    } label: {
                        HStack(spacing: 6) {
                            if updater.isChecking {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                            Text(appState.localized(updater.isChecking ? "about.checking" : "about.checkForUpdates"))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(updater.isChecking || !updater.canCheckForUpdates)
                }
            }

            // Section 2: Diagnostics & Resources
            SettingsCard(
                title: appState.localized("about.diagnostics"),
                systemImage: "stethoscope",
                accentColor: .teal
            ) {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle(appState.localized("about.debugLogging"), isOn: $appState.settings.debugLoggingEnabled)
                        .font(.system(size: 12.5, weight: .medium))
                    Text(appState.localized("about.debugHint"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Divider()

                HStack(spacing: 10) {
                    Button {
                        openConsoleApp()
                    } label: {
                        Label(appState.localized("about.openConsole"), systemImage: "terminal")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button {
                        if let delegate = NSApp.delegate as? AppDelegate {
                            delegate.openHelp()
                        } else {
                            AppLogger.lifecycle.notice("Unable to locate AppDelegate to open User Guide.")
                        }
                    } label: {
                        Label(appState.localized("about.openGuide"), systemImage: "book.fill")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            // Section 3: Configuration Backup & Restore
            SettingsCard(
                title: appState.localized("about.backupRestore"),
                systemImage: "externaldrive.badge.timemachine",
                accentColor: .indigo
            ) {
                HStack(spacing: 10) {
                    Button {
                        exportSettingsJSON()
                    } label: {
                        Label(appState.localized("about.exportJSON"), systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button {
                        importSettingsJSON()
                    } label: {
                        Label(appState.localized("about.importJSON"), systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                if let banner = statusBannerText {
                    HStack(spacing: 8) {
                        Image(systemName: statusBannerIsError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .foregroundColor(statusBannerIsError ? .red : .green)
                        Text(banner)
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(statusBannerIsError ? .red : .primary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill((statusBannerIsError ? Color.red : Color.green).opacity(0.12))
                    )
                }
            }

            // Section 4: Factory Reset
            SettingsCard(
                title: appState.localized("about.factoryReset"),
                systemImage: "trash.circle.fill",
                accentColor: .red
            ) {
                HStack {
                    Text(appState.localized("general.resetDesc"))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Spacer()

                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Text(appState.localized("about.resetAllButton"))
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
        }
        .alert(appState.localized("general.resetAlertTitle"), isPresented: $showResetConfirmation) {
            Button(appState.localized("general.cancel"), role: .cancel) {}
            Button(appState.localized("general.resetConfirm"), role: .destructive) {
                appState.resetToDefaults()
            }
        } message: {
            Text(appState.localized("general.resetAlertMessage"))
        }
    }

    // MARK: - Helpers

    private var formattedLastCheckDate: String {
        guard let date = updater.lastCheckDate else {
            return appState.localized("about.neverChecked")
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func openConsoleApp() {
        let consoleURL = URL(fileURLWithPath: "/System/Applications/Utilities/Console.app")
        NSWorkspace.shared.open(consoleURL)
    }

    private func exportSettingsJSON() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.json]
        panel.nameFieldStringValue = "MacStash-Settings.json"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                let data = try appState.persistence.exportJSON(settings: appState.settings)
                try data.write(to: url)
                statusBannerIsError = false
                statusBannerText = appState.localized("about.exportSuccess")
                AppLogger.settings.info("Exported settings JSON to \(url.path, privacy: .public)")
            } catch {
                statusBannerIsError = true
                statusBannerText = "\(appState.localized("about.importError")): \(error.localizedDescription)"
                AppLogger.settings.error("Failed to export settings JSON: \(error.localizedDescription)")
            }
        }
    }

    private func importSettingsJSON() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.json]
        panel.allowsMultipleSelection = false
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                let data = try Data(contentsOf: url)
                let imported = try appState.persistence.importJSON(data: data)
                appState.settings = imported
                statusBannerIsError = false
                statusBannerText = appState.localized("about.importSuccess")
                AppLogger.settings.info("Imported settings JSON from \(url.path, privacy: .public)")
            } catch {
                statusBannerIsError = true
                statusBannerText = "\(appState.localized("about.importError")): \(error.localizedDescription)"
                AppLogger.settings.error("Failed to import settings JSON: \(error.localizedDescription)")
            }
        }
    }
}
