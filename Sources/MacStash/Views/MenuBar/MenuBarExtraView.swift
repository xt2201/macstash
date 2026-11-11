import SwiftUI
import AppKit
import MacStashCore

public struct MenuBarExtraView: View {
    @ObservedObject var appState: AppState
    public var onOpenSettings: () -> Void
    public var onOpenGuide: () -> Void

    public init(
        appState: AppState,
        onOpenSettings: @escaping () -> Void,
        onOpenGuide: @escaping () -> Void = {}
    ) {
        self.appState = appState
        self.onOpenSettings = onOpenSettings
        self.onOpenGuide = onOpenGuide
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 1. Header Strip
            headerSection

            // 2. Active Context App Card
            contextBanner

            // 3. Pomodoro Focus Card
            pomodoroCard

            // 4. Hardware Control Card (Audio, Displays, Keyboard)
            hardwareControlsCard

            // 5. Modular Quick Utilities Grid
            quickModulesGrid

            Divider()
                .opacity(0.6)

            // 6. Footer Actions
            footerActions
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(width: 296)
        .macStashTheme(appState.resolvedColorScheme)
        .onAppear {
            appState.keyboard.updateBrightnessFromHardware()
            appState.audio.updateVolumeFromHardware()
            _ = appState.connectedDisplays(forceRefresh: true)
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack(spacing: 8) {
            StashBrandLogoView(size: 22)

            VStack(alignment: .leading, spacing: 0) {
                Text("MacStash")
                    .font(.system(size: 13, weight: .bold))
                Text(appState.isEnabled ? appState.localized("settings.statusActive") : appState.localized("settings.statusPaused"))
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundColor(appState.isEnabled ? .green : .secondary)
            }

            Spacer()

            Button(action: onOpenGuide) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(appState.localized("menubar.userGuide"))

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(appState.localized("menubar.quickSettings"))

            Toggle("", isOn: $appState.isEnabled)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
        }
    }

    private var contextBanner: some View {
        HStack(spacing: 8) {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appState.profiles.currentBundleId) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: appURL.path))
                    .resizable()
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: "app.dashed")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 20, height: 20)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(appState.localized("menubar.activeContext"))
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(.secondary)
                Text(appState.profiles.currentAppName)
                    .font(.system(size: 11.5, weight: .semibold))
                    .lineLimit(1)
            }

            Spacer()

            Text(appState.activeProfile.name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.accentColor.opacity(0.14)))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.045))
        )
    }

    private var pomodoroCard: some View {
        let modeColor: Color = appState.pomodoroMode == .focus ? .purple : .green

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: appState.pomodoroMode == .focus ? "brain.head.profile" : "cup.and.saucer.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(modeColor)

                Text(modeTitle(for: appState.pomodoroMode))
                    .font(.system(size: 11, weight: .semibold))

                Spacer()

                if appState.pomodoroTotalRounds > 0 {
                    Text(String(format: appState.localized("pomodoro.roundIndicator"), min(appState.pomodoroTotalRounds, appState.pomodoroCompletedRounds + 1), appState.pomodoroTotalRounds))
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.primary.opacity(0.06)))
                }
            }

            HStack(alignment: .center) {
                Text(appState.formattedTimerTime)
                    .font(.system(size: 21, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundColor(appState.isPomodoroRunning ? .primary : .secondary)

                Spacer()

                HStack(spacing: 5) {
                    Button(action: { appState.togglePomodoro() }) {
                        Image(systemName: appState.isPomodoroRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 10, weight: .bold))
                            .frame(width: 22, height: 20)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(modeColor)
                    .controlSize(.small)
                    .help(appState.isPomodoroRunning ? appState.localized("menubar.pause") : appState.localized("menubar.start"))

                    Button(action: { appState.skipPomodoroMode() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 9.5, weight: .bold))
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help(appState.localized("menubar.skip"))

                    Button(action: { appState.resetPomodoro() }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 9.5, weight: .bold))
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help(appState.localized("menubar.reset"))
                }
            }

            GeometryReader { geo in
                let totalW = geo.size.width
                let fillW = max(0, min(totalW, totalW * CGFloat(appState.pomodoroProgress)))
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.09))
                        .frame(height: 4)

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
                            .frame(width: fillW, height: 4)
                    }
                }
            }
            .frame(height: 4)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(modeColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(modeColor.opacity(0.20), lineWidth: 0.8)
        )
    }

    private var hardwareControlsCard: some View {
        let displays = appState.connectedDisplays()

        return VStack(spacing: 9) {
            // Audio Volume & Output Routing
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
                        HStack(spacing: 5) {
                            Image(systemName: "hifispeaker.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            Text(appState.audio.deviceName)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.045)))
                    }
                    .menuStyle(.borderlessButton)
                    .padding(.leading, 22)
                }
            }

            Divider().opacity(0.5)

            // Display Brightness (cached displays)
            if displays.count <= 1 {
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

                    Text("\(Int(round(appState.getValue(for: .brightness) * 100)))%")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .monospacedDigit()
                        .frame(width: 34, alignment: .trailing)
                }
            } else {
                VStack(spacing: 7) {
                    ForEach(displays, id: \.uuid) { disp in
                        HStack(spacing: 8) {
                            Image(systemName: disp.isBuiltIn ? "laptopcomputer" : "display")
                                .foregroundColor(.orange)
                                .frame(width: 16)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(disp.name)
                                    .font(.system(size: 9.5, weight: .medium))
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

                            Text("\(Int(round(appState.getValue(for: .brightness, displayID: disp.id) * 100)))%")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .monospacedDigit()
                                .frame(width: 34, alignment: .trailing)
                        }
                    }
                }
            }

            // Keyboard Backlight
            if appState.keyboard.isSupported {
                Divider().opacity(0.5)
                KeyboardBrightnessSliderRow(keyboard: appState.keyboard)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.primary.opacity(0.045))
        )
    }

    private var quickModulesGrid: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                quickToggleTile(
                    title: appState.localized("menubar.cornerDials"),
                    icon: "circle.dashed",
                    tint: .blue,
                    isActive: appState.isCornerDialsEnabled
                ) {
                    appState.isCornerDialsEnabled.toggle()
                }

                quickToggleTile(
                    title: appState.localized("menubar.edgeSlider"),
                    icon: "slider.vertical.3",
                    tint: .indigo,
                    isActive: appState.isEdgeSlidersEnabled
                ) {
                    appState.isEdgeSlidersEnabled.toggle()
                }
            }

            HStack(spacing: 6) {
                quickToggleTile(
                    title: appState.localized("general.secondDock"),
                    icon: "dock.rectangle",
                    tint: .teal,
                    isActive: appState.sideDock.config.isDockVisible
                ) {
                    appState.sideDock.toggleDock()
                }

                KeepAwakeTile(keepAwake: appState.keepAwake)
            }

            if appState.settings.isStashShelfEnabled || appState.settings.isScratchpadEnabled {
                HStack(spacing: 6) {
                    if appState.settings.isStashShelfEnabled {
                        quickToggleTile(
                            title: "\(appState.localized("menubar.stash")) (\(appState.stashShelf.items.count))",
                            icon: "tray.2.fill",
                            tint: .cyan,
                            isActive: appState.stashShelf.isShelfOpen
                        ) {
                            if appState.stashShelf.isShelfOpen {
                                appState.stashShelf.closeShelf()
                            } else {
                                appState.scratchpad.isScratchpadOpen = false
                                appState.stashShelf.openShelf()
                            }
                        }
                    }

                    if appState.settings.isScratchpadEnabled {
                        quickToggleTile(
                            title: appState.localized("menubar.notes"),
                            icon: "note.text",
                            tint: .green,
                            isActive: appState.scratchpad.isScratchpadOpen
                        ) {
                            if appState.scratchpad.isScratchpadOpen {
                                appState.scratchpad.isScratchpadOpen = false
                            } else {
                                appState.stashShelf.closeShelf()
                                appState.scratchpad.isScratchpadOpen = true
                            }
                        }
                    }
                }
            }
        }
    }

    private func quickToggleTile(
        title: String,
        icon: String,
        tint: Color,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isActive ? tint : .secondary)
                    .frame(width: 16)

                Text(title)
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(isActive ? .primary : .secondary)
                    .lineLimit(1)

                Spacer(minLength: 2)

                Circle()
                    .fill(isActive ? tint : Color.secondary.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isActive ? tint.opacity(0.14) : Color.primary.opacity(0.045))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(isActive ? tint.opacity(0.35) : Color.clear, lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }

    private var footerActions: some View {
        VStack(spacing: 2) {
            MenuBarActionRow(
                icon: "arrow.triangle.2.circlepath",
                title: appState.localized("menubar.checkForUpdates"),
                shortcut: nil,
                tint: .primary
            ) {
                appState.updater.checkForUpdates(silent: false)
            }

            MenuBarActionRow(
                icon: "book",
                title: appState.localized("menubar.userGuide"),
                shortcut: "⌘?",
                tint: .primary,
                action: onOpenGuide
            )

            MenuBarActionRow(
                icon: "gearshape",
                title: appState.localized("menubar.quickSettings"),
                shortcut: "⌘,",
                tint: .primary,
                action: onOpenSettings
            )

            Divider().opacity(0.5).padding(.vertical, 2)

            MenuBarActionRow(
                icon: "power",
                title: appState.localized("menubar.quit"),
                shortcut: "⌘Q",
                tint: .red
            ) {
                NSApplication.shared.terminate(nil)
            }
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

private struct MenuBarActionRow: View {
    let icon: String
    let title: String
    let shortcut: String?
    let tint: Color
    let action: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(tint)
                    .frame(width: 16)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(tint)

                Spacer()

                if let shortcut {
                    Text(shortcut)
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5.5)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isHovered ? Color.primary.opacity(0.08) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
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

            Text(audio.isMuted ? "0%" : "\(Int(round(audio.volume * 100)))%")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .frame(width: 34, alignment: .trailing)
        }
    }
}

