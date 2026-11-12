import SwiftUI
import AppKit
import MacStashCore
import MacStashDesignSystem

public struct DialSatelliteCluster: View {
    @ObservedObject var appState: AppState
    public let action: ControlAction
    public let geometry: RadialDialGeometry
    public let satelliteRadius: CGFloat
    public let satSize: CGFloat
    public let displayID: CGDirectDisplayID

    @State private var hoveredKey: String? = nil

    public init(
        appState: AppState,
        action: ControlAction,
        geometry: RadialDialGeometry,
        satelliteRadius: CGFloat,
        satSize: CGFloat,
        displayID: CGDirectDisplayID = 0
    ) {
        self.appState = appState
        self.action = action
        self.geometry = geometry
        self.satelliteRadius = satelliteRadius
        self.satSize = satSize
        self.displayID = displayID
    }

    private var reduceMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    public var body: some View {
        Group {
            if action == .timer {
                timerSatellites
            } else if action == .volume && appState.nowPlaying.hasMedia {
                volumeMediaSatellites
            } else if action == .mediaPlayback {
                mediaPlaybackSatellites
            } else if action == .keepAwake {
                keepAwakeSatellites
            } else if action == .stashShelf {
                stashShelfSatellites
            } else if action == .scratchpad {
                scratchpadSatellites
            }
        }
    }

    // MARK: - Timer Satellites

    private var timerSatellites: some View {
        Group {
            satelliteButton(
                key: "timer_reset",
                icon: "arrow.counterclockwise",
                iconSize: 9,
                tint: .purple,
                label: appState.localized("menubar.reset"),
                normalizedAngle: 0.14
            ) {
                appState.resetPomodoro()
            }

            satelliteButton(
                key: "timer_skip",
                icon: "forward.fill",
                iconSize: 8,
                tint: appState.pomodoroMode == .focus ? .purple : .green,
                label: appState.localized("menubar.skip"),
                normalizedAngle: 0.86
            ) {
                appState.skipPomodoroMode()
            }
        }
    }

    // MARK: - Volume + Media Satellites

    private var volumeMediaSatellites: some View {
        Group {
            satelliteButton(
                key: "vol_rwd",
                icon: "gobackward.10",
                iconSize: 9.5,
                tint: appState.nowPlaying.artworkTint,
                label: appState.localized("corners.media.seekBackward"),
                normalizedAngle: 0.16
            ) {
                appState.nowPlaying.skipBackward(seconds: 10)
            }

            satelliteButton(
                key: "vol_playpause",
                icon: appState.nowPlaying.isPlaying ? "pause.fill" : "play.fill",
                iconSize: 9,
                tint: appState.nowPlaying.isPlaying ? appState.nowPlaying.artworkTint : .clear,
                label: appState.nowPlaying.isPlaying ? appState.localized("corners.media.pause") : appState.localized("corners.media.play"),
                normalizedAngle: 0.50
            ) {
                appState.nowPlaying.togglePlayPause()
            }

            satelliteButton(
                key: "vol_fwd",
                icon: "goforward.10",
                iconSize: 9.5,
                tint: appState.nowPlaying.artworkTint,
                label: appState.localized("corners.media.seekForward"),
                normalizedAngle: 0.84
            ) {
                appState.nowPlaying.skipForward(seconds: 10)
            }
        }
    }

    // MARK: - Dedicated Media Playback Satellites

