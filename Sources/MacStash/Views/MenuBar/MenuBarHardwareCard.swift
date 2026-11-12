import SwiftUI
import AppKit
import MacStashCore
import MacStashDesignSystem

public struct MenuBarHardwareCard: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        let displays = appState.connectedDisplays()

        VStack(spacing: 9) {
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

            // Display Brightness (single or scrollable multi-monitor list)
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
                ScrollView(.vertical, showsIndicators: displays.count > 3) {
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
                .frame(maxHeight: 165)
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
