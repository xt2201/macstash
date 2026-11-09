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
            // Interactive Liquid Glass Studio Stage (Real-time Live Preview)
            LiquidGlassPreviewStage(appState: appState)

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

// MARK: - Interactive Liquid Glass Preview Stage

private struct LiquidGlassPreviewStage: View {
    @ObservedObject var appState: AppState
    @State private var previewValue: Double = 0.65
    @State private var previewAction: ControlAction = .volume

    var body: some View {
        GroupBox(label: Label(appState.effectiveLanguage == "vi" ? "Thử nghiệm Liquid Glass tương tác" : "Interactive Liquid Glass Studio", systemImage: "sparkles")) {
            VStack(spacing: 12) {
                // Interactive stage canvas with dark backdrop and simulated screen corner
                ZStack(alignment: .bottomTrailing) {
                    // Simulated desktop wallpaper preview
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.14, blue: 0.22),
                            Color(red: 0.04, green: 0.06, blue: 0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 190)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.25), Color.white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )

                    // Interactive mini dial positioned at the bottom right corner of the stage
                    let stageDialSize: CGFloat = min(155, appState.settings.dialRadiusPoints)
                    let geom = RadialDialGeometry(
                        corner: .bottomRight,
                        size: CGSize(width: stageDialSize, height: stageDialSize),
                        outerRadius: stageDialSize - 15,
                        innerRadius: 50
                    )

                    ZStack {
                        QuarterCircleGlassBackdrop(
                            corner: .bottomRight,
                            dialSize: stageDialSize,
                            tint: previewAction.accentColors.first ?? .clear
                        )
                        .opacity(appState.settings.dialOpacity)

                        DialTicksView(
                            geometry: geom,
                            value: previewValue,
                            accentColor: previewAction.accentColors.first ?? .accentColor
                        )

                        DialArcShape(
                            geometry: geom,
                            value: previewValue,
                            gradientColors: previewAction.accentColors
                        )

                        // Center badge (tap to toggle mute/play)
                        Button(action: {
                            SoundEffectManager.shared.playAccent()
                            HapticManager.shared.performDetentTick()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                previewValue = previewValue > 0.05 ? 0.0 : 0.75
                            }
                        }) {
                            CenterActionBadge(
                                action: previewAction,
                                corner: .bottomRight,
                                value: previewValue,
                                dialSize: stageDialSize,
                                isExpanded: true,
                                formattedTimer: "25:00",
                                isPomodoroRunning: false,
                                isPomodoroPaused: false,
                                pomodoroMode: .focus,
                                completedRounds: 1,
                                totalRounds: 4,
                                isMuted: previewValue <= 0.01,
                                isKeyboardSupported: true,
                                formattedKeepAwake: "30m",
                                stashItemCount: 3,
                                tint: previewAction.accentColors.first ?? .clear
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(width: stageDialSize, height: stageDialSize)
                    .padding([.bottom, .trailing], 8)
                }

                // Controls beneath the stage to test actions & scrub value
                HStack(spacing: 12) {
                    Picker("", selection: $previewAction) {
                        Text(ControlAction.volume.displayName).tag(ControlAction.volume)
                        Text(ControlAction.brightness.displayName).tag(ControlAction.brightness)
                        Text(ControlAction.timer.displayName).tag(ControlAction.timer)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 240)

                    Spacer()

                    Slider(value: $previewValue, in: 0...1)
                        .frame(width: 120)
                }
                .padding(.horizontal, 4)
            }
            .padding(8)
        }
    }
}