private struct KeepAwakeTile: View {
    @ObservedObject var keepAwake: KeepAwakeManager

    private func localized(_ key: String) -> String {
        LocalizationService.shared.localized(key)
    }

    var body: some View {
        Menu {
            Button(localized("menubar.keepAwakeOff")) { keepAwake.deactivate() }
            Divider()
            Button(localized("menubar.keepAwake15m")) { keepAwake.activate(minutes: 15) }
            Button(localized("menubar.keepAwake30m")) { keepAwake.activate(minutes: 30) }
            Button(localized("menubar.keepAwake1h")) { keepAwake.activate(minutes: 60) }
            Button(localized("menubar.keepAwake2h")) { keepAwake.activate(minutes: 120) }
            Button(localized("menubar.keepAwakeIndefinite")) { keepAwake.activate(minutes: -1) }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(keepAwake.isActive ? .orange : .secondary)

                Text(keepAwake.isActive ? keepAwake.formattedRemaining : localized("menubar.keepAwake"))
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(keepAwake.isActive ? .primary : .secondary)
                    .lineLimit(1)

                Spacer(minLength: 2)

                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(keepAwake.isActive ? Color.orange.opacity(0.14) : Color.primary.opacity(0.045))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(keepAwake.isActive ? Color.orange.opacity(0.35) : Color.clear, lineWidth: 0.8)
            )
        }
        .menuStyle(.borderlessButton)
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

            Text("\(Int(round(keyboard.brightness * 100)))%")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .frame(width: 34, alignment: .trailing)
        }
    }
}
