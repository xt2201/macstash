import AppKit
import ApplicationServices
import SideDockCore

@MainActor
public final class ReserveSpaceManager: ObservableObject {
    public static let shared = ReserveSpaceManager()

    private let policy = ReserveSpacePolicy()
    private var workspaceObserver: NSObjectProtocol?
    private var isObserving = false

    public init() {}

    public func startObserving(dockFrameProvider: @escaping @MainActor @Sendable () -> (CGRect, DockPlacement, CGRect)?) {
        guard !isObserving else { return }
        isObserving = true

        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self = self else { return }
                guard let (dockFrame, placement, screenVisible) = dockFrameProvider() else { return }
                self.adjustFrontmostWindow(dockFrame: dockFrame, placement: placement, screenVisible: screenVisible)
            }
        }
    }

    public func stopObserving() {
        if let observer = workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            workspaceObserver = nil
        }
        isObserving = false
    }

    public func adjustFrontmostWindow(dockFrame: CGRect, placement: DockPlacement, screenVisible: CGRect) {
        guard placement != .floating else { return }
        guard AXIsProcessTrusted() else { return }

        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              frontApp.bundleIdentifier != Bundle.main.bundleIdentifier else {
            return
        }

        let appRef = AXUIElementCreateApplication(frontApp.processIdentifier)
        var windowVal: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &windowVal)
        guard err == .success, let windowVal = windowVal, CFGetTypeID(windowVal) == AXUIElementGetTypeID() else {
            return
        }

        // swiftlint:disable:next force_cast
        let windowRef = windowVal as! AXUIElement

        var posVal: CFTypeRef?
        var sizeVal: CFTypeRef?
        guard AXUIElementCopyAttributeValue(windowRef, kAXPositionAttribute as CFString, &posVal) == .success,
              AXUIElementCopyAttributeValue(windowRef, kAXSizeAttribute as CFString, &sizeVal) == .success,
              let posVal = posVal, let sizeVal = sizeVal else {
            return
        }

        var origin = CGPoint.zero
        var size = CGSize.zero
        // swiftlint:disable:next force_cast
        guard AXValueGetValue(posVal as! AXValue, .cgPoint, &origin),
              // swiftlint:disable:next force_cast
              AXValueGetValue(sizeVal as! AXValue, .cgSize, &size) else {
            return
        }

        let currentFrame = CGRect(origin: origin, size: size)
        let adjustedFrame = policy.adjustWindowFrame(
            windowFrame: currentFrame,
            dockFrame: dockFrame,
            placement: placement,
            screenVisibleFrame: screenVisible
        )

        guard adjustedFrame != currentFrame else { return }

        var newOrigin = adjustedFrame.origin
        var newSize = adjustedFrame.size
        if let newPosVal = AXValueCreate(.cgPoint, &newOrigin),
           let newSizeVal = AXValueCreate(.cgSize, &newSize) {
            AXUIElementSetAttributeValue(windowRef, kAXPositionAttribute as CFString, newPosVal)
            AXUIElementSetAttributeValue(windowRef, kAXSizeAttribute as CFString, newSizeVal)
        }
    }
}