    private var mediaPlaybackSatellites: some View {
        Group {
            satelliteButton(
                key: "media_prev",
                icon: "backward.fill",
                iconSize: 8.5,
                tint: appState.nowPlaying.artworkTint,
                label: appState.localized("corners.media.previous"),
                normalizedAngle: 0.14
            ) {
                appState.nowPlaying.previousTrack()
            }

            satelliteButton(
                key: "media_rwd",
                icon: "gobackward.10",
                iconSize: 9.5,
                tint: appState.nowPlaying.artworkTint,
                label: appState.localized("corners.media.seekBackward"),
                normalizedAngle: 0.38
            ) {
                appState.nowPlaying.skipBackward(seconds: 10)
            }

            satelliteButton(
                key: "media_fwd",
                icon: "goforward.10",
                iconSize: 9.5,
                tint: appState.nowPlaying.artworkTint,
                label: appState.localized("corners.media.seekForward"),
                normalizedAngle: 0.62
            ) {
                appState.nowPlaying.skipForward(seconds: 10)
            }

            satelliteButton(
                key: "media_next",
                icon: "forward.fill",
                iconSize: 8.5,
                tint: appState.nowPlaying.artworkTint,
                label: appState.localized("corners.media.next"),
                normalizedAngle: 0.86
            ) {
                appState.nowPlaying.nextTrack()
            }
        }
    }

    // MARK: - Keep Awake Satellites

    private var keepAwakeSatellites: some View {
        Group {
            satelliteButton(
                key: "awake_inf",
                icon: "infinity",
                iconSize: 9,
                tint: .orange,
                label: appState.localized("general.keepAwakeIndefinite"),
                normalizedAngle: 0.14
            ) {
                appState.keepAwake.activate(minutes: -1)
            }

            satelliteButton(
                key: "awake_off",
                icon: "power",
                iconSize: 9,
                tint: .clear,
                label: appState.localized("general.turnOffKeepAwake"),
                normalizedAngle: 0.86
            ) {
                appState.keepAwake.deactivate()
            }
        }
    }

    // MARK: - Stash Shelf Satellites

    private var stashShelfSatellites: some View {
        Group {
            satelliteButton(
                key: "shelf_open",
                icon: "tray.full.fill",
                iconSize: 9,
                tint: .cyan,
                label: appState.localized("corners.action.openShelf"),
                normalizedAngle: 0.14
            ) {
                appState.toggleAction(.stashShelf, displayID: displayID)
            }

            satelliteButton(
                key: "shelf_clear",
                icon: "trash",
                iconSize: 9,
                tint: .clear,
                label: appState.localized("general.clearAll"),
                normalizedAngle: 0.86
            ) {
                appState.stashShelf.clearAll()
            }
        }
    }

    // MARK: - Scratchpad Satellites

    private var scratchpadSatellites: some View {
        Group {
            satelliteButton(
                key: "pad_open",
                icon: "note.text.badge.plus",
                iconSize: 9,
                tint: .green,
                label: appState.localized("corners.action.openScratchpad"),
                normalizedAngle: 0.14
            ) {
                appState.toggleAction(.scratchpad, displayID: displayID)
            }

            satelliteButton(
                key: "pad_copy",
                icon: "doc.on.doc",
                iconSize: 9,
                tint: .clear,
                label: appState.localized("scratchpad.copyAll"),
                normalizedAngle: 0.86
            ) {
                appState.scratchpad.copyAll()
            }
        }
    }

    // MARK: - Shared Satellite Button Builder

    private func satelliteButton(
        key: String,
        icon: String,
        iconSize: CGFloat,
        tint: Color,
        label: String,
        normalizedAngle: Double,
        action: @escaping () -> Void
    ) -> some View {
        let pt = geometry.point(radius: satelliteRadius, angleDegrees: geometry.angle(for: normalizedAngle))
        let isHovered = hoveredKey == key

        return Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .bold))
                .foregroundColor(tint == .clear ? .secondary : (isHovered ? .primary : tint))
                .frame(width: satSize, height: satSize)
                .contentShape(Circle())
                .circularLiquidGlass(
                    tint: tint,
                    specularIntensity: 1.0,
                    causticOpacity: 0.25,
                    isHighlighted: isHovered
                )
                .scaleEffect(reduceMotion ? 1.0 : (isHovered ? 1.15 : 1.0))
                .animation(reduceMotion ? nil : .spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
        .onHover { isHovered in
            if isHovered {
                hoveredKey = key
            } else if hoveredKey == key {
                hoveredKey = nil
            }
        }
        .position(x: pt.x, y: pt.y)
    }
}
