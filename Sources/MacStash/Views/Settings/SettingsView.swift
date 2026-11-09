import SwiftUI
import AppKit
import MacStashCore
import SideDockCore
import SideDockWidgets
import SideDockUI
import SideDockSystem

public struct SettingsView: View {
    @ObservedObject var appState: AppState
    @State private var selectedTab: SettingsTab = .general

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

        @MainActor
        public func localizedTitle(using appState: AppState) -> String {
            switch self {
            case .general: return appState.localized("tab.general")
            case .hotCorners: return appState.localized("tab.hotCorners")
            case .sideDock: return appState.effectiveLanguage == "vi" ? "Thanh Dock" : "Second Dock"
            case .appearance: return appState.localized("tab.appearance")
            case .displays: return appState.localized("tab.displays")
            case .pomodoro: return appState.localized("tab.pomodoro")
            case .shortcuts: return appState.localized("tab.shortcuts")
            case .about: return appState.localized("tab.about")
            }
        }

        public var systemImage: String {
            switch self {
            case .general: return "gearshape"
            case .hotCorners: return "hand.tap"
            case .sideDock: return "dock.rectangle"
            case .appearance: return "paintpalette"
            case .displays: return "display.2"
            case .pomodoro: return "timer"
            case .shortcuts: return "keyboard"
            case .about: return "info.circle"
            }
        }
    }

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 0) {
            // macOS HIG Toolbar Tabs Bar
            HStack(spacing: 6) {
                ForEach(SettingsTab.allCases) { tab in
                    Button(action: { selectedTab = tab }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: 15))
                            Text(tab.localizedTitle(using: appState))
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(selectedTab == tab ? .accentColor : .primary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(selectedTab == tab ? Color.accentColor.opacity(0.14) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(selectedTab == tab ? Color.accentColor.opacity(0.35) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // Tab Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case .general:
                        GeneralTab(appState: appState)
                    case .hotCorners:
                        HotCornersTab(appState: appState)
                    case .sideDock:
                        DockSettingsTabView(
                            config: Binding(
                                get: { appState.sideDock.config },
                                set: { appState.sideDock.config = $0 }
                            ),
                            onSave: { immediate in
                                appState.sideDock.configStore.updateConfig(immediate: immediate) { cfg in
                                    cfg = appState.sideDock.config
                                }
                                appState.sideDock.updateDockLayout()
                            },
                            onResetLayout: {
                                appState.sideDock.resetLayout()
                            }
                        )
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
                .padding(20)
            }
        }
        .frame(width: 660, height: 560)
    }
}
