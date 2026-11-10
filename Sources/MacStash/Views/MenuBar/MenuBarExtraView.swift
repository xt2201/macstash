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

                // Liquid Progress Bar
                GeometryReader { geo in
                    let totalW = geo.size.width
                    let fillW = max(0, min(totalW, totalW * CGFloat(appState.pomodoroProgress)))
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 3.5)

                        if fillW > 2 {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: appState.pomodoroMode == .focus
                                            ? [Color.purple, Color(red: 0.8, green: 0.4, blue: 1.0)]
                                            : [Color.green, Color(red: 0.4, green: 0.9, blue: 0.6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: fillW, height: 3.5)
                                .shadow(
                                    color: (appState.pomodoroMode == .focus ? Color.purple : Color.green).opacity(0.5),
                                    radius: 3,
                                    x: 0,
                                    y: 0
                                )
                        }
                    }
                }
                .frame(height: 3.5)
            }
            .padding(.horizontal, 12)

            Divider()

            // Hardware Controls
            VStack(spacing: 8) {
                // Volume
                VStack(spacing: 4) {
                    VolumeSliderRow(
                        audio: appState.audio,
                        localizedMute: appState.localized("menubar.mute"),
                        localizedUnmute: appState.localized("menubar.unmute")
                    )

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
                    KeyboardBrightnessSliderRow(keyboard: appState.keyboard)
                }

                // Keep Awake (Caffeine)
                KeepAwakeRow(keepAwake: appState.keepAwake)

                // Stash Shelf & Scratchpad quick access (only if enabled)
                if appState.settings.isStashShelfEnabled || appState.settings.isScratchpadEnabled {
                    HStack(spacing: 6) {
                        if appState.settings.isStashShelfEnabled {
                            Button(action: {
                                if appState.stashShelf.isShelfOpen {
                                    appState.stashShelf.closeShelf()
                                } else {
                                    appState.scratchpad.isScratchpadOpen = false
                                    appState.stashShelf.openShelf()
                                }
                            }) {
                                Label("\(appState.localized("menubar.stash")) (\(appState.stashShelf.items.count))", systemImage: "tray.2.fill")
                                    .font(.system(size: 10, weight: .medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.cyan.opacity(0.12)))
                            }
                            .buttonStyle(.plain)
                        }

                        if appState.settings.isScratchpadEnabled {
                            Button(action: {
                                if appState.scratchpad.isScratchpadOpen {
                                    appState.scratchpad.isScratchpadOpen = false
                                } else {
                                    appState.stashShelf.closeShelf()
                                    appState.scratchpad.isScratchpadOpen = true
                                }
                            }) {
                                Label(appState.localized("menubar.notes"), systemImage: "note.text")
                                    .font(.system(size: 10, weight: .medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.green.opacity(0.12)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)

            Divider()

            // Quick Actions
            VStack(spacing: 2) {
                Button(action: {
                    appState.sideDock.toggleDock()
                }) {
                    HStack {
                        Image(systemName: "dock.rectangle")
                        Text(appState.sideDock.config.isDockVisible ? appState.localized("menubar.hideDock") : appState.localized("menubar.showDock"))
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.plain)

                Button(action: {
                    appState.updater.checkForUpdates(silent: false)
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text(appState.localized("menubar.checkForUpdates"))
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
        .onAppear {
            appState.keyboard.updateBrightnessFromHardware()
            appState.audio.updateVolumeFromHardware()
        }
    }

    private func modeTitle(for mode: PomodoroMode) -> String {
        switch mode {
        case .focus: return appState.localized("pomodoro.modeFocus")
        case .shortBreak: return appState.localized("pomodoro.modeShortBreak")
        case .longBreak: return appState.localized("pomodoro.modeLongBreak")
        }
    }
}

private struct VolumeSliderRow: View {
    @ObservedObject var audio: AudioManager
    var localizedMute: String
    var localizedUnmute: String

    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                audio.toggleMute()
            }) {
                Image(systemName: audio.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .foregroundColor(audio.isMuted ? .red : .blue)
                    .frame(width: 16)
            }
            .buttonStyle(.plain)
            .help(audio.isMuted ? localizedUnmute : localizedMute)

            Slider(
                value: Binding(
                    get: { audio.volume },
                    set: { audio.setVolume($0) }
                ),
                in: 0...1
            )

            Text(audio.isMuted ? "0%" : "\(Int(audio.volume * 100))%")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .frame(width: 32)
        }
    }
}

private struct KeepAwakeRow: View {
    @ObservedObject var keepAwake: KeepAwakeManager

    private func localized(_ key: String) -> String {
        LocalizationService.shared.localized(key)
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "cup.and.saucer.fill")
                .foregroundColor(keepAwake.isActive ? .orange : .secondary)
                .frame(width: 16)

            Text(localized("menubar.keepAwake"))
                .font(.system(size: 11, weight: .medium))

            Spacer()

            Menu {
                Button(localized("menubar.keepAwakeOff")) { keepAwake.deactivate() }
                Divider()
                Button(localized("menubar.keepAwake15m")) { keepAwake.activate(minutes: 15) }
                Button(localized("menubar.keepAwake30m")) { keepAwake.activate(minutes: 30) }
                Button(localized("menubar.keepAwake1h")) { keepAwake.activate(minutes: 60) }
                Button(localized("menubar.keepAwake2h")) { keepAwake.activate(minutes: 120) }
                Button(localized("menubar.keepAwakeIndefinite")) { keepAwake.activate(minutes: -1) }
            } label: {
                Text(keepAwake.formattedRemaining)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(keepAwake.isActive ? .orange : .secondary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }
}

private struct KeyboardBrightnessSliderRow: View {
    @ObservedObject var keyboard: KeyboardBrightnessManager

    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                keyboard.setBrightness(KeyboardBrightnessPolicy.toggle(current: keyboard.brightness))
            }) {
                Image(systemName: "keyboard.fill")
                    .foregroundColor(.teal)
                    .frame(width: 16)
            }
            .buttonStyle(.plain)

            Slider(
                value: Binding(
                    get: { keyboard.brightness },
                    set: { keyboard.setBrightness($0) }
                ),
                in: 0...1
            )

            Text("\(Int(keyboard.brightness * 100))%")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .frame(width: 32)
        }
    }
}
