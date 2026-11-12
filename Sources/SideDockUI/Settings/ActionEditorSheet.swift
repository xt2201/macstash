import SwiftUI
import SideDockCore
import MacStashCore

public struct ActionEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let onCreate: (DockActionItem) -> Void

    @State private var displayName: String = "Mission Control"
    @State private var kind: DockActionKind = .systemCommand
    @State private var systemCommand: BuiltInSystemCommand = .missionControl
    @State private var payload: String = ""
    @State private var targetBundleID: String = ""
    @State private var symbolName: String = "bolt.fill"

    public init(onCreate: @escaping (DockActionItem) -> Void) {
        self.onCreate = onCreate
    }

    private func localized(_ key: String) -> String {
        LocalizationService.shared.localized(key)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(localized("dock.addActionTitle"))
                .font(.system(size: 15, weight: .bold))

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text(localized("dock.actionKind"))
                    .font(.system(size: 12, weight: .medium))
                Picker("", selection: $kind) {
                    Text("System").tag(DockActionKind.systemCommand)
                    Text("AppleScript").tag(DockActionKind.appleScript)
                    Text("Shell").tag(DockActionKind.shellScript)
                    Text("Menu Click").tag(DockActionKind.menuClick)
                    Text("URL").tag(DockActionKind.url)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            TextField(localized("dock.actionNamePlaceholder"), text: $displayName)
                .textFieldStyle(.roundedBorder)

            if kind == .systemCommand {
                Picker("Command", selection: $systemCommand) {
                    Text("Lock Screen").tag(BuiltInSystemCommand.lockScreen)
                    Text("Sleep Display").tag(BuiltInSystemCommand.sleepDisplay)
                    Text("Mission Control").tag(BuiltInSystemCommand.missionControl)
                    Text("App Expose").tag(BuiltInSystemCommand.appExpose)
                    Text("Show Desktop").tag(BuiltInSystemCommand.showDesktop)
                    Text("Screenshot Area").tag(BuiltInSystemCommand.screenshotArea)
                    Text("Empty Trash").tag(BuiltInSystemCommand.emptyTrash)
                    Text("Toggle Dark Mode").tag(BuiltInSystemCommand.toggleDarkMode)
                    Text("Open Launchpad").tag(BuiltInSystemCommand.openLaunchpad)
                    Text("Window Switcher").tag(BuiltInSystemCommand.openWindowSwitcher)
                }
                .pickerStyle(.menu)
                .onChange(of: systemCommand) { _, newCmd in
                    displayName = defaultTitle(for: newCmd)
                    symbolName = defaultSymbol(for: newCmd)
                }
            } else {
                if kind == .menuClick {
                    TextField("Target Bundle ID (e.g. com.apple.Safari)", text: $targetBundleID)
                        .textFieldStyle(.roundedBorder)
                    TextField("Menu Path (e.g. File > New Private Window)", text: $payload)
                        .textFieldStyle(.roundedBorder)
                } else {
                    TextEditor(text: $payload)
                        .font(.system(size: 11.5, design: .monospaced))
                        .frame(height: 110)
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.primary.opacity(0.15)))
                }
            }

            HStack {
                Text("SF Symbol:")
                    .font(.system(size: 12))
                TextField("bolt.fill", text: $symbolName)
                    .textFieldStyle(.roundedBorder)
                Image(systemName: symbolName.isEmpty ? "bolt.fill" : symbolName)
                    .frame(width: 24, height: 24)
            }

            Divider()

            HStack {
                Spacer()
                Button(localized("dock.cancel")) { dismiss() }
                    .buttonStyle(.bordered)
                Button(localized("dock.create")) {
                    let finalPayload = kind == .systemCommand ? systemCommand.rawValue : payload
                    let item = DockActionItem(
                        displayName: displayName.isEmpty ? "Action" : displayName,
                        kind: kind,
                        payload: finalPayload,
                        targetBundleIdentifier: targetBundleID.isEmpty ? nil : targetBundleID,
                        systemIconName: symbolName.isEmpty ? "bolt.fill" : symbolName
                    )
                    onCreate(item)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(18)
        .frame(width: 420)
    }

    private func defaultTitle(for cmd: BuiltInSystemCommand) -> String {
        switch cmd {
        case .lockScreen: return "Lock Screen"
        case .sleepDisplay: return "Sleep Display"
        case .missionControl: return "Mission Control"
        case .appExpose: return "App Expose"
        case .showDesktop: return "Show Desktop"
        case .screenshotArea: return "Screenshot"
        case .emptyTrash: return "Empty Trash"
        case .toggleDarkMode: return "Dark Mode"
        case .openLaunchpad: return "Launchpad"
        case .openWindowSwitcher: return "Window Switcher"
        case .toggleNativeDockAutoHide: return "Toggle System Dock"
        }
    }

    private func defaultSymbol(for cmd: BuiltInSystemCommand) -> String {
        switch cmd {
        case .lockScreen: return "lock.fill"
        case .sleepDisplay: return "moon.zzz.fill"
        case .missionControl: return "rectangle.3.group"
        case .appExpose: return "macwindow.on.rectangle"
        case .showDesktop: return "menubar.dock.rectangle"
        case .screenshotArea: return "camera.viewfinder"
        case .emptyTrash: return "trash.slash.fill"
        case .toggleDarkMode: return "circle.lefthalf.filled"
        case .openLaunchpad: return "square.grid.3x3.fill"
        case .openWindowSwitcher: return "square.on.square"
        case .toggleNativeDockAutoHide: return "dock.arrow.down.rectangle"
        }
    }
}
