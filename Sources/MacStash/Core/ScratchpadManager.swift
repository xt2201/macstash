import Foundation
import AppKit
import Combine
import MacStashCore

/// Quick scratchpad text, counters and local persistence.
@MainActor
public final class ScratchpadManager: ObservableObject {
    public static let shared = ScratchpadManager()

    private let storage = ScratchpadStorage()

    @Published public var text: String = "" {
        didSet {
            updateCounts()
            storage.save(ScratchpadData(text: text, lastModified: Date()))
        }
    }

    @Published public var isScratchpadOpen: Bool = false
    @Published public private(set) var characterCount: Int = 0
    @Published public private(set) var wordCount: Int = 0

    private init() {
        text = storage.load().text
        updateCounts()
    }

    public func clear() {
        text = ""
        storage.clear()
        HapticManager.shared.performBoundaryClick()
    }

    public func copyAll() {
        guard !text.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        HapticManager.shared.performDetentTick()
    }

    private func updateCounts() {
        characterCount = text.count
        wordCount = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
}
