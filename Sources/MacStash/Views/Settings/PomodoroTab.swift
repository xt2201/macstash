import SwiftUI
import AppKit
import MacStashCore

public struct PomodoroTab: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    private var modeTint: Color {
        appState.pomodoroMode == .focus ? .red : .green
    }

    private var statusText: String {
        if appState.isPomodoroRunning {
            return appState.localized("pomodoro.statusRunning")
        } else if appState.isPomodoroPaused {
            return appState.localized("pomodoro.statusPausedOnly")
        } else {
            return appState.localized("pomodoro.statusIdle")
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Section 1: Hero Timer & Session Control
            SettingsCard(
                title: appState.localized("pomodoro.currentState"),
                systemImage: "timer",
                accentColor: modeTint
            ) {
                HStack(alignment: .center, spacing: 22) {
                    // Countdown Ring
                    ZStack {
                        Circle()
                            .stroke(Color.primary.opacity(0.08), lineWidth: 8)

                        Circle()
                            .trim(from: 0, to: CGFloat(max(0.0, min(1.0, appState.pomodoroProgress))))
                            .stroke(
                                AngularGradient(
                                    colors: appState.pomodoroMode == .focus
                                        ? [Color.orange, Color.red, Color.pink]
                                        : [Color.mint, Color.green, Color.teal],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 0.25), value: appState.pomodoroProgress)

                        VStack(spacing: 3) {
                            Text(appState.formattedTimerTime)
                                .font(.system(size: 22, weight: .bold, design: .monospaced))
                                .monospacedDigit()

                            Text(localizedModeName(appState.pomodoroMode))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(modeTint)
                        }
                    }
                    .frame(width: 112, height: 112)

                    // Controls & Mode Switcher
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            StatusBadgePill(
                                text: statusText,
                                color: appState.isPomodoroRunning ? modeTint : (appState.isPomodoroPaused ? .orange : .secondary)
                            )

                            Spacer()

                            // Round Dots
                            HStack(spacing: 4) {
                                let total = max(1, appState.pomodoroTotalRounds)
                                ForEach(0..<total, id: \.self) { idx in
                                    let filled = idx < (appState.pomodoroCompletedRounds % max(1, total))
                                    Circle()
                                        .fill(filled ? modeTint : Color.primary.opacity(0.14))
                                        .frame(width: 7, height: 7)
                                }
                            }

                            Button(appState.localized("pomodoro.resetRounds")) {
                                appState.resetPomodoroRounds()
                            }
                            .buttonStyle(.borderless)
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Picker("", selection: Binding(
                                get: { appState.pomodoroMode },
                                set: { appState.setPomodoroMode($0) }
                            )) {
                                Text(appState.localized("pomodoro.modeFocus")).tag(PomodoroMode.focus)
                                Text(appState.localized("pomodoro.modeShortBreak")).tag(PomodoroMode.shortBreak)
                                Text(appState.localized("pomodoro.modeLongBreak")).tag(PomodoroMode.longBreak)
                            }
                            .labelsHidden()
                            .pickerStyle(.segmented)
                            .disabled(appState.isPomodoroRunning)

                            Text(appState.localized("pomodoro.modeHint"))
                                .font(.system(size: 10.5))
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 8) {
                            Button {
                                appState.togglePomodoro()
                            } label: {
                                Label(
                                    appState.localized(appState.isPomodoroRunning ? "pomodoro.btnPause" : "pomodoro.btnStart"),
                                    systemImage: appState.isPomodoroRunning ? "pause.fill" : "play.fill"
                                )
                                .font(.system(size: 12, weight: .semibold))
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(modeTint)

                            Button {
                                appState.skipPomodoroMode()
                            } label: {
                                Label(appState.localized("pomodoro.btnSkip"), systemImage: "forward.end.fill")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .buttonStyle(.bordered)

                            Button {
                                appState.resetPomodoro()
                            } label: {
                                Label(appState.localized("pomodoro.btnReset"), systemImage: "arrow.counterclockwise")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .buttonStyle(.bordered)
                        }

                        Text("\(appState.localized("pomodoro.completedRoundsLabel")) \(appState.pomodoroCompletedRounds)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Section 2: Interval Durations
            SettingsCard(
                title: appState.localized("pomodoro.intervalDurations"),
                systemImage: "clock.fill",
                accentColor: .orange
            ) {
                durationStepperRow(
                    label: appState.localized("pomodoro.focusDuration"),
                    value: $appState.settings.pomodoroFocusDurationMinutes,
                    range: 1...120,
                    unit: appState.localized("pomodoro.minutesUnit")
                )

                Divider()

                durationStepperRow(
                    label: appState.localized("pomodoro.shortBreakDuration"),
                    value: $appState.settings.pomodoroShortBreakMinutes,
                    range: 1...60,
                    unit: appState.localized("pomodoro.minutesUnit")
                )

                Divider()

                durationStepperRow(
                    label: appState.localized("pomodoro.longBreakDuration"),
                    value: $appState.settings.pomodoroLongBreakMinutes,
                    range: 1...90,
                    unit: appState.localized("pomodoro.minutesUnit")
                )

                Divider()

                durationStepperRow(
                    label: appState.localized("pomodoro.roundsBeforeLong"),
                    value: $appState.settings.pomodoroRoundsBeforeLongBreak,
                    range: 1...12,
                    unit: appState.localized("pomodoro.rounds")
                )
            }

            // Section 3: Automation & Alerts
            SettingsCard(
                title: appState.localized("pomodoro.automationAlerts"),
                systemImage: "bell.badge.fill",
                accentColor: .purple
            ) {
                Toggle(appState.localized("pomodoro.autoStartBreak"), isOn: $appState.settings.pomodoroAutoStartBreaks)
                    .font(.system(size: 12.5, weight: .medium))

                Divider()

                Toggle(appState.localized("pomodoro.playChime"), isOn: $appState.settings.pomodoroSoundEnabled)
                    .font(.system(size: 12.5, weight: .medium))
            }
        }
    }

    private func durationStepperRow(
        label: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        unit: String
    ) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12.5, weight: .medium))
            Spacer()
            Stepper(value: value, in: range) {
                Text("\(value.wrappedValue) \(unit)")
                    .font(.system(size: 12.5, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .frame(minWidth: 72, alignment: .trailing)
            }
        }
    }

    private func localizedModeName(_ mode: PomodoroMode) -> String {
        switch mode {
        case .focus: return appState.localized("pomodoro.modeFocus")
        case .shortBreak: return appState.localized("pomodoro.modeShortBreak")
        case .longBreak: return appState.localized("pomodoro.modeLongBreak")
        }
    }
}
