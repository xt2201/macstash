import Foundation
import AppKit
import SwiftUI
import Combine
import OSLog
import MacStashCore

/// Manages system-wide audio media playback detection, track metadata, album artwork,
/// dominant artwork color tint extraction (`artworkTint`), real-time audio rhythm levels,
/// and transport controls (Play/Pause, Next, Previous) across all macOS applications and browsers.
@MainActor
public final class NowPlayingManager: ObservableObject {
    public static let shared = NowPlayingManager()

    public static let defaultPrimaryTint = Color(red: 1.0, green: 0.40, blue: 0.06)
    public static let defaultSecondaryTint = Color(red: 1.0, green: 0.68, blue: 0.16)

    @Published public private(set) var title: String = ""
    @Published public private(set) var artist: String = ""
    @Published public private(set) var album: String = ""
    @Published public private(set) var appName: String = ""
    @Published public private(set) var appBundleID: String = ""
    @Published public private(set) var playingPID: Int32 = 0
    @Published public private(set) var artworkImage: NSImage? = nil
    @Published public private(set) var artworkTint: Color = NowPlayingManager.defaultPrimaryTint
    @Published public private(set) var artworkSecondaryTint: Color = NowPlayingManager.defaultSecondaryTint
    @Published public private(set) var isPlaying: Bool = false
    @Published public private(set) var hasMedia: Bool = false
    @Published public private(set) var duration: Double = 0.0
    @Published public private(set) var elapsedTime: Double = 0.0
    @Published public private(set) var audioLevels: [CGFloat] = [0.18, 0.18, 0.18, 0.18, 0.18]

    private var helperProcess: Process?
    private var stdinPipe: Pipe?
    private var stdoutPipe: Pipe?
    private var stdoutBuffer = Data()
    private var restartWorkItem: DispatchWorkItem?
    private var isShuttingDown = false

    // Beat / rhythm envelope generator state
    private var rhythmTimer: Timer?
    private var isVisualizerActive: Bool = false
    private var smoothedBands: [Double] = [0.18, 0.18, 0.18, 0.18, 0.18]
    private var beatPhase: Double = 0.0
    private var trackSeed: Double = 1.0

