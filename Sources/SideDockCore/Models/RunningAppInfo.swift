import Foundation

public struct RunningAppInfo: Identifiable, Equatable, Sendable {
    public let id: pid_t
    public let bundleIdentifier: String?
    public let localizedName: String
    public let bundleURL: URL?
    public let isHidden: Bool
    public let isActive: Bool

    public init(
        processIdentifier: pid_t,
        bundleIdentifier: String?,
        localizedName: String,
        bundleURL: URL?,
        isHidden: Bool = false,
        isActive: Bool = false
    ) {
        self.id = processIdentifier
        self.bundleIdentifier = bundleIdentifier
        self.localizedName = localizedName
        self.bundleURL = bundleURL
        self.isHidden = isHidden
        self.isActive = isActive
    }
}
