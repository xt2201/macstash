import SwiftUI
import AppKit
import SideDockUI
import SideDockSystem
import SideDockEngine
import MacStashCore
import MacStashDesignSystem

public struct SettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var permissions = SystemPermissionService.shared
    @ObservedObject private var sideDock = SideDockManager.shared
    @State private var selectedTab: SettingsTab
    @State private var searchQuery: String = ""

    public enum SettingsTab: String, CaseIterable, Identifiable {
        case general = "General"
        case hotCorners = "Hot Corners"
        case sideDock = "Second Dock"
        case appearance = "Appearance"
        case displays = "Displays"
        case pomodoro = "Pomodoro"
        case shortcuts = "Shortcuts"
        case about = "About / Advanced"

        public var id: String { rawValue }

        var localizationKey: String {
            switch self {
            case .general: return "tab.general"
            case .hotCorners: return "tab.hotCorners"
            case .sideDock: return "tab.sideDock"
            case .appearance: return "tab.appearance"
            case .displays: return "tab.displays"
            case .pomodoro: return "tab.pomodoro"
            case .shortcuts: return "tab.shortcuts"
            case .about: return "tab.about"
            }
        }

        var iconName: String {
            switch self {
            case .general: return "gearshape.fill"
            case .hotCorners: return "inset.filled.topleft.topright.bottomleft.bottomright.rectangle"
            case .sideDock: return "dock.rectangle"
            case .appearance: return "sparkles"
            case .displays: return "display.2"
            case .pomodoro: return "timer"
            case .shortcuts: return "keyboard.fill"
            case .about: return "info.circle.fill"
            }
        }

        var tintColor: Color {
            switch self {
            case .general: return .blue
            case .hotCorners: return .cyan
            case .sideDock: return .teal
            case .appearance: return .purple
            case .displays: return .orange
            case .pomodoro: return .red
            case .shortcuts: return .indigo
            case .about: return .gray
            }
        }

        var section: SidebarSection {
            switch self {
            case .general, .hotCorners, .sideDock: return .core
            case .appearance, .displays, .pomodoro: return .customize
            case .shortcuts, .about: return .system
            }
        }
    }

    enum SidebarSection: CaseIterable {
        case core, customize, system

        var titleKey: String {
            switch self {
            case .core: return "settings.sectionCore"
            case .customize: return "settings.sectionCustomize"
            case .system: return "settings.sectionSystem"
            }
        }

        var tabs: [SettingsTab] {
            SettingsTab.allCases.filter { $0.section == self }
        }
    }

    public init(appState: AppState, initialTab: SettingsTab = .general) {
        self.appState = appState
        self._selectedTab = State(initialValue: initialTab)
    }

    public var body: some View {
        HStack(spacing: 0) {
            sidebarView
                .frame(width: 222)
                .background(SidebarVisualEffectBackground())

            Divider()

            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 820, minHeight: 600)
        .macStashTheme(appState.resolvedColorScheme)
        .onAppear {
            permissions.checkAllPermissions()
            if let requested = appState.requestedSettingsTab, let tab = SettingsTab(rawValue: requested) {
                selectedTab = tab
                appState.requestedSettingsTab = nil
            }
        }
        .onReceive(appState.$requestedSettingsTab) { tabID in
            if let tabID, let matched = SettingsTab(rawValue: tabID) {
                withAnimation(.easeInOut(duration: 0.16)) {
                    selectedTab = matched
                }
                appState.requestedSettingsTab = nil
            }
        }
    }

    // MARK: - Sidebar

    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App Identity + Master Switch Header
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    StashBrandLogoView(size: 34, showWordmark: false)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("MacStash")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)

                        StatusBadgePill(
                            text: appState.localized(appState.isEnabled ? "settings.statusActive" : "settings.statusPaused"),
                            color: appState.isEnabled ? .green : .orange
                        )
                    }

                    Spacer()

                    Toggle("", isOn: $appState.isEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .controlSize(.small)
                        .help(appState.localized("general.enableMacStash"))
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 16)
            .padding(.bottom, 14)

            Divider()
                .padding(.horizontal, 12)

            // Search Bar
            SearchInputField(
                placeholder: appState.localized("settings.searchPlaceholder"),
                text: $searchQuery
            )
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 4)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        ForEach(SidebarSection.allCases, id: \.titleKey) { section in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(appState.localized(section.titleKey).uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary.opacity(0.85))
                                    .tracking(0.6)
                                    .padding(.horizontal, 10)
                                    .padding(.bottom, 2)

                                ForEach(section.tabs) { tab in
                                    sidebarRow(for: tab)
                                }
                            }
                        }
                    } else {
                        let filtered = matchingTabs
                        if filtered.isEmpty {
                            Text(appState.localized("folder.empty"))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.top, 8)
                        } else {
                            ForEach(filtered) { tab in
                                sidebarRow(for: tab)
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
        }
    }

    private var matchingTabs: [SettingsTab] {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return SettingsTab.allCases }
        return SettingsTab.allCases.filter { tab in
            let title = appState.localized(tab.localizationKey).lowercased()
            let raw = tab.rawValue.lowercased()
            return title.contains(q) || raw.contains(q)
        }
    }

    private func sidebarRow(for tab: SettingsTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            withAnimation(.easeInOut(duration: 0.14)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 9) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 22, height: 22)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(tab.tintColor.gradient)
                    )

                Text(appState.localized(tab.localizationKey))
                    .font(.system(size: 12.5, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .primary : .primary.opacity(0.85))
                    .lineLimit(1)

                Spacer()

                sidebarBadge(for: tab)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.16) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor.opacity(0.28) : Color.clear, lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func sidebarBadge(for tab: SettingsTab) -> some View {
        switch tab {
        case .general:
            if !permissions.isAccessibilityGranted {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 7, height: 7)
            }
        case .sideDock:
            if sideDock.config.isDockVisible {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
            }
        case .pomodoro:
            if appState.isPomodoroRunning {
                Text(appState.formattedTimerTime)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundColor(.red)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Capsule().fill(Color.red.opacity(0.14)))
            }
        case .about:
            if appState.updater.updateAvailable {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 7, height: 7)
            }
        default:
            EmptyView()
        }
    }

    // MARK: - Detail Content

    private var detailView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Subtle sticky section header
            HStack(spacing: 10) {
                Image(systemName: selectedTab.iconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 26, height: 26)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(selectedTab.tintColor.gradient)
                    )

                Text(appState.localized(selectedTab.localizationKey))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                if selectedTab == .hotCorners {
                    StatusBadgePill(
                        text: appState.activeProfile.name,
                        color: .cyan
                    )
                } else if selectedTab == .pomodoro && appState.isPomodoroRunning {
                    StatusBadgePill(
                        text: appState.formattedTimerTime,
                        color: appState.pomodoroMode == .focus ? .red : .green
                    )
                } else if selectedTab == .sideDock {
                    StatusBadgePill(
                        text: sideDock.config.isDockVisible ? appState.localized("settings.statusActive") : appState.localized("settings.statusHidden"),
                        color: sideDock.config.isDockVisible ? .teal : .secondary
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)

            Divider()

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 18) {
                    activeTabContent
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .frame(maxWidth: 680, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }



    @ViewBuilder
    private var activeTabContent: some View {
        switch selectedTab {
        case .general:
            GeneralTab(appState: appState)
        case .hotCorners:
            HotCornersTab(appState: appState)
        case .sideDock:
            VStack(alignment: .leading, spacing: 18) {
                SideDockSuperchargerCard(sideDock: sideDock, appState: appState)

                DockSettingsTabView(
                    config: Binding(
                        get: { sideDock.config },
                        set: { newConfig in
                            sideDock.config = newConfig
                            sideDock.configStore.saveConfig(newConfig)
                        }
                    ),
                    onSave: { _ in
                        sideDock.configStore.saveConfig(sideDock.config)
                    },
                    onResetLayout: {
                        sideDock.resetLayoutToDefaults()
                    }
                )
            }
        case .appearance:
            AppearanceTab(appState: appState)
        case .displays:
            DisplaysTab(appState: appState)
        case .pomodoro:
            PomodoroTab(appState: appState)
        case .shortcuts:
            ShortcutsTab(appState: appState)
        case .about:
            AboutTab(appState: appState)
        }
    }
}

