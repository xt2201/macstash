import Foundation
import AppKit
import Darwin

// MARK: - MediaRemote Private Framework Bridge (Loaded inside /usr/bin/perl Platform Binary)

private final class MediaRemoteAdapter: @unchecked Sendable {
    static let shared = MediaRemoteAdapter()

    typealias RegisterNotificationsFn = @convention(c) (DispatchQueue) -> Void
    typealias SetWantsNotificationsFn = @convention(c) (Bool) -> Void
    typealias GetClientsFn = @convention(c) (DispatchQueue, @escaping (NSArray?) -> Void) -> Void
    typealias GetClientFn = @convention(c) (DispatchQueue, @escaping (AnyObject?) -> Void) -> Void
    typealias GetAppPIDFn = @convention(c) (DispatchQueue, @escaping (Int32) -> Void) -> Void
    typealias GetAppDisplayIDFn = @convention(c) (DispatchQueue, @escaping (CFString?) -> Void) -> Void
    typealias GetAppIsPlayingFn = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
    typealias GetNowPlayingInfoFn = @convention(c) (DispatchQueue, @escaping (NSDictionary?) -> Void) -> Void
    typealias GetNowPlayingInfoForPlayerFn = @convention(c) (AnyObject, Bool, DispatchQueue, @escaping (NSDictionary?) -> Void) -> Void
    typealias GetPlaybackStateForPlayerFn = @convention(c) (AnyObject, DispatchQueue, @escaping (UInt32) -> Void) -> Void
    typealias ClientGetPIDFn = @convention(c) (AnyObject) -> Int32
    typealias ClientGetStringFn = @convention(c) (AnyObject) -> Unmanaged<CFString>?
    typealias SendCommandFn = @convention(c) (Int32, CFDictionary?) -> Bool
    typealias SendCommandToPlayerFn = @convention(c) (Int32, CFDictionary?, AnyObject, Int32, DispatchQueue, @escaping (UInt32, NSArray?) -> Void) -> Void
    typealias ArtworkCopyImageDataFn = @convention(c) (AnyObject) -> Unmanaged<CFData>?
    typealias SetElapsedTimeFn = @convention(c) (Double) -> Void

    let queue = DispatchQueue(label: "com.macstash.nowplaying.adapter", qos: .userInteractive)

    var registerNotifications: RegisterNotificationsFn?
    var setWantsNotifications: SetWantsNotificationsFn?
    var getClients: GetClientsFn?
    var getClient: GetClientFn?
    var getAppPID: GetAppPIDFn?
    var getAppDisplayID: GetAppDisplayIDFn?
    var getAppIsPlaying: GetAppIsPlayingFn?
    var getNowPlayingInfo: GetNowPlayingInfoFn?
    var getNowPlayingInfoForPlayer: GetNowPlayingInfoForPlayerFn?
    var getPlaybackStateForPlayer: GetPlaybackStateForPlayerFn?
    var clientGetPID: ClientGetPIDFn?
    var clientGetBundleID: ClientGetStringFn?
    var clientGetParentBundleID: ClientGetStringFn?
    var clientGetDisplayName: ClientGetStringFn?
    var sendCommand: SendCommandFn?
    var sendCommandToPlayer: SendCommandToPlayerFn?
    var artworkCopyImageData: ArtworkCopyImageDataFn?
    var setElapsedTime: SetElapsedTimeFn?

    private var lastActivePlayerPath: AnyObject?
    private var lastPlayerPathsByPID: [Int32: AnyObject] = [:]
    private var lastArtworkSignature: Int = 0
    private var isCollecting: Bool = false
    private var pendingCollect: Bool = false

    private init() {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW) else {
            return
        }

        func sym<T>(_ name: String, as type: T.Type) -> T? {
            guard let ptr = dlsym(handle, name) else { return nil }
            return unsafeBitCast(ptr, to: type)
        }

