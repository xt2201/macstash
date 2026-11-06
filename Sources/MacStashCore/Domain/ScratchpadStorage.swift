import Foundation

/// Fast local persistence for the floating glass scratchpad drawer.
public struct ScratchpadData: Codable, Equatable, Sendable {
    public var text: String
    public var lastModified: Date

    public init(text: String = "", lastModified: Date = Date()) {
        self.text = text
        self.lastModified = lastModified
    }
}

public final class ScratchpadStorage: @unchecked Sendable {
    private let userDefaults: UserDefaults
    private let storageKey = "macstash.scratchpad.data"

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func load() -> ScratchpadData {
        guard let data = userDefaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(ScratchpadData.self, from: data) else {
            return ScratchpadData()
        }
        return decoded
    }

    public func save(_ data: ScratchpadData) {
        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults.set(encoded, forKey: storageKey)
        }
    }

    public func clear() {
        userDefaults.removeObject(forKey: storageKey)
    }
}
