import SwiftUI
import AppKit
import os.log
import SideDockCore
import MacStashCore

public struct DockProfilesSection: View {
    private static let logger = Logger(subsystem: "com.macstash.app", category: "sidedock")

    @Binding public var config: SideDockFileConfig
    public let activeProfileIndex: Int
    public let onSave: (Bool) -> Void
    public let onResetLayout: () -> Void
    public let onOpenWidgetGallery: () -> Void

    @State private var newProfileName: String = ""
    @State private var isCreatingProfile: Bool = false
    @State private var triggerAppBundleInput: String = ""

    public init(
        config: Binding<SideDockFileConfig>,
        activeProfileIndex: Int,
        onSave: @escaping (Bool) -> Void,
        onResetLayout: @escaping () -> Void,
        onOpenWidgetGallery: @escaping () -> Void
    ) {
        self._config = config
        self.activeProfileIndex = activeProfileIndex
        self.onSave = onSave
        self.onResetLayout = onResetLayout
        self.onOpenWidgetGallery = onOpenWidgetGallery
    }

    private func localized(_ key: String) -> String {
        LocalizationService.shared.localized(key)
    }

    private var triggerBinding: Binding<ProfileTriggerRule> {
        $config.profiles[activeProfileIndex].triggerRule
    }

    public var body: some View {
        DockSettingsCard(title: localized("dock.profilesTitle"), systemImage: "square.stack.3d.up", accent: .purple) {
            HStack(spacing: 8) {
                Text(localized("dock.activeProfile"))
                    .font(.system(size: 12, weight: .medium))

                Picker("", selection: $config.activeProfileId) {
                    ForEach(config.profiles) { prof in
                        Text(prof.name).tag(prof.id)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 180)
                .onChange(of: config.activeProfileId) { _, _ in onSave(true) }

                Spacer()

                Button { exportCurrentProfile() } label: {
                    Label(localized("dock.export"), systemImage: "square.and.arrow.up")
                }

                Button { importProfileFromFile() } label: {
                    Label(localized("dock.import"), systemImage: "square.and.arrow.down")
                }

                Button { isCreatingProfile = true } label: {
                    Label(localized("dock.newProfile"), systemImage: "plus")
                }

                if config.profiles.count > 1 {
                    Button(role: .destructive) {
                        deleteCurrentProfile()
                    } label: {
                        Image(systemName: "trash").foregroundColor(.red)
                    }
                    .help(localized("dock.delete"))
                }
            }

            if isCreatingProfile {
                HStack {
                    TextField(localized("dock.profileNamePlaceholder"), text: $newProfileName)
                        .textFieldStyle(.roundedBorder)
                    Button(localized("dock.create")) { createNewProfile() }
                        .buttonStyle(.borderedProminent)
                        .disabled(newProfileName.trimmingCharacters(in: .whitespaces).isEmpty)
                    Button(localized("dock.cancel")) {
                        isCreatingProfile = false
                        newProfileName = ""
                    }
                }
            }

            Divider()

            Toggle(localized("dock.profileAutoTrigger"), isOn: Binding(
                get: { triggerBinding.wrappedValue.isEnabled },
                set: { triggerBinding.wrappedValue.isEnabled = $0; onSave(false) }
            ))

            if triggerBinding.wrappedValue.isEnabled {
                HStack(spacing: 8) {
                    TextField("com.apple.dt.Xcode", text: $triggerAppBundleInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11))
                    Button(localized("dock.add")) {
                        let trimmed = triggerAppBundleInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        if !triggerBinding.wrappedValue.activeAppBundleIDs.contains(trimmed) {
                            triggerBinding.wrappedValue.activeAppBundleIDs.append(trimmed)
                            onSave(false)
                        }
                        triggerAppBundleInput = ""
                    }
                    .disabled(triggerAppBundleInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if !triggerBinding.wrappedValue.activeAppBundleIDs.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(triggerBinding.wrappedValue.activeAppBundleIDs, id: \.self) { bid in
                                HStack(spacing: 4) {
                                    Text(bid).font(.system(size: 10.5))
                                    Button {
                                        triggerBinding.wrappedValue.activeAppBundleIDs.removeAll { $0 == bid }
                                        onSave(false)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.primary.opacity(0.08)))
                            }
                        }
                    }
                }
            }

            Divider()

            HStack {
                Button {
                    onOpenWidgetGallery()
                } label: {
                    Label(localized("dock.browseWidgets"), systemImage: "plus.rectangle.on.rectangle")
                }
                .buttonStyle(.borderedProminent)

                Spacer()

                Button(role: .destructive) {
                    onResetLayout()
                } label: {
                    Label(localized("dock.resetLayout"), systemImage: "arrow.counterclockwise")
                }
                .help(localized("dock.resetLayoutHelp"))
            }
        }
    }

    private func createNewProfile() {
        let trimmed = newProfileName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let newProf = DockProfile(name: trimmed, items: config.profiles[activeProfileIndex].items)
        config.profiles.append(newProf)
        config.activeProfileId = newProf.id
        newProfileName = ""
        isCreatingProfile = false
        onSave(true)
    }

    private func deleteCurrentProfile() {
        guard config.profiles.count > 1 else { return }
        config.profiles.remove(at: activeProfileIndex)
        config.activeProfileId = config.profiles.first?.id ?? UUID()
        onSave(true)
    }

    private func exportCurrentProfile() {
        let prof = config.profiles[activeProfileIndex]
        let service = DockProfileTransferService()
        do {
            let data = try service.exportProfileJSON(profile: prof)
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.json]
            savePanel.nameFieldStringValue = "\(prof.name.replacingOccurrences(of: " ", with: "_")).sidedock-profile"
            savePanel.prompt = "Export"
            if savePanel.runModal() == .OK, let url = savePanel.url {
                try data.write(to: url, options: .atomic)
            }
        } catch {
            Self.logger.error("Export profile failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func importProfileFromFile() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.prompt = "Import"

        if openPanel.runModal() == .OK, let url = openPanel.url {
            do {
                let data = try Data(contentsOf: url)
                let service = DockProfileTransferService()
                let imported = try service.importProfile(from: data)
                config.profiles.append(imported)
                config.activeProfileId = imported.id
                onSave(true)
            } catch {
                Self.logger.error("Import profile failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
