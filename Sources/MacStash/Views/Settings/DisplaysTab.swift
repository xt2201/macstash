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
            GroupBox(label: Label("Connected Displays", systemImage: "display.2")) {
                VStack(alignment: .leading, spacing: 16) {
                    if displays.isEmpty {
                        Text("Scanning for connected displays...")
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

            GroupBox(label: Label("Brightness Adjustment Precision", systemImage: "slider.horizontal.3")) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Adjustment Step Size:")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Picker("", selection: $appState.settings.brightnessStepFraction) {
                            Text("1% (Ultra Fine)").tag(Float(0.01))
                            Text("5% (Balanced)").tag(Float(0.05))
                            Text("10% (Coarse)").tag(Float(0.10))
                        }
                        .pickerStyle(.menu)
                        .frame(width: 160)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Minimum Hardware Clamp:")
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text("\(Int(appState.settings.minBrightnessClamp * 100))%")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                        }
                        Slider(value: $appState.settings.minBrightnessClamp, in: 0.0...0.3, step: 0.05)
                        Text("Prevents backlight turning completely black when dialing to minimum.")
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
                            Text("Built-in Retina")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.blue.opacity(0.12)))
                        } else {
                            Text("External Display")
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

                Picker("Method", selection: Binding(
                    get: { profile.preferredMethod },
                    set: { newMethod in
                        var updated = profile
                        updated.preferredMethod = newMethod
                        appState.brightnessService.setProfile(updated)
                    }
                )) {
                    Text("Auto").tag(BrightnessMethod.auto)
                    if display.isBuiltIn {
                        Text("Native DisplayServices").tag(BrightnessMethod.builtIn)
                    } else {
                        Text("DDC/CI Hardware").tag(BrightnessMethod.ddc)
                    }
                    Text("Software Dimming").tag(BrightnessMethod.software)
                }
                .pickerStyle(.menu)
                .frame(width: 170)
            }

            // Method Explanation & Status
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text("Active Method: \(resolved.method.displayName) — \(resolved.reason)")
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
                            appState.brightnessService.setProfile(updated)
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