    // Fallback in-process MediaRemote symbols (used only if Perl helper is unavailable)
    private typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]?) -> Void) -> Void
    private typealias MRMediaRemoteGetIsPlayingFunction = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
    private typealias MRMediaRemoteSendCommandFunction = @convention(c) (Int32, AnyObject?) -> Bool

    private var getNowPlayingInfoFunc: MRMediaRemoteGetNowPlayingInfoFunction?
    private var getIsPlayingFunc: MRMediaRemoteGetIsPlayingFunction?
    private var sendCommandFunc: MRMediaRemoteSendCommandFunction?

    private let backgroundQueue = DispatchQueue(label: "com.macstash.nowplaying", qos: .userInteractive)

    private init() {
        loadFallbackMediaRemoteFramework()
        startHelperProcessIfPossible()
    }

    // MARK: - Platform-Binary Perl Bridge (`now-playing.pl` + `libMacStashNowPlaying.dylib`)

    private func resolveHelperPaths() -> (scriptPath: String, dylibPath: String)? {
        let fm = FileManager.default

        var scriptCandidates: [String] = []
        if let bundledScript = Bundle.main.path(forResource: "now-playing", ofType: "pl") {
            scriptCandidates.append(bundledScript)
        }
        if let resURL = Bundle.main.resourceURL {
            scriptCandidates.append(resURL.appendingPathComponent("now-playing.pl").path)
            scriptCandidates.append(resURL.appendingPathComponent("MacStash_MacStash.bundle/now-playing.pl").path)
            scriptCandidates.append(resURL.appendingPathComponent("MacStash_MacStash.bundle/Contents/Resources/now-playing.pl").path)
        }
        if let execURL = Bundle.main.executableURL {
            let contentsURL = execURL.deletingLastPathComponent().deletingLastPathComponent()
            scriptCandidates.append(contentsURL.appendingPathComponent("Resources/now-playing.pl").path)
        }
        scriptCandidates.append("/Applications/Stash.app/Contents/Resources/now-playing.pl")
        scriptCandidates.append(fm.currentDirectoryPath + "/Sources/MacStash/Resources/now-playing.pl")

        var dylibCandidates: [String] = []
        if let fwPath = Bundle.main.privateFrameworksPath {
            dylibCandidates.append((fwPath as NSString).appendingPathComponent("libMacStashNowPlaying.dylib"))
        }
        if let execURL = Bundle.main.executableURL {
            let contentsURL = execURL.deletingLastPathComponent().deletingLastPathComponent()
            dylibCandidates.append(contentsURL.appendingPathComponent("Frameworks/libMacStashNowPlaying.dylib").path)
            // Also check same directory as executable (e.g. .build/debug or .build/release)
            dylibCandidates.append(execURL.deletingLastPathComponent().appendingPathComponent("libMacStashNowPlaying.dylib").path)
        }
        dylibCandidates.append("/Applications/Stash.app/Contents/Frameworks/libMacStashNowPlaying.dylib")
        dylibCandidates.append(fm.currentDirectoryPath + "/.build/release/libMacStashNowPlaying.dylib")
        dylibCandidates.append(fm.currentDirectoryPath + "/.build/debug/libMacStashNowPlaying.dylib")
        dylibCandidates.append(fm.currentDirectoryPath + "/.build/arm64-apple-macosx/release/libMacStashNowPlaying.dylib")

        guard let scriptPath = scriptCandidates.first(where: { fm.isReadableFile(atPath: $0) }),
              let dylibPath = dylibCandidates.first(where: { fm.isReadableFile(atPath: $0) }) else {
            return nil
        }

        return (scriptPath, dylibPath)
    }

    private func startHelperProcessIfPossible() {
        guard helperProcess == nil else { return }
        guard let paths = resolveHelperPaths() else {
            AppLogger.audio.warning("NowPlaying helper paths not found; using fallback MediaRemote loader")
            refreshNowPlayingFallback()
            return
        }

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        proc.arguments = [paths.scriptPath, paths.dylibPath, "watch_all"]

        let inPipe = Pipe()
        let outPipe = Pipe()
        proc.standardInput = inPipe
        proc.standardOutput = outPipe
        proc.standardError = FileHandle.nullDevice

        outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            Task { @MainActor [weak self] in
                self?.consumeStdoutChunk(data)
            }
        }

        proc.terminationHandler = { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.stdoutPipe?.fileHandleForReading.readabilityHandler = nil
                self.helperProcess = nil
                self.stdinPipe = nil
                self.stdoutPipe = nil
                guard !self.isShuttingDown else { return }
                let item = DispatchWorkItem { [weak self] in
                    Task { @MainActor [weak self] in
                        self?.startHelperProcessIfPossible()
                    }
                }
                self.restartWorkItem = item
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: item)
            }
        }

        do {
            try proc.run()
            self.helperProcess = proc
            self.stdinPipe = inPipe
            self.stdoutPipe = outPipe
            AppLogger.audio.info("Started NowPlaying Perl bridge with dylib at \(paths.dylibPath, privacy: .public)")
        } catch {
            AppLogger.audio.error("Failed to launch NowPlaying Perl bridge: \(error.localizedDescription, privacy: .public)")
            refreshNowPlayingFallback()
        }
    }

    private func consumeStdoutChunk(_ chunk: Data) {
        stdoutBuffer.append(chunk)
        while let newlineRange = stdoutBuffer.range(of: Data([0x0A])) {
            let lineData = stdoutBuffer.subdata(in: 0..<newlineRange.lowerBound)
            stdoutBuffer.removeSubrange(0..<newlineRange.upperBound)
            if !lineData.isEmpty {
                parseHelperJSONLine(lineData)
            }
        }
    }

    private func parseHelperJSONLine(_ lineData: Data) {
        guard let dict = try? JSONSerialization.jsonObject(with: lineData, options: []) as? [String: Any] else {
            return
        }

        let newTitle = (dict["kMRMediaRemoteNowPlayingInfoTitle"] as? String) ?? ""
        let newArtist = (dict["kMRMediaRemoteNowPlayingInfoArtist"] as? String) ?? ""
        let newAlbum = (dict["kMRMediaRemoteNowPlayingInfoAlbum"] as? String) ?? ""
        let newAppName = (dict["appName"] as? String) ?? ""
        let newBundleID = (dict["displayID"] as? String) ?? (dict["bundleID"] as? String) ?? ""
        let newPID = (dict["pid"] as? NSNumber)?.int32Value ?? 0
        let newDuration = (dict["kMRMediaRemoteNowPlayingInfoDuration"] as? NSNumber)?.doubleValue ?? 0.0
        let newElapsed = (dict["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? NSNumber)?.doubleValue ?? 0.0
        let newPlaying = (dict["isPlaying"] as? Bool) ?? ((dict["isPlaying"] as? NSNumber)?.boolValue ?? false)
        let artworkUnchanged = (dict["artworkUnchanged"] as? Bool) ?? false

        if newTitle != self.title || newArtist != self.artist {
            var hasher = Hasher()
            hasher.combine(newTitle)
            hasher.combine(newArtist)
            let hashVal = abs(hasher.finalize())
            self.trackSeed = 0.85 + Double(hashVal % 35) / 100.0
        }

        self.title = newTitle
        self.artist = newArtist
        self.album = newAlbum
        self.appName = newAppName
        self.appBundleID = newBundleID
        self.playingPID = newPID
        self.duration = newDuration
        self.elapsedTime = newElapsed
        self.isPlaying = newPlaying
        self.hasMedia = !newTitle.isEmpty || newPlaying
        updateRhythmEngineState()

        if let b64 = dict["artworkBase64"] as? String,
           !b64.isEmpty,
           let imgData = Data(base64Encoded: b64, options: .ignoreUnknownCharacters),
           let image = NSImage(data: imgData) {
            self.artworkImage = image
            let extracted = Self.extractDominantTint(from: image)
            self.artworkTint = extracted.primary
            self.artworkSecondaryTint = extracted.secondary
        } else if !artworkUnchanged {
            if newTitle.isEmpty && !newPlaying {
                self.artworkImage = nil
                self.artworkTint = Self.defaultPrimaryTint
                self.artworkSecondaryTint = Self.defaultSecondaryTint
            }
        }
    }

    private func sendHelperCommand(_ cmd: String) -> Bool {
        guard let proc = helperProcess, proc.isRunning, let pipe = stdinPipe else {
            return false
        }
        let line = cmd.hasSuffix("\n") ? cmd : (cmd + "\n")
        guard let data = line.data(using: .utf8) else { return false }
        do {
            try pipe.fileHandleForWriting.write(contentsOf: data)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Dominant Artwork Tint Extraction (Vorssaint / Dynamic Island Style)

    public static func extractDominantTint(from image: NSImage) -> (primary: Color, secondary: Color) {
        let sampleSize = 24
        var pixelData = [UInt8](repeating: 0, count: sampleSize * sampleSize * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let ctx = CGContext(
            data: &pixelData,
            width: sampleSize,
            height: sampleSize,
            bitsPerComponent: 8,
            bytesPerRow: sampleSize * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return (defaultPrimaryTint, defaultSecondaryTint)
        }

        var rect = NSRect(x: 0, y: 0, width: sampleSize, height: sampleSize)
        guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
            return (defaultPrimaryTint, defaultSecondaryTint)
        }

        ctx.interpolationQuality = .medium
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: sampleSize, height: sampleSize))

        // 12 hue buckets around the color wheel for robust dominant color clustering
        let bucketCount = 12
        var bucketWeights = [Double](repeating: 0.0, count: bucketCount)
        var bucketHueSin = [Double](repeating: 0.0, count: bucketCount)
        var bucketHueCos = [Double](repeating: 0.0, count: bucketCount)
        var bucketSat = [Double](repeating: 0.0, count: bucketCount)
        var bucketBri = [Double](repeating: 0.0, count: bucketCount)

        var fallbackR = 0.0
        var fallbackG = 0.0
        var fallbackB = 0.0
        var fallbackWeight = 0.0

        for i in stride(from: 0, to: pixelData.count, by: 4) {
            let a = Double(pixelData[i + 3]) / 255.0
            guard a > 0.25 else { continue }

            let r = Double(pixelData[i]) / 255.0
            let g = Double(pixelData[i + 1]) / 255.0
            let b = Double(pixelData[i + 2]) / 255.0

            let maxC = max(r, max(g, b))
            let minC = min(r, min(g, b))
            let delta = maxC - minC
            let brightness = maxC
            let saturation = maxC > 0.001 ? (delta / maxC) : 0.0

            // Track overall non-black average as fallback for monochrome covers
            if brightness > 0.12 && brightness < 0.96 {
                fallbackR += r
                fallbackG += g
                fallbackB += b
                fallbackWeight += 1.0
            }

            // Ignore near-black, near-white, and desaturated gray pixels when finding vibrant tint
            guard brightness > 0.15, saturation > 0.14 else { continue }
            if brightness > 0.94 && saturation < 0.25 { continue }

            var hue: Double = 0.0
            if delta > 0.0001 {
                if maxC == r {
                    hue = ((g - b) / delta).truncatingRemainder(dividingBy: 6.0)
                } else if maxC == g {
                    hue = ((b - r) / delta) + 2.0
                } else {
                    hue = ((r - g) / delta) + 4.0
                }
                hue /= 6.0
                if hue < 0 { hue += 1.0 }
            }

            // Favor vivid, luminous colors
            let weight = pow(saturation, 1.35) * pow(brightness, 0.85)
            let bucket = min(bucketCount - 1, max(0, Int(hue * Double(bucketCount))))
            let angle = hue * 2.0 * .pi

            bucketWeights[bucket] += weight
            bucketHueSin[bucket] += sin(angle) * weight
            bucketHueCos[bucket] += cos(angle) * weight
            bucketSat[bucket] += saturation * weight
            bucketBri[bucket] += brightness * weight
        }

        // Find dominant vibrant hue bucket
        var bestBucket = 0
        var maxWeight = 0.0
        for b in 0..<bucketCount {
            if bucketWeights[b] > maxWeight {
                maxWeight = bucketWeights[b]
                bestBucket = b
            }
        }

        if maxWeight > 0.01 {
            let w = bucketWeights[bestBucket]
            var avgHue = atan2(bucketHueSin[bestBucket] / w, bucketHueCos[bestBucket] / w) / (2.0 * .pi)
            if avgHue < 0 { avgHue += 1.0 }

            let avgSat = bucketSat[bestBucket] / w
            let avgBri = bucketBri[bestBucket] / w

            // Boost saturation and brightness so visualizer bars pop against dark glass
            let vibrantSat = max(0.68, min(1.0, avgSat * 1.25))
            let vibrantBri = max(0.88, min(1.0, avgBri * 1.18))

            let secondaryHue = (avgHue + 0.055).truncatingRemainder(dividingBy: 1.0)
            let secondarySat = max(0.55, min(0.95, vibrantSat * 0.88))
            let secondaryBri = min(1.0, vibrantBri * 1.08)

            let primaryNS = NSColor(hue: avgHue, saturation: vibrantSat, brightness: vibrantBri, alpha: 1.0)
            let secondaryNS = NSColor(hue: secondaryHue, saturation: secondarySat, brightness: secondaryBri, alpha: 1.0)
            return (Color(nsColor: primaryNS), Color(nsColor: secondaryNS))
        }

        if fallbackWeight > 0 {
            let r = fallbackR / fallbackWeight
            let g = fallbackG / fallbackWeight
            let b = fallbackB / fallbackWeight
            let ns = NSColor(srgbRed: r, green: g, blue: b, alpha: 1.0)
            var h: CGFloat = 0, s: CGFloat = 0, v: CGFloat = 0, a: CGFloat = 0
            ns.usingColorSpace(.sRGB)?.getHue(&h, saturation: &s, brightness: &v, alpha: &a)
            if s > 0.06 {
                let primaryNS = NSColor(hue: h, saturation: max(0.55, s * 1.4), brightness: max(0.85, v * 1.2), alpha: 1.0)
                let secondaryNS = NSColor(hue: fmod(h + 0.05, 1.0), saturation: max(0.45, s * 1.2), brightness: 0.98, alpha: 1.0)
                return (Color(nsColor: primaryNS), Color(nsColor: secondaryNS))
            }
        }

        return (defaultPrimaryTint, defaultSecondaryTint)
    }

    // MARK: - Real-Time Rhythm & Beat Envelope Engine

    public func setVisualizerActive(_ active: Bool) {
        isVisualizerActive = active
        updateRhythmEngineState()
    }

    private func updateRhythmEngineState() {
        if isPlaying && isVisualizerActive {
            if rhythmTimer == nil {
                startRhythmEngine()
            }
        } else {
            rhythmTimer?.invalidate()
            rhythmTimer = nil
            smoothedBands = [0.18, 0.18, 0.18, 0.18, 0.18]
            audioLevels = [0.18, 0.18, 0.18, 0.18, 0.18]
        }
    }

    private func startRhythmEngine() {
        rhythmTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.stepRhythmEnvelope()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.rhythmTimer = timer
    }

    private func stepRhythmEnvelope() {
        guard isPlaying else {
            var needsUpdate = false
            for i in 0..<smoothedBands.count {
                if abs(smoothedBands[i] - 0.18) > 0.005 {
                    smoothedBands[i] = smoothedBands[i] * 0.72 + 0.18 * 0.28
                    needsUpdate = true
                } else {
                    smoothedBands[i] = 0.18
                }
            }
            if needsUpdate {
                audioLevels = smoothedBands.map { CGFloat($0) }
            }
            return
        }

        let dt = 1.0 / 30.0
        beatPhase += dt * (2.15 * trackSeed)

        // Sub-bass kick pulse + syncopated snare/hi-hat transient envelope
        let kickPulse = pow(max(0.0, sin(beatPhase * .pi)), 2.6)
        let offBeat = pow(max(0.0, sin((beatPhase * 2.0 + 0.35) * .pi)), 3.2)
        let groove = (sin(beatPhase * 0.75) + 1.0) * 0.5

        let bandFreqs: [Double] = [3.4, 4.9, 6.3, 5.5, 7.8]
        let bandPhases: [Double] = [0.0, 1.1, 2.3, 3.6, 4.7]
        let bandWeights: [Double] = [
            0.78 * kickPulse + 0.22 * groove,
            0.55 * kickPulse + 0.45 * offBeat,
            0.40 * kickPulse + 0.60 * offBeat,
            0.30 * kickPulse + 0.70 * groove,
            0.25 * groove + 0.75 * offBeat
        ]

        let volScale = Double(max(0.45, min(1.0, AudioManager.shared.volume)))

        for i in 0..<5 {
            let osc1 = (sin(beatPhase * bandFreqs[i] + bandPhases[i]) + 1.0) * 0.5
            let osc2 = (cos(beatPhase * (bandFreqs[i] * 0.67) - bandPhases[i] * 1.3) + 1.0) * 0.5
            let rawEnergy = (osc1 * 0.48 + osc2 * 0.22 + bandWeights[i] * 0.30) * volScale
            let target = max(0.18, min(1.0, 0.16 + rawEnergy * 0.88))

            // Fast attack (0.58), smooth natural decay (0.26)
            let alpha = target > smoothedBands[i] ? 0.58 : 0.26
            smoothedBands[i] += (target - smoothedBands[i]) * alpha
        }

        audioLevels = smoothedBands.map { CGFloat($0) }
    }

    // MARK: - State Refresh

    public func refreshNowPlaying() {
        if sendHelperCommand("refresh") {
            return
        }
        startHelperProcessIfPossible()
    }

    // MARK: - Fallback In-Process Loader

    private func loadFallbackMediaRemoteFramework() {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW) else {
            return
        }
        if let getInfoSym = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") {
            getNowPlayingInfoFunc = unsafeBitCast(getInfoSym, to: MRMediaRemoteGetNowPlayingInfoFunction.self)
        }
        if let isPlayingSym = dlsym(handle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying") {
            getIsPlayingFunc = unsafeBitCast(isPlayingSym, to: MRMediaRemoteGetIsPlayingFunction.self)
        }
        if let sendCmdSym = dlsym(handle, "MRMediaRemoteSendCommand") {
            sendCommandFunc = unsafeBitCast(sendCmdSym, to: MRMediaRemoteSendCommandFunction.self)
        }
    }

    private func refreshNowPlayingFallback() {
        guard let getInfo = getNowPlayingInfoFunc else { return }
        getInfo(backgroundQueue) { [weak self] infoDict in
            guard let dict = infoDict, !dict.isEmpty else { return }
            let trackTitle = (dict["kMRMediaRemoteNowPlayingInfoTitle"] as? String) ?? ""
            let trackArtist = (dict["kMRMediaRemoteNowPlayingInfoArtist"] as? String) ?? ""
            let trackAlbum = (dict["kMRMediaRemoteNowPlayingInfoAlbum"] as? String) ?? ""
            let artworkData = dict["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.title = trackTitle
                self.artist = trackArtist
                self.album = trackAlbum
                if let data = artworkData, let img = NSImage(data: data) {
                    self.artworkImage = img
                    let tint = Self.extractDominantTint(from: img)
                    self.artworkTint = tint.primary
                    self.artworkSecondaryTint = tint.secondary
                }
                self.hasMedia = !trackTitle.isEmpty
            }
        }
    }

    // MARK: - Transport Controls

    public func togglePlayPause() {
        HapticManager.shared.performDetentTick()
        SoundEffectManager.shared.playAccent()

        let nextState = !isPlaying
        isPlaying = nextState
        updateRhythmEngineState()

        if sendHelperCommand("toggle") {
            return
        }

        if let send = sendCommandFunc, send(2, nil) {
            return
        }

        sendSystemMediaKey(key: 16)
    }

    public func nextTrack() {
        HapticManager.shared.performDetentTick()
        SoundEffectManager.shared.playAccent()

        if sendHelperCommand("next") {
            return
        }

        if let send = sendCommandFunc, send(4, nil) {
            return
        }

        sendSystemMediaKey(key: 17)
    }

    public func previousTrack() {
        HapticManager.shared.performDetentTick()
        SoundEffectManager.shared.playAccent()

        if sendHelperCommand("previous") {
            return
        }

        if let send = sendCommandFunc, send(5, nil) {
            return
        }

        sendSystemMediaKey(key: 18)
    }

    public func activateCurrentApp() {
        guard !appBundleID.isEmpty else { return }
        if let app = NSRunningApplication.runningApplications(withBundleIdentifier: appBundleID).first {
            app.activate()
        } else if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appBundleID) {
            NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration())
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
