import SwiftUI
import AppKit

public struct SettingsView: View {
    @ObservedObject var appState: AppState
    @State private var selectedTab: SettingsTab = .general

    public enum SettingsTab: String, CaseIterable, Identifiable {
        case general = "General"
        case corners = "Corners"
        case dock = "Hidden Dock"
        case feedback = "Feedback"
        case profiles = "App Profiles"
        case updates = "Updates"

        public var id: String { rawValue }

        public var systemImage: String {
            switch self {
            case .general: return "gearshape.fill"
            case .corners: return "hand.tap.fill"
            case .dock: return "dock.rectangle"
            case .feedback: return "waveform"
            case .profiles: return "person.crop.circle.badge.checkmark"
            case .updates: return "arrow.triangle.2.circlepath.circle.fill"
            }
        }
    }

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Tab Selector Bar
            HStack(spacing: 14) {
                ForEach(SettingsTab.allCases) { tab in
                    Button(action: { selectedTab = tab }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: 15))
                            Text(tab.rawValue)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTab == tab ? Color.accentColor.opacity(0.12) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 14)
            .padding(.bottom, 6)

            Divider()

            // Tab Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case .general:
                        GeneralTab(appState: appState)
                    case .corners:
                        CornersTab(appState: appState)
                    case .dock:
                        DockTab(appState: appState)
                    case .feedback:
                        FeedbackTab(appState: appState)
                    case .profiles:
                        ProfilesTab(appState: appState)
                    case .updates:
                        UpdatesTab(appState: appState)
                    }
                }
                .padding(22)
            }
        }
        .frame(width: 620, height: 500)
    }
}

// MARK: - General Tab

private struct GeneralTab: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            GroupBox("Master Controls") {
                VStack(spacing: 12) {
                    Toggle("Enable MacStash Controls", isOn: $appState.isEnabled)
                        .font(.system(size: 13, weight: .semibold))

                    Divider()

                    Toggle("Enable Corner Radial Dials", isOn: $appState.isCornerDialsEnabled)
                    Toggle("Enable Edge Sliders", isOn: $appState.isEdgeSlidersEnabled)
                    Toggle("Enable Hidden Dock Shelf", isOn: $appState.isHiddenDockEnabled)
                }
                .padding(8)
            }

            GroupBox("Active App Context") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Frontmost Application:")
                            .font(.system(size: 12, weight: .medium))
                        Text(appState.profiles.currentAppName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.accentColor)
                    }
                    Spacer()
                    Text("Profile: \(appState.activeProfile.name)")
                        .font(.system(size: 12))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.secondary.opacity(0.15)))
                }
                .padding(8)
            }
        }
    }
}

// MARK: - Corners Tab

private struct CornersTab: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Corner Dials & Hotzone Sensitivity")
                .font(.system(size: 14, weight: .bold))

            // Trigger Zone Sensitivity
            GroupBox("Trigger Precision (Tránh chạm nhầm)") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Corner Trigger Radius:")
                            .font(.system(size: 12, weight: .medium))
                        Slider(value: $appState.cornerSensitivityRadius, in: 4...16, step: 2)
                        Text("\(Int(appState.cornerSensitivityRadius)) px")
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 45)
                    }

                    Text("Lower values (e.g. 6-8px) require moving cursor directly into the extreme corner vertex, allowing 100% click pass-through to underlying app buttons and tabs.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Divider()

                    HStack {
                        Text("Activation Dwell Delay:")
                            .font(.system(size: 12, weight: .medium))
                        Picker("", selection: $appState.cornerDwellDelay) {
                            Text("Instant (0s)").tag(TimeInterval(0.0))
                            Text("Fast (0.08s)").tag(TimeInterval(0.08))
                            Text("Gentle (0.15s)").tag(TimeInterval(0.15))
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(8)
            }

            // Visual Screen Preview
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .frame(height: 220)

                VStack {
                    HStack {
                        cornerPicker(for: .topLeft)
                        Spacer()
                        cornerPicker(for: .topRight)
                    }
                    Spacer()
                    HStack {
                        cornerPicker(for: .bottomLeft)
                        Spacer()
                        cornerPicker(for: .bottomRight)
                    }
                }
                .padding(14)
            }
        }
    }

    private func cornerPicker(for corner: CornerPosition) -> some View {
        VStack(alignment: corner == .topLeft || corner == .bottomLeft ? .leading : .trailing, spacing: 4) {
            Text(corner.displayName)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)

            Picker("", selection: Binding(
                get: { appState.action(for: corner) },
                set: { newAction in
                    appState.activeProfile.cornerActions[corner] = newAction
                    appState.saveSettings()
                }
            )) {
                ForEach(ControlAction.allCases) { action in
                    Label(action.displayName, systemImage: action.systemImage)
                        .tag(action)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 185)
        }
    }
}

