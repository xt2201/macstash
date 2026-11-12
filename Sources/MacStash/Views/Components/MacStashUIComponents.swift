import SwiftUI
import AppKit
import UniformTypeIdentifiers
import MacStashCore
@_exported import MacStashDesignSystem

// MARK: - Interactive Keycap Shortcut Recorder

public struct ShortcutRecorderView: View {
    @Binding public var shortcut: String
    public let defaultValue: String
    public let recordLabel: String
    public let pressKeysLabel: String
    public let clearLabel: String

    @State private var isRecording: Bool = false
    @State private var monitor: Any?

    public init(
        shortcut: Binding<String>,
        defaultValue: String,
        recordLabel: String,
        pressKeysLabel: String,
        clearLabel: String
    ) {
        self._shortcut = shortcut
        self.defaultValue = defaultValue
        self.recordLabel = recordLabel
        self.pressKeysLabel = pressKeysLabel
        self.clearLabel = clearLabel
    }

    private var keycaps: [String] {
        ShortcutValidator.keycapTokens(for: shortcut)
    }

    public var body: some View {
        HStack(spacing: 6) {
            Button(action: {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }) {
                HStack(spacing: 4) {
                    if isRecording {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        Text(pressKeysLabel)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.accentColor)
                    } else if keycaps.isEmpty {
                        Text(recordLabel)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(Array(keycaps.enumerated()), id: \.offset) { _, token in
                            Text(token)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2.5)
                                .background(
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .fill(Color.primary.opacity(0.08))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .strokeBorder(Color.primary.opacity(0.14), lineWidth: 0.7)
                                )
                        }
                    }
                }
                .padding(.horizontal, 8)
                .frame(minWidth: 126, minHeight: 28)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isRecording ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(isRecording ? Color.accentColor : Color.primary.opacity(0.14), lineWidth: isRecording ? 1.4 : 0.8)
                )
            }
            .buttonStyle(.plain)

            if !shortcut.isEmpty {
                Button(action: {
                    stopRecording()
                    shortcut = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help(clearLabel)
            } else {
                Button(action: {
                    stopRecording()
                    shortcut = defaultValue
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .onDisappear {
            stopRecording()
        }
    }

    private func startRecording() {
        stopRecording()
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            if event.keyCode == 53 { // Escape cancels recording
                stopRecording()
                return nil
            }
            if let formatted = Self.formatRecordedEvent(event) {
                shortcut = formatted
                stopRecording()
                return nil
            }
            return nil
        }
    }

    private func stopRecording() {
        if let mon = monitor {
            NSEvent.removeMonitor(mon)
            monitor = nil
        }
        isRecording = false
    }

    private static func formatRecordedEvent(_ event: NSEvent) -> String? {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let allowedMods: NSEvent.ModifierFlags = [.control, .option, .shift, .command]
        let activeMods = flags.intersection(allowedMods)
        // Require at least one modifier key so normal typing isn't stolen
        guard !activeMods.isEmpty else { return nil }

        guard let keyName = keyName(for: event.keyCode) else { return nil }
        var parts: [String] = []
        if activeMods.contains(.control) { parts.append("Control") }
        if activeMods.contains(.option) { parts.append("Option") }
        if activeMods.contains(.shift) { parts.append("Shift") }
        if activeMods.contains(.command) { parts.append("Command") }
        parts.append(keyName)
        return parts.joined(separator: "+")
    }

    private static func keyName(for keyCode: UInt16) -> String? {
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 23: return "5"
        case 22: return "6"
        case 26: return "7"
        case 28: return "8"
        case 25: return "9"
        case 29: return "0"
        case 31: return "O"
        case 32: return "U"
        case 34: return "I"
        case 35: return "P"
        case 37: return "L"
        case 38: return "J"
        case 40: return "K"
        case 45: return "N"
        case 46: return "M"
        case 49: return "Space"
        case 48: return "Tab"
        case 36: return "Return"
        default: return nil
        }
    }
}

// MARK: - App Bundle Picker Helper

public enum AppPickerHelper {
    public struct PickedApp: Identifiable {
        public let id: String
        public let name: String
        public let bundleIdentifier: String
        public let icon: NSImage?
    }

    @MainActor
    public static func runningUserApps() -> [PickedApp] {
        let selfID = Bundle.main.bundleIdentifier
        var seen = Set<String>()
        var results: [PickedApp] = []

        for app in NSWorkspace.shared.runningApplications {
            guard app.activationPolicy == .regular,
                  let bundleID = app.bundleIdentifier,
                  bundleID != selfID,
                  !seen.contains(bundleID) else { continue }
            seen.insert(bundleID)
            let name = app.localizedName ?? bundleID
            let icon = app.icon ?? app.bundleURL.map { NSWorkspace.shared.icon(forFile: $0.path) }
            results.append(PickedApp(id: bundleID, name: name, bundleIdentifier: bundleID, icon: icon))
        }

        return results.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    @MainActor
    public static func browseForApplication(completion: @escaping (PickedApp?) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.begin { response in
            guard response == .OK, let url = panel.url else {
                completion(nil)
                return
            }
            let bundle = Bundle(url: url)
            let bundleID = bundle?.bundleIdentifier ?? url.deletingPathExtension().lastPathComponent
            let name = FileManager.default.displayName(atPath: url.path)
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            completion(PickedApp(id: bundleID, name: name, bundleIdentifier: bundleID, icon: icon))
        }
    }
}
