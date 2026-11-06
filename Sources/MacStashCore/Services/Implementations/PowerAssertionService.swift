import Foundation
import IOKit.pwr_mgt

/// Protocol for platform power assertions to prevent macOS display or system sleep.
public protocol PowerAssertionServiceProtocol: AnyObject, Sendable {
    var isActive: Bool { get }
    var remainingSeconds: TimeInterval { get }
    var durationMinutes: Int { get }
    func activate(minutes: Int) -> Bool
    func deactivate()
    func toggle() -> Bool
}

/// Manages macOS I/O Kit power assertions (`kIOPMAssertionTypePreventUserIdleDisplaySleep`)
/// to keep the Mac and its connected displays awake during video rendering, long builds,
/// downloads, or presentations without requiring third-party tools like Amphetamine.
public final class PowerAssertionService: @unchecked Sendable {
    public private(set) var isActive: Bool = false
    public private(set) var remainingSeconds: TimeInterval = 0
    public private(set) var durationMinutes: Int = 0 // 0 = off, -1 = indefinite, >0 = minutes
    public private(set) var expirationDate: Date?

    private var assertionID: IOPMAssertionID = 0
    private let lock = NSLock()

    public init() {}

    deinit {
        deactivate()
    }

    /// Activates sleep prevention for the specified duration in minutes.
    /// - Parameter minutes: Number of minutes (e.g., 15, 30, 60, 120), or -1 for indefinite (until turned off).
    @discardableResult
    public func activate(minutes: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        releaseAssertionIfNeeded()

        let reason = "MacStash Keep Awake Active" as CFString
        var newID: IOPMAssertionID = 0
        let ret = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &newID
        )

        guard ret == kIOReturnSuccess else {
            isActive = false
            assertionID = 0
            durationMinutes = 0
            remainingSeconds = 0
            expirationDate = nil
            return false
        }

        self.assertionID = newID
        self.isActive = true
        self.durationMinutes = minutes

        if minutes > 0 {
            let secs = TimeInterval(minutes * 60)
            self.remainingSeconds = secs
            self.expirationDate = Date().addingTimeInterval(secs)
        } else {
            // Indefinite
            self.remainingSeconds = -1
            self.expirationDate = nil
        }

        return true
    }

    /// Releases any active power assertion and restores macOS default power management.
    public func deactivate() {
        lock.lock()
        defer { lock.unlock() }

        releaseAssertionIfNeeded()
        isActive = false
        durationMinutes = 0
        remainingSeconds = 0
        expirationDate = nil
    }

    /// Toggles between active (indefinite) and inactive state.
    @discardableResult
    public func toggle() -> Bool {
        if isActive {
            deactivate()
            return false
        } else {
            return activate(minutes: -1)
        }
    }

    /// Updates internal timer remaining time, automatically deactivating when expired.
    /// Returns true if still active, false if expired or inactive.
    public func tick() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard isActive else { return false }
        guard let exp = expirationDate else {
            // Indefinite
            return true
        }

        let left = exp.timeIntervalSinceNow
        if left <= 0 {
            releaseAssertionIfNeeded()
            isActive = false
            durationMinutes = 0
            remainingSeconds = 0
            expirationDate = nil
            return false
        } else {
            remainingSeconds = left
            return true
        }
    }

    private func releaseAssertionIfNeeded() {
        if assertionID != 0 {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
        }
    }
}