        registerNotifications = sym("MRMediaRemoteRegisterForNowPlayingNotifications", as: RegisterNotificationsFn.self)
        setWantsNotifications = sym("MRMediaRemoteSetWantsNowPlayingNotifications", as: SetWantsNotificationsFn.self)
        getClients = sym("MRMediaRemoteGetNowPlayingClients", as: GetClientsFn.self)
        getClient = sym("MRMediaRemoteGetNowPlayingClient", as: GetClientFn.self)
        getAppPID = sym("MRMediaRemoteGetNowPlayingApplicationPID", as: GetAppPIDFn.self)
        getAppDisplayID = sym("MRMediaRemoteGetNowPlayingApplicationDisplayID", as: GetAppDisplayIDFn.self)
        getAppIsPlaying = sym("MRMediaRemoteGetNowPlayingApplicationIsPlaying", as: GetAppIsPlayingFn.self)
        getNowPlayingInfo = sym("MRMediaRemoteGetNowPlayingInfo", as: GetNowPlayingInfoFn.self)
        getNowPlayingInfoForPlayer = sym("MRMediaRemoteGetNowPlayingInfoForPlayer", as: GetNowPlayingInfoForPlayerFn.self)
        getPlaybackStateForPlayer = sym("MRMediaRemoteGetPlaybackStateForPlayer", as: GetPlaybackStateForPlayerFn.self)
        clientGetPID = sym("MRNowPlayingClientGetProcessIdentifier", as: ClientGetPIDFn.self)
        clientGetBundleID = sym("MRNowPlayingClientGetBundleIdentifier", as: ClientGetStringFn.self)
        clientGetParentBundleID = sym("MRNowPlayingClientGetParentAppBundleIdentifier", as: ClientGetStringFn.self)
        clientGetDisplayName = sym("MRNowPlayingClientGetDisplayName", as: ClientGetStringFn.self)
        sendCommand = sym("MRMediaRemoteSendCommand", as: SendCommandFn.self)
        sendCommandToPlayer = sym("MRMediaRemoteSendCommandToPlayer", as: SendCommandToPlayerFn.self)
        artworkCopyImageData = sym("MRNowPlayingArtworkCopyImageData", as: ArtworkCopyImageDataFn.self)
        setElapsedTime = sym("MRMediaRemoteSetElapsedTime", as: SetElapsedTimeFn.self)
    }

    struct CandidateSnapshot {
        var playerPath: AnyObject?
        var pid: Int32 = 0
        var bundleID: String = ""
        var parentBundleID: String = ""
        var displayName: String = ""
        var isPlaying: Bool = false
        var title: String = ""
        var artist: String = ""
        var album: String = ""
        var duration: Double = 0.0
        var elapsedTime: Double = 0.0
        var playbackRate: Double = 0.0
        var artworkData: Data? = nil
        var artworkMIMEType: String = ""
        var isPrimaryClient: Bool = false
    }

    func extractString(_ fn: ClientGetStringFn?, client: AnyObject) -> String {
        guard let fn = fn, let unmanaged = fn(client) else { return "" }
        return unmanaged.takeUnretainedValue() as String
    }

    /// Constructs an `MRPlayerPath` targeting a specific process PID and bundle identifier,
    /// matching Vorssaint's `NotchNativePlayback.select()` implementation.
    func makePlayerPath(pid: Int32, bundleIdentifier: String) -> AnyObject? {
        guard pid > 0 else { return nil }
        guard let playerPathClass = NSClassFromString("MRPlayerPath") as? NSObject.Type,
              let clientClass = NSClassFromString("MRClient") as? NSObject.Type else {
            return nil
        }

        let localPlayerPathSel = NSSelectorFromString("localPlayerPath")
        let initBundleSel = NSSelectorFromString("initWithBundleIdentifier:")
        let setPIDSel = NSSelectorFromString("setProcessIdentifier:")
        let setClientSel = NSSelectorFromString("setClient:")
        let setPlayerSel = NSSelectorFromString("setPlayer:")

        guard (playerPathClass as AnyObject).responds(to: localPlayerPathSel),
              let baseUnmanaged = (playerPathClass as AnyObject).perform(localPlayerPathSel),
              let baseObj = baseUnmanaged.takeUnretainedValue() as? NSObject,
              let playerPath = baseObj.copy() as? NSObject else {
            return nil
        }

        let resolvedBundle = bundleIdentifier.isEmpty
            ? (NSRunningApplication(processIdentifier: pid)?.bundleIdentifier ?? "com.apple.WebKit.GPU")
            : bundleIdentifier

        let allocSel = NSSelectorFromString("alloc")
        guard let allocatedUnmanaged = (clientClass as AnyObject).perform(allocSel) else {
            return nil
        }
        let allocatedObj = allocatedUnmanaged.takeUnretainedValue() as AnyObject
        guard allocatedObj.responds(to: initBundleSel),
              let clientUnmanaged = allocatedObj.perform(initBundleSel, with: resolvedBundle as NSString) else {
            return nil
        }
        let mrClient = clientUnmanaged.takeRetainedValue() as AnyObject

        if mrClient.responds(to: setPIDSel),
           let mrClientNSObj = mrClient as? NSObject {
            typealias SetPIDIMP = @convention(c) (AnyObject, Selector, Int32) -> Void
            let imp = mrClientNSObj.method(for: setPIDSel)
            let setPID = unsafeBitCast(imp, to: SetPIDIMP.self)
            setPID(mrClient, setPIDSel, pid)
        }

        if playerPath.responds(to: setClientSel) {
            _ = playerPath.perform(setClientSel, with: mrClient)
        }
        if playerPath.responds(to: setPlayerSel) {
            _ = playerPath.perform(setPlayerSel, with: nil)
        }

        return playerPath
    }

    func collectAndEmit(deduplicateArtwork: Bool, completion: (@Sendable () -> Void)? = nil) {
        queue.async { [weak self] in
            guard let self = self else {
                completion?()
                return
            }
            if self.isCollecting {
                self.pendingCollect = true
                completion?()
                return
            }
            self.isCollecting = true
            self.performCollection(deduplicateArtwork: deduplicateArtwork) {
                self.queue.async {
                    self.isCollecting = false
                    if self.pendingCollect {
                        self.pendingCollect = false
                        self.collectAndEmit(deduplicateArtwork: deduplicateArtwork, completion: nil)
                    }
                    completion?()
                }
            }
        }
    }

    private func performCollection(deduplicateArtwork: Bool, done: @escaping @Sendable () -> Void) {
        let topGroup = DispatchGroup()

        var clientObjects: [AnyObject] = []
        var activeClientObj: AnyObject? = nil
        var globalPID: Int32 = 0
        var globalDisplayID: String = ""
        var globalIsPlaying: Bool = false
        var globalInfoDict: NSDictionary? = nil

        if let getClients = getClients {
            topGroup.enter()
            getClients(queue) { arr in
                if let arr = arr {
                    for item in arr {
                        clientObjects.append(item as AnyObject)
                    }
                }
                topGroup.leave()
            }
        }

        if let getClient = getClient {
            topGroup.enter()
            getClient(queue) { client in
                activeClientObj = client
                topGroup.leave()
            }
        }

        if let getAppPID = getAppPID {
            topGroup.enter()
            getAppPID(queue) { pid in
                globalPID = pid
                topGroup.leave()
            }
        }

        if let getAppDisplayID = getAppDisplayID {
            topGroup.enter()
            getAppDisplayID(queue) { disp in
                if let disp = disp {
                    globalDisplayID = disp as String
                }
                topGroup.leave()
            }
        }

        if let getAppIsPlaying = getAppIsPlaying {
            topGroup.enter()
            getAppIsPlaying(queue) { playing in
                globalIsPlaying = playing
                topGroup.leave()
            }
        }

        if let getNowPlayingInfo = getNowPlayingInfo {
            topGroup.enter()
            getNowPlayingInfo(queue) { dict in
                globalInfoDict = dict
                topGroup.leave()
            }
        }

        topGroup.notify(queue: queue) { [weak self] in
            guard let self = self else {
                done()
                return
            }

            let activePID = activeClientObj.flatMap { self.clientGetPID?($0) } ?? globalPID

            // Ensure activeClientObj is included in clientObjects if not already present
            if let active = activeClientObj {
                let aPID = self.clientGetPID?(active) ?? 0
                let exists = clientObjects.contains { (self.clientGetPID?($0) ?? -1) == aPID }
                if !exists {
                    clientObjects.insert(active, at: 0)
                }
            }

            // Build candidate descriptors from MRNowPlayingClients
            struct ClientDescriptor {
                var pid: Int32
                var bundleID: String
                var parentBundleID: String
                var displayName: String
            }

            var descriptors: [ClientDescriptor] = []
            var seenPIDs = Set<Int32>()

            for client in clientObjects {
                let cPID = self.clientGetPID?(client) ?? 0
                guard cPID > 0, !seenPIDs.contains(cPID) else { continue }
                seenPIDs.insert(cPID)

                let runApp = NSRunningApplication(processIdentifier: cPID)
                let cBundle = self.extractString(self.clientGetBundleID, client: client)
                let resolvedBundle = !cBundle.isEmpty ? cBundle : (runApp?.bundleIdentifier ?? "")
                let cParent = self.extractString(self.clientGetParentBundleID, client: client)
                let cName = self.extractString(self.clientGetDisplayName, client: client)
                let resolvedName = !cName.isEmpty ? cName : (runApp?.localizedName ?? "")

                descriptors.append(
                    ClientDescriptor(
                        pid: cPID,
                        bundleID: resolvedBundle,
                        parentBundleID: cParent,
                        displayName: resolvedName
                    )
                )
            }

            if globalPID > 0 && !seenPIDs.contains(globalPID) {
                seenPIDs.insert(globalPID)
                let runApp = NSRunningApplication(processIdentifier: globalPID)
                descriptors.append(
                    ClientDescriptor(
                        pid: globalPID,
                        bundleID: runApp?.bundleIdentifier ?? globalDisplayID,
                        parentBundleID: globalDisplayID,
                        displayName: runApp?.localizedName ?? ""
                    )
                )
            }

            // Also scan NSWorkspace.shared.runningApplications for active media/browser/WebKit GPU processes
            let candidatePrefixes = [
                "com.apple.WebKit.GPU",
                "com.apple.Music",
                "com.spotify.client",
                "com.pauldavis.crest",
                "com.apple.Safari",
                "com.google.Chrome",
                "company.thebrowser.Browser",
                "com.brave.Browser",
                "org.mozilla.firefox",
                "com.microsoft.edgemac",
                "com.operasoftware.Opera",
                "com.vivaldi.Vivaldi",
                "com.colliderli.iina",
                "org.videolan.vlc",
                "com.tidal.desktop",
                "com.amazon.music"
            ]
            for app in NSWorkspace.shared.runningApplications where !app.isTerminated {
                let pid = app.processIdentifier
                guard pid > 0, !seenPIDs.contains(pid), let bid = app.bundleIdentifier else { continue }
                if candidatePrefixes.contains(where: { bid.hasPrefix($0) }) {
                    seenPIDs.insert(pid)
                    descriptors.append(
                        ClientDescriptor(
                            pid: pid,
                            bundleID: bid,
                            parentBundleID: "",
                            displayName: app.localizedName ?? ""
                        )
                    )
                }
            }

            guard !descriptors.isEmpty,
                  let getInfoForPlayer = self.getNowPlayingInfoForPlayer else {
                let snap = self.buildSnapshot(
                    playerPath: nil,
                    pid: globalPID,
                    bundleID: globalDisplayID,
                    parentBundleID: "",
                    displayName: "",
                    isPlaying: globalIsPlaying,
                    info: globalInfoDict,
                    isPrimary: true
                )
                self.emitSnapshot(snap, deduplicateArtwork: deduplicateArtwork)
                done()
                return
            }

            let clientGroup = DispatchGroup()
            var snapshots: [CandidateSnapshot] = []

            for desc in descriptors {
                guard let playerPath = self.makePlayerPath(pid: desc.pid, bundleIdentifier: desc.bundleID) else {
                    continue
                }

                var cState: UInt32 = 0
                var cInfo: NSDictionary? = nil

                clientGroup.enter()
                let itemGroup = DispatchGroup()

                if let getState = self.getPlaybackStateForPlayer {
                    itemGroup.enter()
                    getState(playerPath, self.queue) { state in
                        cState = state
                        itemGroup.leave()
                    }
                }

                itemGroup.enter()
                getInfoForPlayer(playerPath, true, self.queue) { dict in
                    cInfo = dict
                    itemGroup.leave()
                }

                itemGroup.notify(queue: self.queue) {
                    let rate = (cInfo?["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? NSNumber)?.doubleValue ?? 0.0
                    let playing = (cState == 1) || (rate > 0.0001) || (desc.pid == globalPID && globalIsPlaying)
                    let snap = self.buildSnapshot(
                        playerPath: playerPath,
                        pid: desc.pid,
                        bundleID: desc.bundleID,
                        parentBundleID: desc.parentBundleID,
                        displayName: desc.displayName,
                        isPlaying: playing,
                        info: cInfo ?? (desc.pid == globalPID ? globalInfoDict : nil),
                        isPrimary: desc.pid == activePID && activePID != 0
                    )
                    snapshots.append(snap)
                    clientGroup.leave()
                }
            }

            clientGroup.notify(queue: self.queue) {
                self.lastPlayerPathsByPID.removeAll()
                for snap in snapshots {
                    if snap.pid > 0, let pp = snap.playerPath {
                        self.lastPlayerPathsByPID[snap.pid] = pp
                    }
                }

                let sorted = snapshots.sorted { a, b in
                    let aHasTitle = !a.title.isEmpty
                    let bHasTitle = !b.title.isEmpty
                    if aHasTitle != bHasTitle { return aHasTitle }
                    if a.isPlaying != b.isPlaying { return a.isPlaying }
                    if a.isPrimaryClient != b.isPrimaryClient { return a.isPrimaryClient }
                    if (a.artworkData != nil) != (b.artworkData != nil) { return a.artworkData != nil }
                    return a.pid > b.pid
                }

                if let best = sorted.first, !best.title.isEmpty || best.isPlaying {
                    self.lastActivePlayerPath = best.playerPath
                    self.emitSnapshot(best, deduplicateArtwork: deduplicateArtwork)
                } else {
                    let fallback = self.buildSnapshot(
                        playerPath: sorted.first?.playerPath,
                        pid: globalPID,
                        bundleID: globalDisplayID,
                        parentBundleID: "",
                        displayName: "",
                        isPlaying: globalIsPlaying,
                        info: globalInfoDict,
                        isPrimary: true
                    )
                    self.lastActivePlayerPath = fallback.playerPath
                    self.emitSnapshot(fallback, deduplicateArtwork: deduplicateArtwork)
                }
                done()
            }
        }
    }

    private func buildSnapshot(
        playerPath: AnyObject?,
        pid: Int32,
        bundleID: String,
        parentBundleID: String,
        displayName: String,
        isPlaying: Bool,
        info: NSDictionary?,
        isPrimary: Bool
    ) -> CandidateSnapshot {
        var snap = CandidateSnapshot(
            playerPath: playerPath,
            pid: pid,
            bundleID: bundleID,
            parentBundleID: parentBundleID,
            displayName: displayName,
            isPlaying: isPlaying,
            isPrimaryClient: isPrimary
        )

        if let dict = info {
            if let t = dict["kMRMediaRemoteNowPlayingInfoTitle"] as? String {
                snap.title = t
            }
            if let a = dict["kMRMediaRemoteNowPlayingInfoArtist"] as? String {
                snap.artist = a
            }
            if let alb = dict["kMRMediaRemoteNowPlayingInfoAlbum"] as? String {
                snap.album = alb
            }
            if let dur = (dict["kMRMediaRemoteNowPlayingInfoDuration"] as? NSNumber)?.doubleValue {
                snap.duration = dur
            }
            if let elap = (dict["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? NSNumber)?.doubleValue {
                var computed = elap
                if let tsDate = dict["kMRMediaRemoteNowPlayingInfoTimestamp"] as? Date {
                    let delta = Date().timeIntervalSince(tsDate)
                    let rate = (dict["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? NSNumber)?.doubleValue ?? (snap.isPlaying ? 1.0 : 0.0)
                    if delta > 0 && rate > 0.001 {
                        computed += delta * rate
                    }
                }
                snap.elapsedTime = computed
            }
            if let rate = (dict["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? NSNumber)?.doubleValue {
                snap.playbackRate = rate
            }
            if let artData = dict["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data, !artData.isEmpty {
                snap.artworkData = artData
            } else if let artObj = dict["kMRMediaRemoteNowPlayingInfoArtworkData"],
                      let copyFn = artworkCopyImageData,
                      let cfData = copyFn(artObj as AnyObject)?.takeRetainedValue() as Data?,
                      !cfData.isEmpty {
                snap.artworkData = cfData
            }
            if let mime = dict["kMRMediaRemoteNowPlayingInfoArtworkMIMEType"] as? String {
                snap.artworkMIMEType = mime
            }
        }
        return snap
    }

    private func computeArtworkSignature(_ data: Data?) -> Int {
        guard let data = data, !data.isEmpty else { return 0 }
        var hasher = Hasher()
        hasher.combine(data.count)
        let prefixCount = min(512, data.count)
        let suffixCount = min(512, data.count)
        hasher.combine(data.prefix(prefixCount))
        hasher.combine(data.suffix(suffixCount))
        return hasher.finalize()
    }

    private func emitSnapshot(_ snap: CandidateSnapshot, deduplicateArtwork: Bool) {
        let effectiveDisplayID = !snap.parentBundleID.isEmpty ? snap.parentBundleID : snap.bundleID

        var payload: [String: Any] = [
            "pid": snap.pid,
            "displayID": effectiveDisplayID,
            "bundleID": snap.bundleID,
            "parentBundleID": snap.parentBundleID,
            "appName": snap.displayName,
            "isPlaying": snap.isPlaying,
            "kMRMediaRemoteNowPlayingInfoTitle": snap.title,
            "kMRMediaRemoteNowPlayingInfoArtist": snap.artist,
            "kMRMediaRemoteNowPlayingInfoAlbum": snap.album,
            "kMRMediaRemoteNowPlayingInfoDuration": snap.duration,
            "kMRMediaRemoteNowPlayingInfoElapsedTime": snap.elapsedTime,
            "kMRMediaRemoteNowPlayingInfoPlaybackRate": snap.playbackRate
        ]

        let sig = computeArtworkSignature(snap.artworkData)
        if let artData = snap.artworkData {
            if deduplicateArtwork && sig != 0 && sig == lastArtworkSignature {
                payload["artworkUnchanged"] = true
            } else {
                lastArtworkSignature = sig
                payload["artworkBase64"] = artData.base64EncodedString()
                if !snap.artworkMIMEType.isEmpty {
                    payload["artworkMIMEType"] = snap.artworkMIMEType
                }
            }
        } else {
            lastArtworkSignature = 0
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
              var jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        jsonString.append("\n")
        if let outData = jsonString.data(using: .utf8) {
            FileHandle.standardOutput.write(outData)
            fflush(stdout)
        }
    }

    func handleCommandLine(_ rawLine: String) {
        let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if trimmed == "refresh" {
            lastArtworkSignature = 0
            collectAndEmit(deduplicateArtwork: false)
            return
        }

        let parts = trimmed.split(separator: " ").map(String.init)
        var targetPID: Int32 = 0
        var commandWord = trimmed.lowercased()
        var seekParam: Double? = nil

        if parts.count >= 4 && parts[0].lowercased() == "play", let parsedPID = Int32(parts[1]) {
            targetPID = parsedPID
            commandWord = parts[3].lowercased()
        } else if parts.count >= 3 && parts[0].lowercased() == "seek", let parsedPID = Int32(parts[1]), let sec = Double(parts[2]) {
            targetPID = parsedPID
            commandWord = "seek"
            seekParam = sec
        } else if parts.count == 2, let parsedPID = Int32(parts[1]) {
            targetPID = parsedPID
            commandWord = parts[0].lowercased()
        } else if parts.count == 2, let sec = Double(parts[1]) {
            commandWord = parts[0].lowercased()
            seekParam = sec
        }

        if commandWord == "seek" || commandWord == "forward" || commandWord == "skip_forward" || commandWord == "backward" || commandWord == "skip_backward" {
            let current = 0.0
            let targetSeconds: Double
            if commandWord == "forward" || commandWord == "skip_forward" {
                let delta = seekParam ?? 10.0
                targetSeconds = max(0.0, current + delta)
            } else if commandWord == "backward" || commandWord == "skip_backward" {
                let delta = seekParam ?? 10.0
                targetSeconds = max(0.0, current - delta)
            } else {
                targetSeconds = max(0.0, seekParam ?? 0.0)
            }

            queue.async { [weak self] in
                guard let self = self else { return }
                self.setElapsedTime?(targetSeconds)

                let options: CFDictionary = [
                    "kMRMediaRemoteOptionPlaybackPosition" as CFString: NSNumber(value: targetSeconds)
                ] as CFDictionary

                let targetPlayerPath = (targetPID > 0 ? self.lastPlayerPathsByPID[targetPID] : nil) ?? self.lastActivePlayerPath
                if let playerPath = targetPlayerPath, let sendToPlayer = self.sendCommandToPlayer {
                    sendToPlayer(48, options, playerPath, 0, self.queue) { [weak self] _, _ in
                        self?.schedulePostCommandEmit()
                    }
                } else if let sendGlobal = self.sendCommand {
                    _ = sendGlobal(48, options)
                    self.schedulePostCommandEmit()
                }
            }
            return
        }

        let commandID: Int32
        switch commandWord {
        case "play":
            commandID = 0
        case "pause":
            commandID = 1
        case "toggle", "toggleplaypause":
            commandID = 2
        case "stop":
            commandID = 3
        case "next", "nexttrack":
            commandID = 4
        case "previous", "previoustrack", "prev":
            commandID = 5
        default:
            return
        }

        queue.async { [weak self] in
            guard let self = self else { return }
            let targetPlayerPath = (targetPID > 0 ? self.lastPlayerPathsByPID[targetPID] : nil) ?? self.lastActivePlayerPath

            if let playerPath = targetPlayerPath, let sendToPlayer = self.sendCommandToPlayer {
                sendToPlayer(commandID, nil, playerPath, 0, self.queue) { [weak self] _, _ in
                    self?.schedulePostCommandEmit()
                }
            } else if let sendGlobal = self.sendCommand {
                _ = sendGlobal(commandID, nil)
                self.schedulePostCommandEmit()
            }
        }
    }

    private func schedulePostCommandEmit() {
        queue.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.collectAndEmit(deduplicateArtwork: true)
        }
        queue.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            self?.collectAndEmit(deduplicateArtwork: true)
        }
    }

    func startWatchLoop() {
        setWantsNotifications?(true)
        registerNotifications?(DispatchQueue.main)

        let notificationNames = [
            "kMRMediaRemoteNowPlayingInfoDidChangeNotification",
            "kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification",
            "kMRMediaRemoteNowPlayingApplicationDidChangeNotification",
            "kMRMediaRemoteNowPlayingClientDidChangeNotification",
            "kMRMediaRemotePlayerIsPlayingDidChangeNotification",
            "kMRMediaRemotePlayerNowPlayingInfoDidChangeNotification",
            "kMRMediaRemoteNowPlayingPlayersDidChangeNotification",
            "kMRMediaRemotePlayerPlaybackStateDidChangeNotification",
            "kMRMediaRemoteNowPlayingPlayerStateDidChange",
            "kMRMediaRemoteNowPlayingApplicationClientStateDidChange"
        ]

        let center = NotificationCenter.default
        for name in notificationNames {
            center.addObserver(
                forName: Notification.Name(name),
                object: nil,
                queue: nil
            ) { [weak self] _ in
                self?.collectAndEmit(deduplicateArtwork: true)
            }
        }

        var stdinBuffer = Data()
        FileHandle.standardInput.readabilityHandler = { [weak self] handle in
            let chunk = handle.availableData
            if chunk.isEmpty {
                exit(0)
            }
            stdinBuffer.append(chunk)
            while let newlineRange = stdinBuffer.range(of: Data([0x0A])) {
                let lineData = stdinBuffer.subdata(in: 0..<newlineRange.lowerBound)
                stdinBuffer.removeSubrange(0..<newlineRange.upperBound)
                if let line = String(data: lineData, encoding: .utf8) {
                    self?.handleCommandLine(line)
                }
            }
        }

        collectAndEmit(deduplicateArtwork: false)

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 2.5, repeating: 2.5)
        timer.setEventHandler { [weak self] in
            self?.collectAndEmit(deduplicateArtwork: true)
        }
        timer.resume()

        withExtendedLifetime(timer) {
            RunLoop.main.run()
        }
    }
}

@_cdecl("macstash_now_playing_get")
public func macstash_now_playing_get() -> Int32 {
    let sema = DispatchSemaphore(value: 0)
    MediaRemoteAdapter.shared.collectAndEmit(deduplicateArtwork: false) {
        sema.signal()
    }
    _ = sema.wait(timeout: .now() + 2.5)
    Darwin.exit(0)
}

@_cdecl("macstash_now_playing_watch")
public func macstash_now_playing_watch() -> Int32 {
    MediaRemoteAdapter.shared.startWatchLoop()
    Darwin.exit(0)
}

@_cdecl("macstash_now_playing_watch_all")
public func macstash_now_playing_watch_all() -> Int32 {
    MediaRemoteAdapter.shared.startWatchLoop()
    Darwin.exit(0)
}
