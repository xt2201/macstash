import SwiftUI
import AppKit
import MacStashCore

public struct AppearanceTab: View {
    @ObservedObject var appState: AppState
    @State private var previewCorner: CornerPosition = .bottomRight
    @State private var previewAction: ControlAction = .volume
    @State private var previewValue: Double = 0.68
    @State private var isLightBackdrop: Bool = false
    @State private var lastDetentStep: Int = 13

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Section 1: Interactive Liquid Glass Studio
            SettingsCard(
                title: appState.localized("appearance.studioTitle"),
                systemImage: "sparkles",
                accentColor: .purple,
                trailingText: "\(Int(round(previewValue * 100)))%"
            ) {
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Text(appState.localized("appearance.previewCorner"))
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(.secondary)

                        Picker("", selection: $previewCorner) {
                            Text("TL").tag(CornerPosition.topLeft)
                            Text("TR").tag(CornerPosition.topRight)
                            Text("BL").tag(CornerPosition.bottomLeft)
                            Text("BR").tag(CornerPosition.bottomRight)
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .frame(width: 150)

                        Picker("", selection: $previewAction) {
                            Text(appState.localized("palette.volume")).tag(ControlAction.volume)
                            Text(appState.localized("palette.brightness")).tag(ControlAction.brightness)
                            Text(appState.localized("corners.action.backlight")).tag(ControlAction.keyboardBrightness)
                            Text(appState.localized("palette.timer")).tag(ControlAction.timer)
                            Text(appState.localized("corners.action.keepAwake")).tag(ControlAction.keepAwake)
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(minWidth: 120, maxWidth: 160)

                        Spacer()
                    }

                    HStack(spacing: 10) {
                        Picker("", selection: $isLightBackdrop) {
                            Text(appState.localized("appearance.wallpaperDark")).tag(false)
                            Text(appState.localized("appearance.wallpaperLight")).tag(true)
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 240)

                        Spacer()
                    }
                }

                previewStageView
            }

