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
            GroupBox(label: Label(appState.localized("appearance.geometryStyling"), systemImage: "circle.circle")) {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(appState.localized("appearance.dialRadius"))
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
                            Text(appState.localized("appearance.glassOpacity"))
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text("\(Int(appState.settings.dialOpacity * 100))%")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                        }
                        Slider(value: $appState.settings.dialOpacity, in: 0.3...1.0, step: 0.05)
                    }

                    Divider()

                    HStack {
                        Text(appState.localized("appearance.theme"))
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Picker("", selection: $appState.settings.appearanceTheme) {
                            Text(appState.localized("appearance.themeMatchSystem")).tag("system")
                            Text(appState.localized("appearance.themeLight")).tag("light")
                            Text(appState.localized("appearance.themeDark")).tag("dark")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 240)
                    }
                }
                .padding(8)
            }

            GroupBox(label: Label(appState.localized("appearance.animationMotion"), systemImage: "sparkles")) {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(appState.localized("appearance.animationSpeed"))
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text(String(format: "%.1fx", appState.settings.animationSpeedMultiplier))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                        }
                        Slider(value: $appState.settings.animationSpeedMultiplier, in: 0.5...2.0, step: 0.1)
                    }

                    Divider()

                    Toggle(appState.localized("appearance.reduceMotion"), isOn: $appState.settings.respectReduceMotion)
                    Text(appState.localized("appearance.reduceMotionHint"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(8)
            }

            GroupBox(label: Label(appState.localized("appearance.tactileAudio"), systemImage: "speaker.wave.2")) {
                VStack(alignment: .leading, spacing: 14) {
                    Toggle(appState.localized("appearance.soundFx"), isOn: $appState.settings.isSoundEnabled)

                    if appState.settings.isSoundEnabled {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(appState.localized("appearance.soundVolume"))
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
                        Text(appState.localized("appearance.hapticIntensity"))
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Picker("", selection: $appState.settings.hapticIntensity) {
                            Text(appState.effectiveLanguage == "vi" ? "Tắt" : "Off").tag("off")
                            Text(appState.localized("appearance.hapticLight")).tag("subtle")
                            Text(appState.localized("appearance.hapticMedium")).tag("medium")
                            Text(appState.localized("appearance.hapticStrong")).tag("strong")
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