// MARK: - Hidden Dock Tab

private struct DockTab: View {
    @ObservedObject var appState: AppState
    @State private var isPickerPresented: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hidden Dock Shelf")
                        .font(.system(size: 14, weight: .bold))
                    Text("Frequently used applications tucked into the screen edge.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { isPickerPresented = true }) {
                    Label("Add Application", systemImage: "plus")
                }
            }

            List {
                ForEach(appState.dockItems) { item in
                    HStack(spacing: 12) {
                        Image(nsImage: item.icon)
                            .resizable()
                            .frame(width: 28, height: 28)

                        Text(item.name)
                            .font(.system(size: 13, weight: .medium))

                        Spacer()

                        Button(action: {
                            if let idx = appState.dockItems.firstIndex(of: item) {
                                appState.dockItems.remove(at: idx)
                            }
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
                .onMove { indices, newOffset in
                    appState.dockItems.move(fromOffsets: indices, toOffset: newOffset)
                }
            }
            .frame(height: 220)
            .sheet(isPresented: $isPickerPresented) {
                AppPickerSheet(appState: appState, isPresented: $isPickerPresented)
            }
        }
    }
}

// MARK: - Feedback Tab

private struct FeedbackTab: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            GroupBox("Trackpad Haptic Feedback") {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Haptic Intensity", selection: $appState.hapticIntensity) {
                        ForEach(HapticIntensity.allCases) { intensity in
                            Text(intensity.rawValue).tag(intensity)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("Tactile resistance notches emitted by the Force Touch trackpad as dials turn.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(8)
            }

            GroupBox("Mechanical Audio Clicks") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable Sound Effects", isOn: $appState.isSoundEnabled)

                    if appState.isSoundEnabled {
                        HStack {
                            Text("Volume")
                                .font(.system(size: 12))
                            Slider(value: $appState.soundVolume, in: 0.1...1.0)
                            Text("\(Int(appState.soundVolume * 100))%")
                                .font(.system(size: 11, weight: .bold))
                                .frame(width: 40)
                        }

                        Button("Test Click Sound") {
                            appState.sound.playTick(enabled: true, volume: appState.soundVolume)
                            appState.haptics.performDetentTick(intensity: appState.hapticIntensity)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(8)
            }
        }
    }
}

// MARK: - Profiles Tab

private struct ProfilesTab: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Context-Aware Profiles")
                .font(.system(size: 14, weight: .bold))
            Text("Customize dial assignments automatically based on the active application.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            List(appState.appProfiles) { profile in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.name)
                            .font(.system(size: 13, weight: .medium))
                        Text(profile.bundleIdentifier ?? "Global Default")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if profile.id == appState.activeProfile.id {
                        Text("Active Now")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(height: 200)
        }
    }
}

// MARK: - Updates Tab

private struct UpdatesTab: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            GroupBox("Application Version") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.accentColor)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("MacStash for macOS")
                                .font(.system(size: 14, weight: .bold))
                            Text("Version \(appState.updater.currentVersion) (Production Build)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: {
                            appState.updater.checkForUpdates(silent: false)
                        }) {
                            if appState.updater.isChecking {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Text("Check for Updates")
                            }
                        }
                        .disabled(appState.updater.isChecking)
                    }
                }
                .padding(10)
            }

            GroupBox("Release Channel & Changelog") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Latest Milestone: v2.0.0")
                        .font(.system(size: 12, weight: .semibold))

                    Text("• Multi-display support across built-in Retina & all external monitors.\n• Pass-through hit-testing: tight 6-8px corner triggers prevent accidental clicks on apps.\n• Focus Timer dial (0-60m) with live radial countdown & audio alarm.\n• Keyboard backlight brightness dial via CoreBrightness.\n• Master volume with instant Audio Output Device switching.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineSpacing(3)
                }
                .padding(10)
            }
        }
    }
}

// MARK: - App Picker Sheet

private struct AppPickerSheet: View {
    @ObservedObject var appState: AppState
    @Binding var isPresented: Bool
    @State private var query: String = ""

    private var filtered: [DockItem] {
        if query.isEmpty { return appState.appManager.installedApps }
        return appState.appManager.installedApps.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Select an Application")
                    .font(.headline)
                Spacer()
                Button("Done") { isPresented = false }
            }

            TextField("Search installed apps...", text: $query)
                .textFieldStyle(.roundedBorder)

            List(filtered) { item in
                HStack(spacing: 12) {
                    Image(nsImage: item.icon)
                        .resizable()
                        .frame(width: 24, height: 24)
                    Text(item.name)
                    Spacer()
                    Button("Add") {
                        if !appState.dockItems.contains(where: { $0.bundleIdentifier == item.bundleIdentifier }) {
                            appState.dockItems.append(item)
                        }
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .frame(height: 300)
        }
        .padding(20)
        .frame(width: 440)
    }
}
