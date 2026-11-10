import SwiftUI
import AppKit
import UniformTypeIdentifiers
import SideDockCore
import SideDockWidgets
import MacStashCore

public struct DockSettingsTabView: View {
    @Binding public var config: SideDockFileConfig
    public let onSave: (Bool) -> Void
    public let onResetLayout: () -> Void

    @State private var showWidgetGallery: Bool = false
    @State private var newProfileName: String = ""
    @State private var isCreatingProfile: Bool = false

    private func localized(_ key: String) -> String {
        LocalizationService.shared.localized(key)
    }

    public init(
        config: Binding<SideDockFileConfig>,
        onSave: @escaping (Bool) -> Void,
        onResetLayout: @escaping () -> Void
    ) {
        self._config = config
        self.onSave = onSave
        self.onResetLayout = onResetLayout
    }

    private var activeProfileIndex: Int {
        if let idx = config.profiles.firstIndex(where: { $0.id == config.activeProfileId }) {
            return idx
        }
        return 0
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
                // Section 1: Core Toggle & Placement
                GroupBox(label: Text(localized("dock.configTitle")).font(.headline)) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(localized("dock.enableSecondDock"), isOn: $config.isDockVisible)
                            .onChange(of: config.isDockVisible) { _, _ in onSave(true) }

                        Divider()

                        Picker(localized("dock.placement"), selection: bindingForPlacement) {
                            Text(localized("dock.placementFixedBottom")).tag(DockPlacement.fixedBottom)
                            Text(localized("dock.placementFloating")).tag(DockPlacement.floating)
                            Text(localized("dock.placementFixedTop")).tag(DockPlacement.fixedTop)
                            Text(localized("dock.placementFixedLeft")).tag(DockPlacement.fixedLeft)
                            Text(localized("dock.placementFixedRight")).tag(DockPlacement.fixedRight)
                        }
                        .pickerStyle(.menu)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(localized("dock.scale"))
                                Spacer()
                                Text("\(String(format: "%.1f", config.profiles[activeProfileIndex].layoutConfig.scale))x")
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                            }
                            Slider(value: bindingForScale, in: 0.7...1.5, step: 0.05)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(localized("dock.tileSpacing"))
                                Spacer()
                                Text("\(Int(config.profiles[activeProfileIndex].layoutConfig.tileSpacing)) px")
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                            }
                            Slider(value: bindingForSpacing, in: 4.0...24.0, step: 1.0)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(localized("dock.edgeOffset"))
                                Spacer()
                                Text("\(Int(config.profiles[activeProfileIndex].layoutConfig.bottomOffset)) px")
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                            }
                            Slider(value: bindingForBottomOffset, in: 0.0...60.0, step: 2.0)
                        }
                    }
                    .padding(8)
                }

                // Section 2: Auto-Hide & Edge Triggers
                GroupBox(label: Text(localized("dock.behaviorTitle")).font(.headline)) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(localized("dock.autoHide"), isOn: bindingForAutoHide)

                        if config.profiles[activeProfileIndex].layoutConfig.autoHide {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(localized("dock.revealDelay"))
                                    Spacer()
                                    Text("\(String(format: "%.1f", config.profiles[activeProfileIndex].layoutConfig.revealDelaySeconds)) s")
                                        .foregroundColor(.secondary)
                                        .monospacedDigit()
                                }
                                Slider(value: bindingForRevealDelay, in: 0.0...3.0, step: 0.1)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(localized("dock.edgeZone"))
                                    Spacer()
                                    Text("\(Int(config.profiles[activeProfileIndex].layoutConfig.edgeTriggerThickness)) px")
                                        .foregroundColor(.secondary)
                                        .monospacedDigit()
                                }
                                Slider(value: bindingForTriggerThickness, in: 2.0...20.0, step: 1.0)
                            }
                        }

                        Toggle(localized("dock.hideInFullscreen"), isOn: bindingForFullscreen)
                        Toggle(localized("dock.hideOnHover"), isOn: bindingForHover)
                        Toggle(localized("dock.reserveSpace"), isOn: bindingForReserve)
                        Toggle(localized("dock.showRunningApps"), isOn: bindingForRunningApps)
                    }
                    .padding(8)
                }

                // Section 3: Appearance & Glass Style
                GroupBox(label: Text(localized("dock.appearanceTitle")).font(.headline)) {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker(localized("dock.backdropStyle"), selection: bindingForBackdrop) {
                            Text(localized("dock.backdropAuto")).tag(DockBackdropStyle.autoSystem)
                            Text(localized("dock.backdropLight")).tag(DockBackdropStyle.lightGlass)
                            Text(localized("dock.backdropDark")).tag(DockBackdropStyle.darkGlass)
                            Text(localized("dock.backdropLiquid")).tag(DockBackdropStyle.liquidGlass)
                            Text(localized("dock.backdropClear")).tag(DockBackdropStyle.clear)
                        }
                        .pickerStyle(.segmented)

                        Toggle(localized("dock.reduceMotion"), isOn: bindingForReduceMotion)
                    }
                    .padding(8)
                }

                // Section 4: Profiles & Widgets
                GroupBox(label: Text(localized("dock.profilesTitle")).font(.headline)) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Picker(localized("dock.activeProfile"), selection: $config.activeProfileId) {
                                ForEach(config.profiles) { prof in
                                    Text(prof.name).tag(prof.id)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: 240)

                            Spacer()

                            Button {
                                exportCurrentProfile()
                            } label: {
                                Label(localized("dock.export"), systemImage: "square.and.arrow.up")
                            }

                            Button {
                                importProfileFromFile()
                            } label: {
                                Label(localized("dock.import"), systemImage: "square.and.arrow.down")
                            }

                            Button {
                                isCreatingProfile = true
                            } label: {
                                Label(localized("dock.newProfile"), systemImage: "plus")
                            }

                            if config.profiles.count > 1 {
                                Button(role: .destructive) {
                                    deleteCurrentProfile()
                                } label: {
                                    Label(localized("dock.delete"), systemImage: "trash")
                                }
                            }
                        }

                        if isCreatingProfile {
                            HStack {
                                TextField(localized("dock.profileNamePlaceholder"), text: $newProfileName)
                                    .textFieldStyle(.roundedBorder)
                                Button(localized("dock.create")) {
                                    createNewProfile()
                                }
                                .disabled(newProfileName.trimmingCharacters(in: .whitespaces).isEmpty)
                                Button(localized("dock.cancel")) {
                                    isCreatingProfile = false
                                    newProfileName = ""
                                }
                            }
                        }

                        Divider()

                        HStack {
                            Button {
                                showWidgetGallery = true
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
                    .padding(8)
                }

                // Section 5: Dock Items & Applications
                GroupBox(label: Text(localized("dock.itemsTitle")).font(.headline)) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(localized("dock.itemsDesc"))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        if config.profiles[activeProfileIndex].items.isEmpty {
                            Text(localized("dock.noItems"))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            VStack(spacing: 4) {
                                ForEach(Array(config.profiles[activeProfileIndex].items.enumerated()), id: \.element.id) { idx, item in
                                    HStack(spacing: 8) {
                                        Image(systemName: item.systemIconName)
                                            .foregroundColor(.accentColor)
                                            .frame(width: 20)

                                        Text(item.displayName)
                                            .font(.system(size: 12, weight: .medium))

                                        Spacer()

                                        if idx > 0 {
                                            Button {
                                                moveItem(from: idx, to: idx - 1)
                                            } label: {
                                                Image(systemName: "chevron.up")
                                                    .font(.system(size: 10, weight: .bold))
                                            }
                                            .buttonStyle(.plain)
                                            .help(localized("dock.moveUp"))
                                        }

                                        if idx < config.profiles[activeProfileIndex].items.count - 1 {
                                            Button {
                                                moveItem(from: idx, to: idx + 1)
                                            } label: {
                                                Image(systemName: "chevron.down")
                                                    .font(.system(size: 10, weight: .bold))
                                            }
                                            .buttonStyle(.plain)
                                            .help(localized("dock.moveDown"))
                                        }

                                        Button(role: .destructive) {
                                            removeItem(at: idx)
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.system(size: 11))
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.plain)
                                        .help(localized("dock.remove"))
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.04)))
                                }
                            }
                        }

                        Divider()

                        HStack(spacing: 10) {
                            Button {
                                addApplication()
                            } label: {
                                Label(localized("dock.addApp"), systemImage: "plus.app")
                            }

                            Button {
                                config.profiles[activeProfileIndex].items.append(.separator(UUID()))
                                onSave(true)
                            } label: {
                                Label(localized("dock.addSeparator"), systemImage: "line.diagonal")
                            }

                            Button {
                                showWidgetGallery = true
                            } label: {
                                Label(localized("dock.addWidget"), systemImage: "plus.rectangle.on.rectangle")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(8)
                }
            }
            .padding(.bottom, 20)
            .sheet(isPresented: $showWidgetGallery) {
                WidgetGalleryView { newItem in
                    config.profiles[activeProfileIndex].items.append(.widget(newItem))
                    onSave(true)
                    showWidgetGallery = false
                }
            }
        }

    // MARK: - Bindings

    private var bindingForPlacement: Binding<DockPlacement> {
        Binding(
            get: { config.profiles[activeProfileIndex].layoutConfig.placement },
            set: { config.profiles[activeProfileIndex].layoutConfig.placement = $0; onSave(false) }
        )
    }

    private var bindingForScale: Binding<Double> {
        Binding(
            get: { config.profiles[activeProfileIndex].layoutConfig.scale },
            set: { config.profiles[activeProfileIndex].layoutConfig.scale = $0; onSave(false) }
        )
    }

    private var bindingForSpacing: Binding<Double> {
        Binding(
            get: { config.profiles[activeProfileIndex].layoutConfig.tileSpacing },
            set: { config.profiles[activeProfileIndex].layoutConfig.tileSpacing = $0; onSave(false) }
        )
    }

    private var bindingForBottomOffset: Binding<Double> {
        Binding(
            get: { config.profiles[activeProfileIndex].layoutConfig.bottomOffset },
            set: { config.profiles[activeProfileIndex].layoutConfig.bottomOffset = $0; onSave(false) }
        )
    }

    private var bindingForAutoHide: Binding<Bool> {
        Binding(
            get: { config.profiles[activeProfileIndex].layoutConfig.autoHide },
            set: { config.profiles[activeProfileIndex].layoutConfig.autoHide = $0; onSave(true) }
        )
    }

    private var bindingForRevealDelay: Binding<Double> {
        Binding(
            get: { config.profiles[activeProfileIndex].layoutConfig.revealDelaySeconds },
            set: { config.profiles[activeProfileIndex].layoutConfig.revealDelaySeconds = $0; onSave(false) }
        )
    }

    private var bindingForTriggerThickness: Binding<Double> {
        Binding(
            get: { config.profiles[activeProfileIndex].layoutConfig.edgeTriggerThickness },
            set: { config.profiles[activeProfileIndex].layoutConfig.edgeTriggerThickness = $0; onSave(false) }
        )
    }

    private var bindingForFullscreen: Binding<Bool> {
        Binding(
            get: { config.profiles[activeProfileIndex].layoutConfig.hideInFullscreen },
            set: { config.profiles[activeProfileIndex].layoutConfig.hideInFullscreen = $0; onSave(false) }
        )
    }

    private var bindingForHover: Binding<Bool> {
        Binding(
            get: { config.profiles[activeProfileIndex].layoutConfig.hideOnWindowHover },
            set: { config.profiles[activeProfileIndex].layoutConfig.hideOnWindowHover = $0; onSave(false) }
        )
    }

    private var bindingForReserve: Binding<Bool> {
        Binding(
            get: { config.profiles[activeProfileIndex].layoutConfig.reserveDockSpace },
            set: { config.profiles[activeProfileIndex].layoutConfig.reserveDockSpace = $0; onSave(false) }
        )
    }

    private var bindingForRunningApps: Binding<Bool> {
        Binding(
            get: { config.profiles[activeProfileIndex].layoutConfig.showRunningApps },
            set: { config.profiles[activeProfileIndex].layoutConfig.showRunningApps = $0; onSave(false) }
        )
    }

    private var bindingForBackdrop: Binding<DockBackdropStyle> {
        Binding(
            get: { config.profiles[activeProfileIndex].theme.backdropStyle },
            set: { config.profiles[activeProfileIndex].theme.backdropStyle = $0; onSave(true) }
        )
    }

    private var bindingForReduceMotion: Binding<Bool> {
        Binding(
            get: { config.profiles[activeProfileIndex].theme.reduceMotion },
            set: { config.profiles[activeProfileIndex].theme.reduceMotion = $0; onSave(false) }
        )
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
        let idx = activeProfileIndex
        config.profiles.remove(at: idx)
        config.activeProfileId = config.profiles.first?.id ?? UUID()
        onSave(true)
    }

    private func exportCurrentProfile() {
        let prof = config.profiles[activeProfileIndex]
        let service = DockProfileTransferService()
        guard let data = try? service.exportProfileJSON(profile: prof) else { return }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "\(prof.name.replacingOccurrences(of: " ", with: "_")).sidedock-profile"
        savePanel.prompt = "Export"

        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? data.write(to: url)
        }
    }

    private func importProfileFromFile() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.prompt = "Import"

        if openPanel.runModal() == .OK, let url = openPanel.url, let data = try? Data(contentsOf: url) {
            let service = DockProfileTransferService()
            if let imported = try? service.importProfile(from: data) {
                config.profiles.append(imported)
                config.activeProfileId = imported.id
                onSave(true)
            }
        }
    }

    private func removeItem(at index: Int) {
        guard index >= 0 && index < config.profiles[activeProfileIndex].items.count else { return }
        config.profiles[activeProfileIndex].items.remove(at: index)
        onSave(true)
    }

    private func moveItem(from: Int, to: Int) {
        guard from >= 0 && from < config.profiles[activeProfileIndex].items.count,
              to >= 0 && to < config.profiles[activeProfileIndex].items.count else { return }
        let item = config.profiles[activeProfileIndex].items.remove(at: from)
        config.profiles[activeProfileIndex].items.insert(item, at: to)
        onSave(true)
    }

    private func addApplication() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [UTType.application]
        openPanel.directoryURL = URL(fileURLWithPath: "/Applications")
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.prompt = "Add to Dock"
        if openPanel.runModal() == .OK {
            for url in openPanel.urls {
                let bundle = Bundle(url: url)
                let bundleID = bundle?.bundleIdentifier ?? url.deletingPathExtension().lastPathComponent
                let name = FileManager.default.displayName(atPath: url.path)
                let appItem = AppItem(bundleIdentifier: bundleID, displayName: name, appPath: url.path)
                config.profiles[activeProfileIndex].items.append(.app(appItem))
            }
            onSave(true)
        }
    }
}