private struct SidebarVisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

private struct SideDockSuperchargerCard: View {
    @ObservedObject var sideDock: SideDockManager
    let appState: AppState

    var body: some View {
        SettingsCard(
            title: appState.localized("dock.supercharger.title"),
            systemImage: "dock.rectangle",
            accentColor: .teal
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(appState.localized("dock.supercharger.subtitle"))
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    Button(action: {
                        sideDock.toggleDock()
                    }) {
                        Label(
                            appState.localized("dock.supercharger.toggle"),
                            systemImage: sideDock.config.isDockVisible ? "eye.slash.fill" : "eye.fill"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(sideDock.config.isDockVisible ? .gray : .teal)

                    Button(action: {
                        sideDock.toggleEditMode()
                    }) {
                        Label(
                            appState.localized("dock.supercharger.editMode"),
                            systemImage: "slider.horizontal.2.square"
                        )
                    }
                    .buttonStyle(.bordered)

                    Button(action: {
                        sideDock.toggleLaunchpad()
                    }) {
                        Label(
                            appState.localized("dock.supercharger.launchpad"),
                            systemImage: "square.grid.3x3.fill"
                        )
                    }
                    .buttonStyle(.bordered)

                    Button(action: {
                        sideDock.toggleWindowSwitcher()
                    }) {
                        Label(
                            appState.localized("dock.supercharger.windowSwitcher"),
                            systemImage: "macwindow.on.rectangle"
                        )
                    }
                    .buttonStyle(.bordered)
                }
                .controlSize(.regular)
            }
        }
    }
}
