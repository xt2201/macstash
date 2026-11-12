import SwiftUI
import AppKit
import UniformTypeIdentifiers
import SideDockCore
import SideDockWidgets
import MacStashCore
import MacStashDesignSystem

public struct AppFolderEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let existing: AppFolderItem?
    public let onSave: (AppFolderItem) -> Void

    @State private var displayName: String
    @State private var selectedApps: [AppItem]
    @State private var showRunningAppsInline: Bool

    public init(existing: AppFolderItem? = nil, onSave: @escaping (AppFolderItem) -> Void) {
        self.existing = existing
        self.onSave = onSave
        _displayName = State(initialValue: existing?.displayName ?? "App Group")
        _selectedApps = State(initialValue: existing?.apps ?? [])
        _showRunningAppsInline = State(initialValue: existing?.showRunningAppsInline ?? true)
    }

    private func localized(_ key: String) -> String {
        LocalizationService.shared.localized(key)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(localized("dock.appFolderEditorTitle"))
                .font(.system(size: 15, weight: .bold))

            Divider()

            TextField("Folder Name", text: $displayName)
                .textFieldStyle(.roundedBorder)

            Toggle(localized("dock.showRunningInline"), isOn: $showRunningAppsInline)

            HStack {
                Text("Apps (\(selectedApps.count))")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Button {
                    pickApps()
                } label: {
                    Label(localized("dock.addApp"), systemImage: "plus.app")
                }
            }

            ScrollView {
                VStack(spacing: 4) {
                    ForEach(selectedApps) { app in
                        HStack(spacing: 8) {
                            Image(nsImage: AppIconCache.shared.icon(forPath: app.appPath, targetSize: NSSize(width: 20, height: 20)))
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text(app.displayName)
                                .font(.system(size: 12))
                            Spacer()
                            Button {
                                selectedApps.removeAll { $0.id == app.id }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.05)))
                    }
                }
            }
            .frame(height: 170)

            Divider()

            HStack {
                Spacer()
                Button(localized("dock.cancel")) { dismiss() }
                    .buttonStyle(.bordered)
                Button(localized("dock.done")) {
                    let folder = AppFolderItem(
                        id: existing?.id ?? UUID(),
                        displayName: displayName.trimmingCharacters(in: .whitespaces).isEmpty ? "App Group" : displayName,
                        apps: selectedApps,
                        showRunningAppsInline: showRunningAppsInline,
                        customIconPath: existing?.customIconPath,
                        tintColorHex: existing?.tintColorHex
                    )
                    onSave(folder)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedApps.isEmpty)
            }
        }
        .padding(18)
        .frame(width: 400)
    }

    private func pickApps() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            for url in panel.urls {
                let bid = Bundle(url: url)?.bundleIdentifier ?? url.deletingPathExtension().lastPathComponent
                let name = FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
                if !selectedApps.contains(where: { $0.bundleIdentifier == bid }) {
                    let face = AppWidgetFaceRegistry.defaultWidgetKind(forBundleID: bid)
                    selectedApps.append(AppItem(bundleIdentifier: bid, displayName: name, appPath: url.path, widgetFaceKind: face))
                }
            }
        }
    }
}
