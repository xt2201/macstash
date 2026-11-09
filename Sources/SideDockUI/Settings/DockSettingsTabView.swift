import SwiftUI
import SideDockCore
import SideDockWidgets

public struct DockSettingsTabView: View {
    @Binding public var config: SideDockFileConfig
    public let onSave: (Bool) -> Void
    public let onResetLayout: () -> Void

    @State private var showWidgetGallery: Bool = false
    @State private var newProfileName: String = ""
    @State private var isCreatingProfile: Bool = false

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
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Section 1: Core Toggle & Placement
                GroupBox(label: Text("Second Dock Configuration").font(.headline)) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Enable Second Dock", isOn: $config.isDockVisible)
                            .onChange(of: config.isDockVisible) { _, _ in onSave(true) }

                        Divider()

                        Picker("Placement", selection: bindingForPlacement) {
                            Text("Fixed Bottom (Above macOS Dock)").tag(DockPlacement.fixedBottom)
                            Text("Floating Window").tag(DockPlacement.floating)
                            Text("Fixed Top").tag(DockPlacement.fixedTop)
                            Text("Fixed Left").tag(DockPlacement.fixedLeft)
                            Text("Fixed Right").tag(DockPlacement.fixedRight)
                        }
                        .pickerStyle(.menu)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Scale:")
                                Spacer()
                                Text("\(String(format: "%.1f", config.profiles[activeProfileIndex].layoutConfig.scale))x")
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: bindingForScale, in: 0.7...1.5, step: 0.05)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Tile Spacing:")
                                Spacer()
                                Text("\(Int(config.profiles[activeProfileIndex].layoutConfig.tileSpacing)) px")
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: bindingForSpacing, in: 4.0...24.0, step: 1.0)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Offset from Screen Edge:")
                                Spacer()
                                Text("\(Int(config.profiles[activeProfileIndex].layoutConfig.bottomOffset)) px")
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: bindingForBottomOffset, in: 0.0...60.0, step: 2.0)
                        }
                    }
                    .padding(8)
                }

                // Section 2: Auto-Hide & Edge Triggers
                GroupBox(label: Text("Behavior & Triggers").font(.headline)) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Auto-Hide Dock", isOn: bindingForAutoHide)

                        if config.profiles[activeProfileIndex].layoutConfig.autoHide {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Reveal Delay:")
                                    Spacer()
                                    Text("\(String(format: "%.1f", config.profiles[activeProfileIndex].layoutConfig.revealDelaySeconds)) s")
                                        .foregroundColor(.secondary)
                                }
                                Slider(value: bindingForRevealDelay, in: 0.0...3.0, step: 0.1)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Activation Edge Zone:")
                                    Spacer()
                                    Text("\(Int(config.profiles[activeProfileIndex].layoutConfig.edgeTriggerThickness)) px")
                                        .foregroundColor(.secondary)
                                }
                                Slider(value: bindingForTriggerThickness, in: 2.0...20.0, step: 1.0)
                            }
                        }

                        Toggle("Hide when application is in Fullscreen", isOn: bindingForFullscreen)
                        Toggle("Hide on Window Hover (fade out when window covers dock)", isOn: bindingForHover)
                        Toggle("Reserve Dock Space (push active windows away from dock)", isOn: bindingForReserve)
                        Toggle("Show Running Applications Bar", isOn: bindingForRunningApps)
                    }
                    .padding(8)
                }

                // Section 3: Appearance & Glass Style
                GroupBox(label: Text("Appearance & Glass Materials").font(.headline)) {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Backdrop Style", selection: bindingForBackdrop) {
                            Text("Auto System").tag(DockBackdropStyle.autoSystem)
                            Text("Light Glass").tag(DockBackdropStyle.lightGlass)
                            Text("Dark Glass").tag(DockBackdropStyle.darkGlass)
                            Text("Liquid Glass").tag(DockBackdropStyle.liquidGlass)
                            Text("Clear (Frameless)").tag(DockBackdropStyle.clear)
                        }
                        .pickerStyle(.segmented)

                        Toggle("Reduce Motion (Disable hover bounce & animations)", isOn: bindingForReduceMotion)
                    }
                    .padding(8)
                }

                // Section 4: Profiles & Widgets
                GroupBox(label: Text("Profiles & Widget Gallery").font(.headline)) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Picker("Active Profile:", selection: $config.activeProfileId) {
                                ForEach(config.profiles) { prof in
                                    Text(prof.name).tag(prof.id)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: 240)

                            Spacer()

                            Button {
                                isCreatingProfile = true
                            } label: {
                                Label("New Profile", systemImage: "plus")
                            }

                            if config.profiles.count > 1 {
                                Button(role: .destructive) {
                                    deleteCurrentProfile()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }

                        if isCreatingProfile {
                            HStack {
                                TextField("Profile Name...", text: $newProfileName)
                                    .textFieldStyle(.roundedBorder)
                                Button("Create") {
                                    createNewProfile()
                                }
                                .disabled(newProfileName.trimmingCharacters(in: .whitespaces).isEmpty)
                                Button("Cancel") {
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
                                Label("Browse Widget Gallery...", systemImage: "plus.rectangle.on.rectangle")
                            }
                            .buttonStyle(.borderedProminent)

                            Spacer()

                            Button(role: .destructive) {
                                onResetLayout()
                            } label: {
                                Label("Reset Layout", systemImage: "arrow.counterclockwise")
                            }
                            .help("Restores dock position and dimensions without losing widgets")
                        }
                    }
                    .padding(8)
                }
            }
            .padding(16)
        }
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
}
