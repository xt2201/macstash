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
            GroupBox(label: Label(appState.localized("pomodoro.intervalDurations"), systemImage: "timer")) {
                VStack(alignment: .leading, spacing: 14) {
                    durationRow(
                        title: appState.localized("pomodoro.focusDuration"),
                        minutes: $appState.settings.pomodoroFocusDurationMinutes,
                        range: 1...120
                    )

                    Divider()

                    durationRow(
                        title: appState.localized("pomodoro.shortBreakDuration"),
                        minutes: $appState.settings.pomodoroShortBreakMinutes,
                        range: 1...30
                    )

                    Divider()

                    durationRow(
                        title: appState.localized("pomodoro.longBreakDuration"),
                        minutes: $appState.settings.pomodoroLongBreakMinutes,
                        range: 1...60
                    )

                    Divider()

                    HStack {
                        Text(appState.localized("pomodoro.roundsBeforeLong"))
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Stepper("\(appState.settings.pomodoroRoundsBeforeLongBreak) \(appState.localized("pomodoro.rounds"))", value: $appState.settings.pomodoroRoundsBeforeLongBreak, in: 1...12)
                    }
                }
                .padding(8)
            }

            GroupBox(label: Label(appState.localized("pomodoro.automationAlerts"), systemImage: "bell.badge")) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(appState.localized("pomodoro.autoStartBreak"), isOn: $appState.settings.pomodoroAutoStartBreaks)
                    Toggle(appState.localized("pomodoro.playChime"), isOn: $appState.settings.pomodoroSoundEnabled)
                }
                .padding(8)
            }

            GroupBox(label: Label(appState.localized("pomodoro.currentState"), systemImage: "clock.arrow.circlepath")) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(appState.localized("pomodoro.currentState")): \(appState.isPomodoroRunning ? appState.localized("pomodoro.statusRunning") : appState.localized("pomodoro.statusPaused"))")
                            .font(.system(size: 13, weight: .semibold))
                        Text("\(appState.localized("pomodoro.timeRemaining")) \(appState.formattedTimerTime)")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                    }

                    Spacer()

                    Button(appState.isPomodoroRunning ? appState.localized("pomodoro.btnPause") : appState.localized("pomodoro.btnStart")) {
                        appState.toggleAction(.timer)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(appState.localized("pomodoro.btnReset")) {
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
            Stepper("\(minutes.wrappedValue) \(appState.effectiveLanguage == "vi" ? "phút" : "min")", value: minutes, in: range)
        }
    }
}
