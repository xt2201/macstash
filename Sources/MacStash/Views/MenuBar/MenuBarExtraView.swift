import SwiftUI
import AppKit

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
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.purple)
                    .frame(width: 16)

                Text(appState.localized("menubar.focusTimer"))
                    .font(.system(size: 11, weight: .medium))

                Text(appState.formattedTimerTime)
                    .font(.system(size: 11, weight: .bold, design: .rounded))

                Spacer()

                Button(appState.isPomodoroRunning ? appState.localized("menubar.pause") : appState.localized("menubar.start")) {
                    appState.toggleAction(.timer)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
            .padding(.horizontal, 12)

            Divider()

            // Hardware Controls
            VStack(spacing: 8) {
                // Volume
                HStack(spacing: 8) {
                    Image(systemName: appState.audio.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .foregroundColor(.blue)
                        .frame(width: 16)

                    Slider(
                        value: Binding(
                            get: { appState.audio.volume },
                            set: { appState.audio.setVolume($0) }
                        ),
                        in: 0...1
                    )

                    Text("\(Int(appState.audio.volume * 100))%")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .frame(width: 32)
                }

                // Display Brightness
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
                    appState.isQuickLauncherPresented = true
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Quick App Launcher")
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
}
