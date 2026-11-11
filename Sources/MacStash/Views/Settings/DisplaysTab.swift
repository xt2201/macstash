import SwiftUI
import AppKit
import MacStashCore

public struct DisplaysTab: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var appState: AppState
    @State private var displays: [DisplayInfo] = []
    @State private var brightnessValues: [CGDirectDisplayID: Double] = [:]

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Section 1: Connected Displays
            SettingsCard(
                title: appState.localized("displays.connectedDisplays"),
                systemImage: "display.2",
                accentColor: .orange,
                trailingText: displays.isEmpty ? nil : "\(displays.count)"
            ) {
                HStack {
                    Spacer()
                    Button {
                        refreshDisplays(force: true)
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }

                if displays.isEmpty {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text(appState.localized("displays.scanning"))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                } else {
                    VStack(spacing: 12) {
                        ForEach(displays) { display in
                            displayCard(for: display)
                        }
                    }
                }
            }

            // Section 2: Precision & Safety Clamps
            SettingsCard(
                title: appState.localized("displays.precision"),
                systemImage: "slider.horizontal.3",
                accentColor: .blue
            ) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(appState.localized("displays.stepSize"))
                        .font(.system(size: 12.5, weight: .medium))

                    Picker("", selection: $appState.settings.brightnessStepFraction) {
                        Text(appState.localized("displays.stepUltraFine")).tag(Float(0.01))
                        Text(appState.localized("displays.stepBalanced")).tag(Float(0.05))
                        Text(appState.localized("displays.stepCoarse")).tag(Float(0.10))
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(appState.localized("displays.minClamp"))
                            .font(.system(size: 12.5, weight: .medium))
                        Spacer()
                        Text("\(Int(round(appState.settings.minBrightnessClamp * 100)))%")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                    }
                    Slider(value: Binding(
                        get: { Double(appState.settings.minBrightnessClamp) },
                        set: { newVal in
                            let clamped = min(Float(newVal), appState.settings.maxBrightnessClamp - 0.05)
                            appState.settings.minBrightnessClamp = max(0.0, clamped)
                        }
                    ), in: 0.0...0.5, step: 0.05)
                    Text(appState.localized("displays.minClampHint"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(appState.localized("displays.maxClamp"))
                            .font(.system(size: 12.5, weight: .medium))
                        Spacer()
                        Text("\(Int(round(appState.settings.maxBrightnessClamp * 100)))%")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                    }
                    Slider(value: Binding(
                        get: { Double(appState.settings.maxBrightnessClamp) },
                        set: { newVal in
                            let clamped = max(Float(newVal), appState.settings.minBrightnessClamp + 0.05)
                            appState.settings.maxBrightnessClamp = min(1.0, clamped)
                        }
                    ), in: 0.5...1.0, step: 0.05)
                    Text(appState.localized("displays.clampRangeHint"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            refreshDisplays(force: false)
        }
    }

    // MARK: - Subviews

    private func displayCard(for display: DisplayInfo) -> some View {
        let profile = appState.brightnessService.profile(for: display.uuid)
            ?? appState.settings.displayBrightnessProfiles[display.uuid]
            ?? DisplayBrightnessProfile(
                displayUUID: display.uuid,
                displayName: display.name,
                preferredMethod: display.isBuiltIn ? .builtIn : .auto,
                actualMethod: display.isBuiltIn ? .builtIn : .ddc,
                isBuiltIn: display.isBuiltIn
            )

        let resolved = BrightnessPolicy.resolveActualMethod(
            preferred: profile.preferredMethod,
            isBuiltIn: display.isBuiltIn,
            isDDCSupported: profile.actualMethod == .ddc || !display.isBuiltIn,
            language: appState.effectiveLanguage
        )

        let level = brightnessValues[display.id] ?? appState.getValue(for: .brightness, displayID: display.id)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: display.isBuiltIn ? "laptopcomputer" : "display")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.orange)
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.orange.opacity(0.14))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(display.name)
                        .font(.system(size: 13, weight: .semibold))
                    Text(display.isBuiltIn ? appState.localized("displays.builtInDisplay") : appState.localized("displays.externalDisplay"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                StatusBadgePill(
                    text: resolved.method.localizedDisplayName(using: appState.effectiveLanguage),
                    color: resolved.method == .software ? .orange : .green
                )
            }

            if !display.isBuiltIn {
                HStack {
                    Text(appState.localized("displays.method"))
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Picker("", selection: Binding(
                        get: { profile.preferredMethod },
                        set: { newMethod in
                            var updated = profile
                            updated.preferredMethod = newMethod
                            updated.actualMethod = BrightnessPolicy.resolveActualMethod(
                                preferred: newMethod,
                                isBuiltIn: display.isBuiltIn,
                                isDDCSupported: true,
                                language: appState.effectiveLanguage
                            ).method
                            appState.updateDisplayProfile(updated)
                        }
                    )) {
                        Text(appState.localized("displays.methodAuto")).tag(BrightnessMethod.auto)
                        Text(appState.localized("displays.methodDDC")).tag(BrightnessMethod.ddc)
                        Text(appState.localized("displays.methodSoftware")).tag(BrightnessMethod.software)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 195)
                }
            }

            Text(resolved.reason)
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            // Live Brightness Test Slider
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(appState.localized("displays.brightnessTest"))
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Text("\(Int(round(level * 100)))%")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .monospacedDigit()
                        .foregroundColor(.orange)
                }

                Slider(value: Binding(
                    get: { brightnessValues[display.id] ?? level },
                    set: { newVal in
                        brightnessValues[display.id] = newVal
                        appState.setValue(for: .brightness, value: newVal, displayID: display.id)
                    }
                ), in: 0.05...1.0)

                // Quick Brightness Presets
                HStack(spacing: 6) {
                    Text(appState.localized("displays.presets"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    Spacer()

                    ForEach([0.25, 0.50, 0.75, 1.0], id: \.self) { preset in
                        Button("\(Int(preset * 100))%") {
                            brightnessValues[display.id] = preset
                            appState.setValue(for: .brightness, value: preset, displayID: display.id)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.035) : Color.black.opacity(0.025))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.07), lineWidth: 0.7)
        )
    }

    private func refreshDisplays(force: Bool) {
        let queried = appState.connectedDisplays(forceRefresh: force)
        displays = queried
        for d in queried {
            brightnessValues[d.id] = appState.getValue(for: .brightness, displayID: d.id)
        }
    }
}
