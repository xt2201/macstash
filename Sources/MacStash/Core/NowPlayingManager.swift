import Foundation
import AppKit
import Combine
import OSLog
import MacStashCore

/// Manages system-wide audio media playback detection, track metadata, album artwork,
/// and transport controls (Play/Pause, Next, Previous) using Apple's native MediaRemote framework.
@MainActor
public final class NowPlayingManager: ObservableObject {
    public static let shared = NowPlayingManager()

    @Published public private(set) var title: String = ""
    @Published public private(set) var artist: String = ""
    @Published public private(set) var album: String = ""
    @Published public private(set) var artworkImage: NSImage? = nil
    @Published public private(set) var isPlaying: Bool = false
    @Published public private(set) var hasMedia: Bool = false
    @Published public private(set) var duration: Double = 0.0
    @Published public private(set) var elapsedTime: Double = 0.0

    // Dynamic MediaRemote function pointers
    private typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]?) -> Void) -> Void
    private typealias MRMediaRemoteRegisterFunction = @convention(c) (DispatchQueue) -> Void
    private typealias MRMediaRemoteGetIsPlayingFunction = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
    private typealias MRMediaRemoteSendCommandFunction = @convention(c) (Int32, AnyObject?) -> Bool

    private var getNowPlayingInfoFunc: MRMediaRemoteGetNowPlayingInfoFunction?
    private var registerForNotificationsFunc: MRMediaRemoteRegisterFunction?
    private var getIsPlayingFunc: MRMediaRemoteGetIsPlayingFunction?
    private var sendCommandFunc: MRMediaRemoteSendCommandFunction?

    private let backgroundQueue = DispatchQueue(label: "com.macstash.nowplaying", qos: .userInteractive)

    private init() {
        loadMediaRemoteFramework()
        setupNotificationObservers()
        refreshNowPlaying()
    }

    // MARK: - Framework Initialization

    private func loadMediaRemoteFramework() {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW) else {
            AppLogger.audio.error("Failed to load MediaRemote.framework")
            return
        }

        if let getInfoSym = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") {
            getNowPlayingInfoFunc = unsafeBitCast(getInfoSym, to: MRMediaRemoteGetNowPlayingInfoFunction.self)
        }
        if let registerSym = dlsym(handle, "MRMediaRemoteRegisterForNowPlayingNotifications") {
            registerForNotificationsFunc = unsafeBitCast(registerSym, to: MRMediaRemoteRegisterFunction.self)
        }
        if let isPlayingSym = dlsym(handle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying") {
            getIsPlayingFunc = unsafeBitCast(isPlayingSym, to: MRMediaRemoteGetIsPlayingFunction.self)
        }
        if let sendCmdSym = dlsym(handle, "MRMediaRemoteSendCommand") {
            sendCommandFunc = unsafeBitCast(sendCmdSym, to: MRMediaRemoteSendCommandFunction.self)
        }

        if let registerFunc = registerForNotificationsFunc {
            registerFunc(backgroundQueue)
        }
    }

    // MARK: - Notification Listeners

    private func setupNotificationObservers() {
        let center = NotificationCenter.default
        let infoChangeName = Notification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification")
        let isPlayingChangeName = Notification.Name("kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification")

        center.addObserver(
            forName: infoChangeName,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshNowPlaying()
            }
        }

        center.addObserver(
            forName: isPlayingChangeName,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshPlaybackState()
            }
        }
    }

    // MARK: - State Refresh

    public func refreshNowPlaying() {
        guard let getInfo = getNowPlayingInfoFunc else { return }

        getInfo(backgroundQueue) { [weak self] infoDict in
            var trackTitle = ""
            var trackArtist = ""
            var trackAlbum = ""
            var artwork: NSImage? = nil
            var trackDuration: Double = 0.0
            var trackElapsed: Double = 0.0
            var active = false

            if let dict = infoDict, !dict.isEmpty {
                if let t = dict["kMRMediaRemoteNowPlayingInfoTitle"] as? String, !t.isEmpty {
                    trackTitle = t
                    active = true
                }
                if let a = dict["kMRMediaRemoteNowPlayingInfoArtist"] as? String {
                    trackArtist = a
                }
                if let alb = dict["kMRMediaRemoteNowPlayingInfoAlbum"] as? String {
                    trackAlbum = alb
                }
                if let data = dict["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data {
                    artwork = NSImage(data: data)
                }
                if let dur = dict["kMRMediaRemoteNowPlayingInfoDuration"] as? Double {
                    trackDuration = dur
                }
                if let elap = dict["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double {
                    trackElapsed = elap
                }
            }

            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.title = trackTitle
                self.artist = trackArtist
                self.album = trackAlbum
                self.artworkImage = artwork
                self.duration = trackDuration
                self.elapsedTime = trackElapsed
                self.hasMedia = active
            }

            Task { @MainActor [weak self] in
                self?.refreshPlaybackState()
            }
        }
    }

    public func refreshPlaybackState() {
        guard let getPlaying = getIsPlayingFunc else { return }

        getPlaying(backgroundQueue) { [weak self] playing in
            Task { @MainActor [weak self] in
                self?.isPlaying = playing
            }
        }
    }

    // MARK: - Transport Controls

    public func togglePlayPause() {
        HapticManager.shared.performDetentTick()
        SoundEffectManager.shared.playAccent()

        if let send = sendCommandFunc {
            let success = send(2, nil) // 2 = togglePlayPause
            if success {
                self.isPlaying.toggle()
                scheduleDelayedRefresh()
                return
            }
        }

        // Fallback: system media key Play/Pause (Keycode 16)
        sendSystemMediaKey(key: 16)
        scheduleDelayedRefresh()
    }

    public func nextTrack() {
        HapticManager.shared.performDetentTick()
        SoundEffectManager.shared.playAccent()

        if let send = sendCommandFunc {
            let success = send(4, nil) // 4 = nextTrack
            if success {
                scheduleDelayedRefresh()
                return
            }
        }

        // Fallback: system media key Next (Keycode 17)
        sendSystemMediaKey(key: 17)
        scheduleDelayedRefresh()
    }

    public func previousTrack() {
        HapticManager.shared.performDetentTick()
        SoundEffectManager.shared.playAccent()

        if let send = sendCommandFunc {
            let success = send(5, nil) // 5 = previousTrack
            if success {
                scheduleDelayedRefresh()
                return
            }
        }

        // Fallback: system media key Previous (Keycode 18)
        sendSystemMediaKey(key: 18)
        scheduleDelayedRefresh()
    }

    private func scheduleDelayedRefresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.refreshNowPlaying()
        }
    }

    private func sendSystemMediaKey(key: Int32) {
        let downEvent = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: 0xa00),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((key << 16) | (0xa << 8)),
            data2: -1
        )
        downEvent?.cgEvent?.post(tap: .cghidEventTap)

        let upEvent = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: 0xb00),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((key << 16) | (0xb << 8)),
            data2: -1
        )
        upEvent?.cgEvent?.post(tap: .cghidEventTap)
    }
}
