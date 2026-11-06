import SwiftUI
import AppKit
import MacStashCore

public struct PomodoroTab: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            GroupBox(label: Label("Interval Durations", systemImage: "timer")) {
                VStack(alignment: .leading, spacing: 14) {
                    durationRow(
                        title: "Focus Session Duration:",
                        minutes: $appState.settings.pomodoroFocusDurationMinutes,
                        range: 1...120
                    )

                    Divider()

                    durationRow(
                        title: "Short Break Duration:",
                        minutes: $appState.settings.pomodoroShortBreakMinutes,
                        range: 1...30
                    )

                    Divider()

                    durationRow(
                        title: "Long Break Duration:",
                        minutes: $appState.settings.pomodoroLongBreakMinutes,
                        range: 1...60
                    )

                    Divider()

                    HStack {
                        Text("Rounds Before Long Break:")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Stepper("\(appState.settings.pomodoroRoundsBeforeLongBreak) rounds", value: $appState.settings.pomodoroRoundsBeforeLongBreak, in: 1...12)
                    }
                }
                .padding(8)
            }

            GroupBox(label: Label("Automation & Alerts", systemImage: "bell.badge")) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Automatically start break when focus ends", isOn: $appState.settings.pomodoroAutoStartBreaks)
                    Toggle("Play chime alert when timer completes", isOn: $appState.settings.pomodoroSoundEnabled)
                }
                .padding(8)
            }

            GroupBox(label: Label("Current Pomodoro State", systemImage: "clock.arrow.circlepath")) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Phase: \(appState.pomodoroEngine.mode.displayName)")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Remaining: \(appState.formattedTimerTime)")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                    }

                    Spacer()

                    Button(appState.isPomodoroRunning ? "Pause" : "Start") {
                        appState.toggleAction(.timer)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Reset") {
                        appState.pomodoroEngine.reset()
                        appState.pomodoroRemainingSeconds = appState.pomodoroEngine.remainingSeconds
                        appState.pomodoroProgress = appState.pomodoroEngine.progress
                        appState.isPomodoroRunning = false
                    }
                    .buttonStyle(.bordered)
                }
                .padding(8)
            }
        }
    }

    private func durationRow(title: String, minutes: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .medium))
            Spacer()
            Stepper("\(minutes.wrappedValue) min", value: minutes, in: range)
        }
    }
}
