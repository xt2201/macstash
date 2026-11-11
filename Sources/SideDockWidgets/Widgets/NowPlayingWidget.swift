import SwiftUI
import AppKit
import SideDockCore

public struct NowPlayingConfig: Codable, Equatable, Sendable {
    public var preferredPlayer: String
    public var showControls: Bool

    public init(preferredPlayer: String = "auto", showControls: Bool = true) {
        self.preferredPlayer = preferredPlayer
        self.showControls = showControls
    }
}

public struct NowPlayingTrackState: Equatable, Sendable {
    public let title: String
    public let artist: String
    public let album: String
    public let isPlaying: Bool
    public let duration: Double
    public let position: Double
    public let playerSource: String
    public let timestamp: Date

    public init(
        title: String = "No Media Playing",
        artist: String = "",
        album: String = "",
        isPlaying: Bool = false,
        duration: Double = 0.0,
        position: Double = 0.0,
        playerSource: String = "",
        timestamp: Date = Date()
    ) {
        self.title = title
        self.artist = artist
        self.album = album
        self.isPlaying = isPlaying
        self.duration = duration
        self.position = position
        self.playerSource = playerSource
        self.timestamp = timestamp
    }

    public var isFresh: Bool {
        Date().timeIntervalSince(timestamp) < 5.0
    }
}

public struct NowPlayingWidgetView: View {
    public let config: NowPlayingConfig
    public let size: WidgetSize
    @State private var trackState: NowPlayingTrackState = NowPlayingTrackState()
    @State private var pollTimer: Timer?

    public init(config: NowPlayingConfig = NowPlayingConfig(), size: WidgetSize = .medium) {
        self.config = config
        self.size = size
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: trackState.isPlaying ? "music.note" : "music.note.list")
                .font(.system(size: 16))
                .foregroundColor(trackState.isPlaying ? .accentColor : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(trackState.title)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)

                if !trackState.artist.isEmpty && size != .small {
                    Text(trackState.artist)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                if size == .large && trackState.duration > 0 {
                    ProgressView(value: trackState.position, total: max(1.0, trackState.duration))
                        .progressViewStyle(.linear)
                        .frame(width: 80)
                }
            }

            if config.showControls && size != .small {
                HStack(spacing: 4) {
                    Button {
                        sendMediaCommand("previous track")
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 9))
                    }
                    .buttonStyle(.plain)

                    Button {
                        sendMediaCommand("playpause")
                    } label: {
                        Image(systemName: trackState.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)

                    Button {
                        sendMediaCommand("next track")
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 9))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .onAppear {
            startPolling()
        }
        .onDisappear {
            stopPolling()
        }
    }

    private func startPolling() {
        stopPolling()
        updatePlaybackState()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task { @MainActor in
                self.updatePlaybackState()
            }
        }
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func updatePlaybackState() {
        let musicRunning = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").first != nil
        let spotifyRunning = NSRunningApplication.runningApplications(withBundleIdentifier: "com.spotify.client").first != nil

        if musicRunning {
            queryPlayer("Music")
        } else if spotifyRunning {
            queryPlayer("Spotify")
        } else {
            self.trackState = NowPlayingTrackState(title: "Not Playing", isPlaying: false, timestamp: Date())
        }
    }

    private func queryPlayer(_ appName: String) {
        let scriptSource = """
        tell application "\(appName)"
            if it is running then
                set pState to (player state as string)
                set tName to (name of current track as string)
                set tArtist to (artist of current track as string)
                set tDuration to (duration of current track as real)
                set tPos to (player position as real)
                return pState & "|||" & tName & "|||" & tArtist & "|||" & tDuration & "|||" & tPos
            else
                return "stopped"
            end if
        end tell
        """

        Task.detached(priority: .utility) {
            var error: NSDictionary?
            let result = NSAppleScript(source: scriptSource)?.executeAndReturnError(&error).stringValue
            await MainActor.run {
                if let result {
                    let parts = result.components(separatedBy: "|||")
                    if parts.count >= 3 {
                        let isPlaying = parts[0].lowercased().contains("play")
                        let title = parts[1]
                        let artist = parts[2]
                        let dur = parts.count > 3 ? (Double(parts[3]) ?? 0) : 0
                        let pos = parts.count > 4 ? (Double(parts[4]) ?? 0) : 0
                        self.trackState = NowPlayingTrackState(
                            title: title,
                            artist: artist,
                            isPlaying: isPlaying,
                            duration: dur,
                            position: pos,
                            playerSource: appName,
                            timestamp: Date()
                        )
                        return
                    }
                }
                self.trackState = NowPlayingTrackState(title: "Not Playing", isPlaying: false, timestamp: Date())
            }
        }
    }

    private func sendMediaCommand(_ command: String) {
        let appName = trackState.playerSource.isEmpty ? "Music" : trackState.playerSource
        let scriptSource = "tell application \"\(appName)\" to \(command)"
        Task.detached(priority: .userInitiated) {
            var error: NSDictionary?
            NSAppleScript(source: scriptSource)?.executeAndReturnError(&error)
            try? await Task.sleep(nanoseconds: 250_000_000)
            await MainActor.run {
                self.updatePlaybackState()
            }
        }
    }
}
