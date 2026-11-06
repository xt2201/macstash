import SwiftUI
import AppKit
import MacStashCore

public struct PomodoroTab: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    private var statusDescription: String {
        if appState.isPomodoroRunning {
            return appState.localized("pomodoro.statusRunning")
        }
        if case .paused = appState.pomodoroEngine.state {
            return appState.localized("pomodoro.statusPausedOnly")
        }
        return appState.localized("pomodoro.statusIdle")
    }

    private var modeTitle: String {
        switch appState.pomodoroMode {
        case .focus: return appState.localized("pomodoro.modeFocus")
        case .shortBreak: return appState.localized("pomodoro.modeShortBreak")
        case .longBreak: return appState.localized("pomodoro.modeLongBreak")
        }
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
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("\(appState.localized("pomodoro.currentMode")) \(modeTitle)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(appState.pomodoroMode == .focus ? .purple : .green)

                                Text("•")
                                    .foregroundColor(.secondary)

                                Text("\(statusDescription)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: 8) {
                                Text("\(appState.localized("pomodoro.timeRemaining")) \(appState.formattedTimerTime)")
                                    .font(.system(size: 22, weight: .bold, design: .monospaced))

                                if appState.pomodoroTotalRounds > 0 {
                                    Text(String(format: appState.localized("pomodoro.roundIndicator"), min(appState.pomodoroTotalRounds, appState.pomodoroCompletedRounds + 1), appState.pomodoroTotalRounds))
                                        .font(.system(size: 10, weight: .semibold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.secondary.opacity(0.12)))
                                }
                            }
                        }

                        Spacer()

                        HStack(spacing: 8) {
                            Button(appState.isPomodoroRunning ? appState.localized("pomodoro.btnPause") : appState.localized("pomodoro.btnStart")) {
                                appState.togglePomodoro()
                            }
                            .buttonStyle(.borderedProminent)

                            Button(appState.localized("pomodoro.btnSkip")) {
                                appState.skipPomodoroMode()
                            }
                            .buttonStyle(.bordered)

                            Button(appState.localized("pomodoro.btnReset")) {
                                appState.resetPomodoro()
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    // Progress Track
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.15))
                                .frame(height: 4)

                            Capsule()
                                .fill(appState.pomodoroMode == .focus ? Color.purple : Color.green)
                                .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(appState.pomodoroProgress))), height: 4)
                        }
                    }
                    .frame(height: 4)
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
            Stepper("\(minutes.wrappedValue) \(appState.localized("pomodoro.minutesUnit"))", value: minutes, in: range)
        }
    }
}