            // Section 2: Dial Geometry & Styling
            SettingsCard(
                title: appState.localized("appearance.geometryStyling"),
                systemImage: "circle.dashed.inset.filled",
                accentColor: .blue
            ) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(appState.localized("appearance.dialRadius"))
                            .font(.system(size: 12.5, weight: .medium))
                        Spacer()
                        Text("\(Int(appState.settings.dialRadiusPoints)) pt")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $appState.settings.dialRadiusPoints, in: 100...250, step: 5)
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(appState.localized("appearance.glassOpacity"))
                            .font(.system(size: 12.5, weight: .medium))
                        Spacer()
                        Text("\(Int(round(appState.settings.dialOpacity * 100)))%")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $appState.settings.dialOpacity, in: 0.2...1.0, step: 0.05)
                    Text(appState.localized("appearance.dialScaleHint"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text(appState.localized("appearance.theme"))
                        .font(.system(size: 12.5, weight: .medium))

                    Picker("", selection: $appState.settings.appearanceTheme) {
                        Text(appState.localized("appearance.themeMatchSystem")).tag("system")
                        Text(appState.localized("appearance.themeLight")).tag("light")
                        Text(appState.localized("appearance.themeDark")).tag("dark")
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
            }

            // Section 3: Animation & Motion
            SettingsCard(
                title: appState.localized("appearance.animationMotion"),
                systemImage: "wind",
                accentColor: .cyan
            ) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(appState.localized("appearance.animationSpeed"))
                            .font(.system(size: 12.5, weight: .medium))
                        Spacer()
                        Text(String(format: "%.1fx", appState.settings.animationSpeedMultiplier))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $appState.settings.animationSpeedMultiplier, in: 0.5...2.0, step: 0.1)
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Toggle(appState.localized("appearance.reduceMotion"), isOn: $appState.settings.respectReduceMotion)
                        .font(.system(size: 12.5, weight: .medium))
                    Text(appState.localized("appearance.reduceMotionHint"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            // Section 4: Tactile & Audio Feedback
            SettingsCard(
                title: appState.localized("appearance.tactileAudio"),
                systemImage: "waveform",
                accentColor: .orange
            ) {
                Toggle(appState.localized("appearance.soundFx"), isOn: $appState.isSoundEnabled)
                    .font(.system(size: 12.5, weight: .medium))

                if appState.isSoundEnabled {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(appState.localized("appearance.soundVolume"))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(round(appState.soundVolume * 100)))%")
                                .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                                .monospacedDigit()
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(
                            get: { Double(appState.soundVolume) },
                            set: { appState.soundVolume = Float($0) }
                        ), in: 0.0...1.0, step: 0.05)
                    }
                    .padding(.leading, 18)
                }

                Divider()

                Toggle(appState.localized("appearance.trackpadHaptics"), isOn: $appState.settings.hapticFeedbackEnabled)
                    .font(.system(size: 12.5, weight: .medium))

                if appState.settings.hapticFeedbackEnabled {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(appState.localized("appearance.hapticIntensity"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Picker("", selection: $appState.settings.hapticIntensity) {
                            Text(appState.localized("appearance.hapticLight")).tag("light")
                            Text(appState.localized("appearance.hapticMedium")).tag("medium")
                            Text(appState.localized("appearance.hapticStrong")).tag("strong")
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                    .padding(.leading, 18)
                }

                Divider()

                HStack {
                    Spacer()
                    Button {
                        appState.sound.playAccent(enabled: appState.isSoundEnabled)
                        appState.haptics.performBoundaryClick(intensity: appState.effectiveHapticIntensity)
                    } label: {
                        Label(appState.localized("appearance.testFeedback"), systemImage: "hand.tap.fill")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }

    // MARK: - Live Interactive Preview Stage

    private var previewStageView: some View {
        let previewDialSize = min(210.0, appState.settings.dialRadiusPoints)
        let tint = previewAction.accentColors.first ?? .accentColor
        let stageHeight = max(210.0, previewDialSize + 44.0)
        let metrics = CornerDialMetrics(dialSize: previewDialSize)
        let geom = RadialDialGeometry(
            corner: previewCorner,
            size: CGSize(width: previewDialSize, height: previewDialSize),
            outerRadius: metrics.tickOuterRadius,
            innerRadius: metrics.badgeOuterRadius
        )

        return ZStack(alignment: stageAlignment(for: previewCorner)) {
            // Wallpaper simulation backdrop
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isLightBackdrop
                            ? [Color(red: 0.87, green: 0.92, blue: 0.98), Color(red: 0.72, green: 0.83, blue: 0.96), Color(red: 0.89, green: 0.84, blue: 0.96)]
                            : [Color(red: 0.06, green: 0.08, blue: 0.14), Color(red: 0.11, green: 0.15, blue: 0.25), Color(red: 0.16, green: 0.11, blue: 0.24)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Decorative desktop ambient mesh orbs for glass refraction test
            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(tint.opacity(isLightBackdrop ? 0.25 : 0.30))
                        .frame(width: 140, height: 140)
                        .blur(radius: 30)
                        .position(x: geo.size.width * 0.32, y: geo.size.height * 0.45)

                    Circle()
                        .fill(Color.indigo.opacity(isLightBackdrop ? 0.18 : 0.28))
                        .frame(width: 130, height: 130)
                        .blur(radius: 28)
                        .position(x: geo.size.width * 0.72, y: geo.size.height * 0.55)
                }
            }

            // Interactive Dial Under Test
            ZStack {
                QuarterCircleGlassBackdrop(
                    corner: previewCorner,
                    dialSize: previewDialSize,
                    tint: tint
                )
                .opacity(appState.settings.dialOpacity)

                DialTicksView(
                    geometry: geom,
                    value: previewValue,
                    accentColor: tint
                )

                DialArcShape(
                    geometry: geom,
                    value: previewValue,
                    gradientColors: previewAction.accentColors
                )

                CenterActionBadge(
                    action: previewAction,
                    corner: previewCorner,
                    value: previewValue,
                    dialSize: previewDialSize,
                    isExpanded: true,
                    formattedTimer: String(format: "%02d:00", max(1, Int(round(previewValue * 60)))),
                    isPomodoroRunning: false,
                    isPomodoroPaused: false,
                    pomodoroMode: .focus,
                    completedRounds: 1,
                    totalRounds: 4,
                    isMuted: previewAction == .volume && previewValue <= 0.01,
                    isKeyboardSupported: true,
                    formattedKeepAwake: "30m",
                    stashItemCount: 3,
                    tint: tint,
                    gradientColors: previewAction.accentColors
                )
            }
            .frame(width: previewDialSize, height: previewDialSize)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let newVal = geom.value(for: value.location)
                        previewValue = max(0.0, min(1.0, newVal))
                        let step = Int(round(previewValue * 20))
                        if step != lastDetentStep {
                            lastDetentStep = step
                            appState.haptics.performDetentTick(intensity: appState.effectiveHapticIntensity)
                        }
                    }
            )
            .macStashTheme(isLightBackdrop ? .light : .dark)
        }
        .frame(height: stageHeight)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.14), lineWidth: 1.0)
        )
    }

    private func stageAlignment(for corner: CornerPosition) -> Alignment {
        switch corner {
        case .topLeft: return .topLeading
        case .topRight: return .topTrailing
        case .bottomLeft: return .bottomLeading
        case .bottomRight: return .bottomTrailing
        }
    }
}
