import SwiftUI
import AppKit
import MacStashCore
import MacStashDesignSystem

public struct MenuBarPomodoroCard: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        let modeColor: Color = appState.pomodoroMode == .focus ? .purple : .green

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: appState.pomodoroMode == .focus ? "brain.head.profile" : "cup.and.saucer.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(modeColor)

                Text(modeTitle(for: appState.pomodoroMode))
                    .font(.system(size: 11, weight: .semibold))

                Spacer()

                if appState.pomodoroTotalRounds > 0 {
                    Text(String(format: appState.localized("pomodoro.roundIndicator"), min(appState.pomodoroTotalRounds, appState.pomodoroCompletedRounds + 1), appState.pomodoroTotalRounds))
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.primary.opacity(0.06)))
                }
            }

            HStack(alignment: .center) {
                Text(appState.formattedTimerTime)
                    .font(.system(size: 21, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundColor(appState.isPomodoroRunning ? .primary : .secondary)

                Spacer()

                HStack(spacing: 5) {
                    Button(action: { appState.togglePomodoro() }) {
                        Image(systemName: appState.isPomodoroRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 10, weight: .bold))
                            .frame(width: 22, height: 20)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(modeColor)
                    .controlSize(.small)
                    .help(appState.isPomodoroRunning ? appState.localized("menubar.pause") : appState.localized("menubar.start"))

                    Button(action: { appState.skipPomodoroMode() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 9.5, weight: .bold))
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help(appState.localized("menubar.skip"))

                    Button(action: { appState.resetPomodoro() }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 9.5, weight: .bold))
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help(appState.localized("menubar.reset"))
                }
            }

            GeometryReader { geo in
                let totalW = geo.size.width
                let fillW = max(0, min(totalW, totalW * CGFloat(appState.pomodoroProgress)))
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.09))
                        .frame(height: 4)

                    if fillW > 2 {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: appState.pomodoroMode == .focus
                                        ? [Color.purple, Color(red: 0.8, green: 0.4, blue: 1.0)]
                                        : [Color.green, Color(red: 0.4, green: 0.9, blue: 0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: fillW, height: 4)
                    }
                }
            }
            .frame(height: 4)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(modeColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(modeColor.opacity(0.20), lineWidth: 0.8)
        )
    }

    private func modeTitle(for mode: PomodoroMode) -> String {
        switch mode {
        case .focus: return appState.localized("pomodoro.modeFocus")
        case .shortBreak: return appState.localized("pomodoro.modeShortBreak")
        case .longBreak: return appState.localized("pomodoro.modeLongBreak")
        }
    }
}
