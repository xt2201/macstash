import SwiftUI
import AppKit
import MacStashCore

public struct AppearanceTab: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            GroupBox(label: Label("Dial Geometry & Styling", systemImage: "circle.circle")) {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Dial Arc Radius:")
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text("\(Int(appState.settings.dialRadiusPoints)) pt")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                        }
                        Slider(value: $appState.settings.dialRadiusPoints, in: 110...200, step: 5)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Background Glass Opacity:")
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text("\(Int(appState.settings.dialOpacity * 100))%")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                        }
                        Slider(value: $appState.settings.dialOpacity, in: 0.3...1.0, step: 0.05)
                    }

                    Divider()

                    HStack {
                        Text("Appearance Theme:")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Picker("", selection: $appState.settings.appearanceTheme) {
                            Text("Match System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 240)
                    }
                }
                .padding(8)
            }

            GroupBox(label: Label("Animation & Motion", systemImage: "sparkles")) {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Animation Speed:")
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text(String(format: "%.1fx", appState.settings.animationSpeedMultiplier))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                        }
                        Slider(value: $appState.settings.animationSpeedMultiplier, in: 0.5...2.0, step: 0.1)
                    }

                    Divider()

                    Toggle("Respect System 'Reduce Motion' Setting", isOn: $appState.settings.respectReduceMotion)
                    Text("When enabled, transitions use instant alpha fades instead of spring rotations if Reduce Motion is active in macOS Accessibility.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(8)
            }

            GroupBox(label: Label("Tactile & Audio Feedback", systemImage: "speaker.wave.2")) {
                VStack(alignment: .leading, spacing: 14) {
                    Toggle("Enable Mechanical Click Sounds", isOn: $appState.settings.isSoundEnabled)

                    if appState.settings.isSoundEnabled {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Sound Volume:")
                                    .font(.system(size: 12, weight: .medium))
                                Spacer()
                                Text("\(Int(appState.settings.soundVolume * 100))%")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                            }
                            Slider(value: $appState.settings.soundVolume, in: 0.1...1.0, step: 0.05)
                        }
                    }

                    Divider()

                    HStack {
                        Text("Trackpad Haptic Intensity:")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Picker("", selection: $appState.settings.hapticIntensity) {
                            Text("Off").tag("off")
                            Text("Subtle").tag("subtle")
                            Text("Medium").tag("medium")
                            Text("Strong").tag("strong")
                        }
                        .pickerStyle(.menu)
                        .frame(width: 140)
                    }
                }
                .padding(8)
            }
        }
    }
}
