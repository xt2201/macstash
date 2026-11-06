import SwiftUI
import AppKit
import MacStashCore

public struct DisplaysTab: View {
    @ObservedObject var appState: AppState
    @State private var displays: [DisplayInfo] = []

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            GroupBox(label: Label(appState.localized("displays.connectedDisplays"), systemImage: "display.2")) {
                VStack(alignment: .leading, spacing: 16) {
                    if displays.isEmpty {
                        Text(appState.localized("displays.scanning"))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(displays, id: \.uuid) { display in
                            displayRow(display: display)
                            if display.uuid != displays.last?.uuid {
                                Divider()
                            }
                        }
                    }
                }
                .padding(8)
            }

            GroupBox(label: Label(appState.localized("displays.precision"), systemImage: "slider.horizontal.3")) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(appState.localized("displays.stepSize"))
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Picker("", selection: $appState.settings.brightnessStepFraction) {
                            Text(appState.localized("displays.stepUltraFine")).tag(Float(0.01))
                            Text(appState.localized("displays.stepBalanced")).tag(Float(0.05))
                            Text(appState.localized("displays.stepCoarse")).tag(Float(0.10))
                        }
                        .pickerStyle(.menu)
                        .frame(width: 160)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(appState.localized("displays.minClamp"))
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text("\(Int(appState.settings.minBrightnessClamp * 100))%")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                        }
                        Slider(value: $appState.settings.minBrightnessClamp, in: 0.0...0.3, step: 0.05)
                        Text(appState.localized("displays.minClampHint"))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(8)
            }
        }
        .onAppear {
            refreshDisplays()
        }
    }

    private func displayRow(display: DisplayInfo) -> some View {
        let profile = appState.brightnessService.profile(for: display.uuid) ?? DisplayBrightnessProfile(
            displayUUID: display.uuid,
            displayName: display.name,
            preferredMethod: .auto,
            actualMethod: display.isBuiltIn ? .builtIn : .auto,
            brightnessLevel: Defaults.Brightness.defaultLevel,
            isBuiltIn: display.isBuiltIn
        )

        let resolved = BrightnessPolicy.resolveActualMethod(
            preferred: profile.preferredMethod,
            isBuiltIn: display.isBuiltIn,
            isDDCSupported: !display.isBuiltIn
        )

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(display.name)
                            .font(.system(size: 13, weight: .semibold))
                        if display.isBuiltIn {
                            Text(appState.localized("displays.builtInDisplay"))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.blue.opacity(0.12)))
                        } else {
                            Text(appState.localized("displays.externalDisplay"))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.purple)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.purple.opacity(0.12)))
                        }
                    }
                    Text("Display ID: \(display.id) • UUID: \(display.uuid.prefix(8))...")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Picker(appState.localized("displays.method"), selection: Binding(
                    get: { profile.preferredMethod },
                    set: { newMethod in
                        var updated = profile
                        updated.preferredMethod = newMethod
                        appState.updateDisplayProfile(updated)
                    }
                )) {
                    Text(appState.localized("displays.methodAuto")).tag(BrightnessMethod.auto)
                    if display.isBuiltIn {
                        Text(appState.localized("displays.methodBuiltIn")).tag(BrightnessMethod.builtIn)
                    } else {
                        Text(appState.localized("displays.methodDDC")).tag(BrightnessMethod.ddc)
                    }
                    Text(appState.localized("displays.methodSoftware")).tag(BrightnessMethod.software)
                }
                .pickerStyle(.menu)
                .frame(width: 190)
            }

            // Method Explanation & Status
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text("\(appState.localized("displays.activeMethodLabel")): \(resolved.method.displayName) — \(resolved.reason)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            // Live Slider Test
            HStack(spacing: 8) {
                Image(systemName: "sun.min")
                    .foregroundColor(.secondary)
                Slider(
                    value: Binding(
                        get: { Double(profile.brightnessLevel) },
                        set: { val in
                            var updated = profile
                            updated.brightnessLevel = Float(val)
                            appState.updateDisplayProfile(updated)
                            Task {
                                _ = await appState.brightnessService.setBrightness(Float(val), for: display)
                            }
                        }
                    ),
                    in: 0.0...1.0
                )
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.secondary)
                Text("\(Int(profile.brightnessLevel * 100))%")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .frame(width: 40)
            }
        }
        .padding(.vertical, 4)
    }

    private func refreshDisplays() {
        self.displays = appState.brightnessService.queryConnectedDisplays()
    }
}
