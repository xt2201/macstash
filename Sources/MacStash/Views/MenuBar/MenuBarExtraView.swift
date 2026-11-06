import SwiftUI
import AppKit
import MacStashCore

public struct MenuBarExtraView: View {
    @ObservedObject var appState: AppState
    public var onOpenSettings: () -> Void

    public init(appState: AppState, onOpenSettings: @escaping () -> Void) {
        self.appState = appState
        self.onOpenSettings = onOpenSettings
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 8) {
                StashBrandLogoView(size: 20)

                Text("MacStash")
                    .font(.system(size: 13, weight: .bold))

                Spacer()

                Toggle("", isOn: $appState.isEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)

            Divider()

            // Active App Context Banner
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.localized("menubar.activeContext"))
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(appState.profiles.currentAppName)
                        .font(.system(size: 12, weight: .medium))
                }
                Spacer()
                Text(appState.activeProfile.name)
                    .font(.system(size: 10))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.secondary.opacity(0.15)))
            }
            .padding(.horizontal, 12)

            Divider()

            // Focus Timer Quick Status
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: appState.pomodoroMode == .focus ? "brain.head.profile" : "cup.and.saucer.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(appState.pomodoroMode == .focus ? .purple : .green)

                    Text(modeTitle(for: appState.pomodoroMode))
                        .font(.system(size: 11, weight: .semibold))

                    Spacer()

                    if appState.pomodoroTotalRounds > 0 {
                        Text(String(format: appState.localized("pomodoro.roundIndicator"), min(appState.pomodoroTotalRounds, appState.pomodoroCompletedRounds + 1), appState.pomodoroTotalRounds))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Capsule().fill(Color.secondary.opacity(0.12)))
                    }
                }

                HStack(alignment: .center) {
                    Text(appState.formattedTimerTime)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(appState.isPomodoroRunning ? .primary : .secondary)

                    Spacer()

                    HStack(spacing: 4) {
                        Button(action: {
                            appState.togglePomodoro()
                        }) {
                            Image(systemName: appState.isPomodoroRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 10, weight: .bold))
                                .frame(width: 14, height: 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.mini)
                        .help(appState.isPomodoroRunning ? appState.localized("menubar.pause") : appState.localized("menubar.start"))

                        Button(action: {
                            appState.skipPomodoroMode()
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 10, weight: .bold))
                                .frame(width: 14, height: 14)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                        .help(appState.localized("menubar.skip"))

                        Button(action: {
                            appState.resetPomodoro()
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 10, weight: .bold))
                                .frame(width: 14, height: 14)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                        .help(appState.localized("menubar.reset"))
                    }
                }

                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 3)

                        Capsule()
                            .fill(appState.pomodoroMode == .focus ? Color.purple : Color.green)
                            .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(appState.pomodoroProgress))), height: 3)
                    }
                }
                .frame(height: 3)
            }
            .padding(.horizontal, 12)

            Divider()

            // Hardware Controls
            VStack(spacing: 8) {
                // Volume
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Button(action: {
                            appState.audio.toggleMute()
                        }) {
                            Image(systemName: appState.audio.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .foregroundColor(appState.audio.isMuted ? .red : .blue)
                                .frame(width: 16)
                        }
                        .buttonStyle(.plain)
                        .help(appState.audio.isMuted ? appState.localized("menubar.unmute") : appState.localized("menubar.mute"))

                        Slider(
                            value: Binding(
                                get: { appState.audio.volume },
                                set: { appState.audio.setVolume($0) }
                            ),
                            in: 0...1
                        )

                        Text(appState.audio.isMuted ? "0%" : "\(Int(appState.audio.volume * 100))%")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .frame(width: 32)
                    }

                    if !appState.audio.outputDevices.isEmpty {
                        Menu {
                            ForEach(appState.audio.outputDevices) { dev in
                                Button(action: {
                                    appState.audio.selectOutputDevice(id: dev.id)
                                }) {
                                    HStack {
                                        Text(dev.name)
                                        if dev.isDefault {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "hifispeaker.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                                Text(appState.audio.deviceName)
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 7))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .menuStyle(.borderlessButton)
                        .padding(.leading, 24)
                    }
                }

                // Display Brightness
                let connectedDisplays = appState.brightnessService.queryConnectedDisplays()
                if connectedDisplays.count <= 1 {
                    HStack(spacing: 8) {
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(.orange)
                            .frame(width: 16)

                        Slider(
                            value: Binding(
                                get: { appState.getValue(for: .brightness) },
                                set: { appState.setValue(for: .brightness, value: $0) }
                            ),
                            in: 0...1
                        )

                        Text("\(Int(appState.getValue(for: .brightness) * 100))%")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .frame(width: 32)
                    }
                } else {
                    VStack(spacing: 6) {
                        ForEach(connectedDisplays, id: \.uuid) { disp in
                            HStack(spacing: 8) {
                                Image(systemName: disp.isBuiltIn ? "laptopcomputer" : "display")
                                    .foregroundColor(.orange)
                                    .frame(width: 16)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(disp.name)
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)

                                    Slider(
                                        value: Binding(
                                            get: { appState.getValue(for: .brightness, displayID: disp.id) },
                                            set: { appState.setValue(for: .brightness, value: $0, displayID: disp.id) }
                                        ),
                                        in: 0...1
                                    )
                                }

                                Text("\(Int(appState.getValue(for: .brightness, displayID: disp.id) * 100))%")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .frame(width: 32)
                            }
                        }
                    }
                }

                // Keyboard Brightness
                if appState.keyboard.isSupported {
                    HStack(spacing: 8) {
                        Image(systemName: "keyboard.fill")
                            .foregroundColor(.teal)
                            .frame(width: 16)

                        Slider(
                            value: Binding(
                                get: { appState.keyboard.brightness },
                                set: { appState.keyboard.setBrightness($0) }
                            ),
                            in: 0...1
                        )

                        Text("\(Int(appState.keyboard.brightness * 100))%")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .frame(width: 32)
                    }
                }
            }
            .padding(.horizontal, 12)

            Divider()

            // Quick Actions
            VStack(spacing: 2) {
                Button(action: {
                    appState.updater.checkForUpdates(silent: false)
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Check for Updates...")
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.plain)

                Button(action: onOpenSettings) {
                    HStack {
                        Image(systemName: "gearshape")
                        Text(appState.localized("menubar.quickSettings"))
                        Spacer()
                        Text("⌘,")
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Quit
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack {
                    Image(systemName: "power")
                    Text(appState.localized("menubar.quit"))
                    Spacer()
                    Text("⌘Q")
                        .foregroundColor(.secondary)
                }
                .foregroundColor(.red)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 6)
        }
        .frame(width: 260)
    }

    private func modeTitle(for mode: PomodoroMode) -> String {
        switch mode {
        case .focus: return appState.localized("pomodoro.modeFocus")
        case .shortBreak: return appState.localized("pomodoro.modeShortBreak")
        case .longBreak: return appState.localized("pomodoro.modeLongBreak")
        }
    }
}
