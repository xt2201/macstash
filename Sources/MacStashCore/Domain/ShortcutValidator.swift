import Foundation

public struct ShortcutConflict: Equatable, Sendable, Identifiable {
    public let id: String
    public let actionKey: String
    public let shortcut: String
    public let reason: String

    public init(actionKey: String, shortcut: String, reason: String) {
        self.id = "\(actionKey)::\(shortcut)"
        self.actionKey = actionKey
        self.shortcut = shortcut
        self.reason = reason
    }
}

public enum ShortcutValidator {
    /// Normalizes user-entered or recorded shortcut strings into a canonical sorted form such as "control+option+s".
    public static func canonicalize(_ raw: String) -> String {
        let parts = raw
            .replacingOccurrences(of: "-", with: "+")
            .split(separator: "+")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }

        var mods: [String] = []
        var key: String?

        for part in parts {
            switch part {
            case "control", "ctrl", "⌃":
                if !mods.contains("control") { mods.append("control") }
            case "option", "opt", "alt", "⌥":
                if !mods.contains("option") { mods.append("option") }
            case "shift", "⇧":
                if !mods.contains("shift") { mods.append("shift") }
            case "command", "cmd", "⌘":
                if !mods.contains("command") { mods.append("command") }
            default:
                key = part
            }
        }

        let order = ["control", "option", "shift", "command"]
        let sortedMods = order.filter { mods.contains($0) }
        guard let k = key else { return sortedMods.joined(separator: "+") }
        return (sortedMods + [k]).joined(separator: "+")
    }

    /// Formats a shortcut string into macOS modifier symbols and capitalized key tokens (e.g. ["⌥", "Space"]).
    public static func keycapTokens(for raw: String) -> [String] {
        let canonical = canonicalize(raw)
        guard !canonical.isEmpty else { return [] }
        let parts = canonical.split(separator: "+").map(String.init)
        return parts.map { token in
            switch token {
            case "control": return "⌃"
            case "option": return "⌥"
            case "shift": return "⇧"
            case "command": return "⌘"
            case "space": return "Space"
            case "return", "enter": return "↩"
            case "escape", "esc": return "⎋"
            case "tab": return "⇥"
            default: return token.uppercased()
            }
        }
    }

    /// Checks a set of named shortcuts against macOS reserved shortcuts and internal duplicate assignments.
    public static func auditConflicts(
        shortcuts: [(actionKey: String, value: String)],
        language: String = "en"
    ) -> [ShortcutConflict] {
        let isVi = language == "vi"
        var conflicts: [ShortcutConflict] = []
        var seenCanonical: [String: String] = [:]

        let reservedMap: [String: (en: String, vi: String)] = [
            "command+space": ("Spotlight Search (⌘Space)", "Tìm kiếm Spotlight (⌘Space)"),
            "command+tab": ("Application Switcher (⌘Tab)", "Chuyển đổi ứng dụng (⌘Tab)"),
            "option+command+escape": ("Force Quit Applications (⌘⌥Esc)", "Buộc thoát ứng dụng (⌘⌥Esc)"),
            "command+q": ("Quit Application (⌘Q)", "Thoát ứng dụng (⌘Q)"),
            "command+w": ("Close Window (⌘W)", "Đóng cửa sổ (⌘W)"),
            "command+h": ("Hide Application (⌘H)", "Ẩn ứng dụng (⌘H)"),
            "command+,": ("Preferences (⌘,)", "Mở Cài đặt (⌘,)"),
            "control+option+d": ("Toggle Second Dock (⌃⌥D)", "Bật/tắt thanh Dock thứ hai (⌃⌥D)")
        ]

        for entry in shortcuts {
            let trimmed = entry.value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let canon = canonicalize(trimmed)

            if let reserved = reservedMap[canon] {
                conflicts.append(
                    ShortcutConflict(
                        actionKey: entry.actionKey,
                        shortcut: entry.value,
                        reason: isVi ? reserved.vi : reserved.en
                    )
                )
            }

            if let existingAction = seenCanonical[canon] {
                let reason = isVi
                    ? "Trùng lặp phím tắt với \(existingAction)"
                    : "Duplicate shortcut already assigned to \(existingAction)"
                conflicts.append(
                    ShortcutConflict(
                        actionKey: entry.actionKey,
                        shortcut: entry.value,
                        reason: reason
                    )
                )
            } else {
                seenCanonical[canon] = entry.actionKey
            }
        }

        return conflicts
    }
}
