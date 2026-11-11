import SwiftUI
import AppKit
import UniformTypeIdentifiers
import SideDockCore
import SideDockWidgets
import MacStashCore

public struct DockSettingsTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding public var config: SideDockFileConfig
    public let onSave: (Bool) -> Void
    public let onResetLayout: () -> Void

    @State private var showWidgetGallery: Bool = false
    @State private var editingWidgetItem: WidgetItem? = nil
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
            dockSectionCard(title: localized("dock.configTitle"), systemImage: "dock.rectangle", accent: .teal) {
                Toggle(localized("dock.enableSecondDock"), isOn: $config.isDockVisible)
                    .font(.system(size: 13, weight: .semibold))
                    .onChange(of: config.isDockVisible) { _, _ in onSave(true) }

                Divider()

                HStack {
                    Text(localized("dock.placement"))
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Picker("", selection: bindingForPlacement) {
                        Text(localized("dock.placementFixedBottom")).tag(DockPlacement.fixedBottom)
                        Text(localized("dock.placementFloating")).tag(DockPlacement.floating)
                        Text(localized("dock.placementFixedTop")).tag(DockPlacement.fixedTop)
                        Text(localized("dock.placementFixedLeft")).tag(DockPlacement.fixedLeft)
                        Text(localized("dock.placementFixedRight")).tag(DockPlacement.fixedRight)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 240)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(localized("dock.scale"))
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Text("\(String(format: "%.2f", config.profiles[activeProfileIndex].layoutConfig.scale))x")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: bindingForScale, in: 0.7...1.5, step: 0.05)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(localized("dock.tileSpacing"))
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Text("\(Int(config.profiles[activeProfileIndex].layoutConfig.tileSpacing)) px")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: bindingForSpacing, in: 4.0...24.0, step: 1.0)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(localized("dock.edgeOffset"))
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Text("\(Int(config.profiles[activeProfileIndex].layoutConfig.bottomOffset)) px")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: bindingForBottomOffset, in: 0.0...60.0, step: 2.0)
                }
            }

            // Section 2: Behavior & Triggers
            dockSectionCard(title: localized("dock.behaviorTitle"), systemImage: "bolt.horizontal", accent: .blue) {
                Toggle(localized("dock.autoHide"), isOn: bindingForAutoHide)

                if config.profiles[activeProfileIndex].layoutConfig.autoHide {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(localized("dock.revealDelay"))
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text("\(String(format: "%.1f", config.profiles[activeProfileIndex].layoutConfig.revealDelaySeconds)) s")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: bindingForRevealDelay, in: 0.0...3.0, step: 0.1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(localized("dock.edgeZone"))
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text("\(Int(config.profiles[activeProfileIndex].layoutConfig.edgeTriggerThickness)) px")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
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

            // Section 3: Appearance & Glass Materials
            dockSectionCard(title: localized("dock.appearanceTitle"), systemImage: "sparkles.rectangle.stack", accent: .indigo) {
                HStack {
                    Text(localized("dock.backdropStyle"))
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                }

                Picker("", selection: bindingForBackdrop) {
                    Text(localized("dock.backdropAuto")).tag(DockBackdropStyle.autoSystem)
                    Text(localized("dock.backdropLight")).tag(DockBackdropStyle.lightGlass)
                    Text(localized("dock.backdropDark")).tag(DockBackdropStyle.darkGlass)
                    Text(localized("dock.backdropLiquid")).tag(DockBackdropStyle.liquidGlass)
                    Text(localized("dock.backdropClear")).tag(DockBackdropStyle.clear)
                }
                .pickerStyle(.segmented)

                Toggle(localized("dock.reduceMotion"), isOn: bindingForReduceMotion)
            }

            // Section 4: Profiles & Widget Gallery
            dockSectionCard(title: localized("dock.profilesTitle"), systemImage: "square.stack.3d.up", accent: .purple) {
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
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .help(localized("dock.delete"))
                    }
                }

                if isCreatingProfile {
                    HStack {
                        TextField(localized("dock.profileNamePlaceholder"), text: $newProfileName)
                            .textFieldStyle(.roundedBorder)
                        Button(localized("dock.create")) {
                            createNewProfile()
                        }
                        .buttonStyle(.borderedProminent)
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

            // Section 5: Dock Items & Applications
            dockSectionCard(title: localized("dock.itemsTitle"), systemImage: "app.badge", accent: .cyan) {
                Text(localized("dock.itemsDesc"))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                if config.profiles[activeProfileIndex].items.isEmpty {
                    Text(localized("dock.noItems"))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 5) {
                        ForEach(Array(config.profiles[activeProfileIndex].items.enumerated()), id: \.element.id) { idx, item in
                            HStack(spacing: 8) {
                                Image(systemName: item.systemIconName)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 20)

                                Text(item.displayName)
                                    .font(.system(size: 12, weight: .medium))

                                if case .widget(let w) = item {
                                    Text(w.size.rawValue.uppercased())
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1.5)
                                        .background(Capsule().fill(Color.primary.opacity(0.06)))
                                }

                                Spacer()

                                if case .widget(let w) = item {
                                    Button {
                                        editingWidgetItem = w
                                    } label: {
                                        Image(systemName: "slider.horizontal.3")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.accentColor)
                                    }
                                    .buttonStyle(.plain)
                                    .help(localized("dock.configureWidget"))
                                }

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
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.primary.opacity(0.045)))
                        }
                    }
                }

                Divider()

                HStack(spacing: 10) {
                    Button { addApplication() } label: {
                        Label(localized("dock.addApp"), systemImage: "plus.app")
                    }

                    Button {
                        config.profiles[activeProfileIndex].items.append(.separator(UUID()))
                        onSave(true)
                    } label: {
                        Label(localized("dock.addSeparator"), systemImage: "line.diagonal")
                    }

                    Spacer()

                    Button { showWidgetGallery = true } label: {
                        Label(localized("dock.addWidget"), systemImage: "plus.rectangle.on.rectangle")
                    }
                    .buttonStyle(.borderedProminent)
                }
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
        .sheet(item: $editingWidgetItem) { widgetItem in
            WidgetConfigSheet(widgetItem: widgetItem) { updatedWidget in
                if let itemIdx = config.profiles[activeProfileIndex].items.firstIndex(where: { $0.id == updatedWidget.id }) {
                    config.profiles[activeProfileIndex].items[itemIdx] = .widget(updatedWidget)
                    onSave(true)
                }
            }
        }
    }

    private func dockSectionCard<Content: View>(
        title: String,
        systemImage: String,
        accent: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 22, height: 22)
                    .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(accent.gradient))

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.045) : Color.black.opacity(0.032))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.primary.opacity(colorScheme == .dark ? 0.09 : 0.07), lineWidth: 0.8)
            )
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
