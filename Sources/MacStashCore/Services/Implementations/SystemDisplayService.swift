import Foundation
import CoreGraphics
import AppKit

public final class SystemDisplayService: DisplayServiceProtocol {
    public init() {}

    public func activeDisplays() -> [DisplayInfo] {
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &count) == .success, count > 0 else {
            return []
        }

        var displayIDs = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetActiveDisplayList(count, &displayIDs, &count) == .success else {
            return []
        }

        var list: [DisplayInfo] = []
        for id in displayIDs {
            let uuid = getDisplayUUID(id: id)
            let isBuiltIn = CGDisplayIsBuiltin(id) != 0
            let name = getDisplayName(id: id, isBuiltIn: isBuiltIn)
            let frame = CGDisplayBounds(id)

            list.append(DisplayInfo(id: id, uuid: uuid, name: name, frame: frame, isBuiltIn: isBuiltIn))
        }

        return list
    }

    public func display(containing point: CGPoint) -> DisplayInfo? {
        let all = activeDisplays()
        return all.first { $0.frame.contains(point) }
    }

    public func display(id: CGDirectDisplayID) -> DisplayInfo? {
        activeDisplays().first { $0.id == id }
    }

    private func getDisplayUUID(id: CGDirectDisplayID) -> String {
        if let cfUUID = CGDisplayCreateUUIDFromDisplayID(id) {
            let uuidString = CFUUIDCreateString(kCFAllocatorDefault, cfUUID.takeRetainedValue()) as String
            return uuidString
        }
        return "display-\(id)"
    }

    private func getDisplayName(id: CGDirectDisplayID, isBuiltIn: Bool) -> String {
        for screen in NSScreen.screens {
            if let screenNum = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
               screenNum == id {
                return screen.localizedName
            }
        }
        return isBuiltIn ? "Built-in Display" : "External Display (\(id))"
    }
}
