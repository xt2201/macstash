import Foundation
import os.log

/// Monitors `~/.Trash` using zero-polling `DispatchSource` filesystem events.
public final class TrashMonitor: @unchecked Sendable {
    private static let logger = Logger(subsystem: "com.macstash.app", category: "trash")
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private let queue = DispatchQueue(label: "com.macstash.sidedock.trash", qos: .utility)

    public init() {}

    deinit {
        stop()
    }

    public func start(onChange: @escaping @Sendable @MainActor (Int) -> Void) {
        stop()
        let trashURL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".Trash")
        let count = Self.countItems(at: trashURL)
        Task { @MainActor in onChange(count) }

        let fd = open(trashURL.path, O_EVTONLY)
        guard fd >= 0 else {
            Self.logger.debug("Could not open ~/.Trash for DispatchSource monitoring")
            return
        }
        fileDescriptor = fd

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename, .attrib],
            queue: queue
        )
        src.setEventHandler {
            let updated = Self.countItems(at: trashURL)
            Task { @MainActor in onChange(updated) }
        }
        src.setCancelHandler { [fd] in
            close(fd)
        }
        source = src
        src.resume()
    }

    public func stop() {
        source?.cancel()
        source = nil
        fileDescriptor = -1
    }

    private static func countItems(at url: URL) -> Int {
        do {
            let items = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            return items.count
        } catch {
            return 0
        }
    }
}
