import Foundation
import AppKit
import Combine
import MacStashCore

/// Quick scratchpad text, counters and debounced local persistence.
@MainActor
public final class ScratchpadManager: ObservableObject {
    public static let shared = ScratchpadManager()

    private let storage: ScratchpadStorage
    private var saveWorkItem: DispatchWorkItem?
    private var undoText: String? = nil

    @Published public var text: String = "" {
        didSet {
            updateCounts()
            scheduleDebouncedSave()
        }
    }

    @Published public var isScratchpadOpen: Bool = false
    @Published public var isPinned: Bool = false
    @Published public private(set) var characterCount: Int = 0
    @Published public private(set) var wordCount: Int = 0

    public init(storage: ScratchpadStorage = ScratchpadStorage()) {
        self.storage = storage
        self.text = storage.load().text
        updateCounts()
    }

    public func togglePin() {
        isPinned.toggle()
        HapticManager.shared.performDetentTick()
    }

    public func clear() {
        guard !text.isEmpty else { return }
        undoText = text
        text = ""
        saveWorkItem?.cancel()
        storage.clear()
        HapticManager.shared.performBoundaryClick()
    }

    public var canUndoClear: Bool {
        undoText != nil && !(undoText?.isEmpty ?? true)
    }

    public func undoClear() {
        guard let restored = undoText, !restored.isEmpty else { return }
        text = restored
        undoText = nil
        saveWorkItem?.cancel()
        storage.save(ScratchpadData(text: text, lastModified: Date()))
        HapticManager.shared.performBoundaryClick()
    }

    public func copyAll() {
        guard !text.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        HapticManager.shared.performDetentTick()
    }

    public func flush() {
        saveWorkItem?.cancel()
        storage.save(ScratchpadData(text: text, lastModified: Date()))
    }

    private func scheduleDebouncedSave() {
        saveWorkItem?.cancel()
        let currentText = text
        let item = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.storage.save(ScratchpadData(text: currentText, lastModified: Date()))
            }
        }
        saveWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: item)
    }

    private func updateCounts() {
        characterCount = text.count
        var count = 0
        var inWord = false
        for scalar in text.unicodeScalars {
            if CharacterSet.whitespacesAndNewlines.contains(scalar) {
                inWord = false
            } else if !inWord {
                inWord = true
                count += 1
            }
        }
        wordCount = count
    }
}
