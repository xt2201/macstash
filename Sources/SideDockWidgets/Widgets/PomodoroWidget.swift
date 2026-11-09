import SwiftUI
import UserNotifications
import SideDockCore

public struct PomodoroConfig: Codable, Equatable, Sendable {
    public var focusMinutes: Int
    public var shortBreakMinutes: Int

    public init(focusMinutes: Int = 25, shortBreakMinutes: Int = 5) {
        self.focusMinutes = max(1, focusMinutes)
        self.shortBreakMinutes = max(1, shortBreakMinutes)
    }
}

public struct PomodoroWidgetView: View {
    public let config: PomodoroConfig
    public let size: WidgetSize
    @State private var remainingSeconds: Int = 25 * 60
    @State private var isRunning: Bool = false
    @State private var isBreak: Bool = false
    @State private var timer: Timer?

    public init(config: PomodoroConfig = PomodoroConfig(), size: WidgetSize = .small) {
        self.config = config
        self.size = size
        _remainingSeconds = State(initialValue: config.focusMinutes * 60)
    }

    private var formattedTime: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    public var body: some View {
        HStack(spacing: 6) {
            Button {
                toggleTimer()
            } label: {
                Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(isBreak ? .green : .red)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 1) {
                Text(formattedTime)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))

                if size != .small {
                    Text(isBreak ? "Break" : "Focus")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }

            if size != .small {
                Button {
                    resetTimer()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }

    private func toggleTimer() {
        if isRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }

    private func startTimer() {
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                } else {
                    self.handleComplete()
                }
            }
        }
    }

    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func resetTimer() {
        pauseTimer()
        isBreak = false
        remainingSeconds = config.focusMinutes * 60
    }

    private func handleComplete() {
        pauseTimer()
        isBreak.toggle()
        remainingSeconds = (isBreak ? config.shortBreakMinutes : config.focusMinutes) * 60
        sendNotification(
            title: isBreak ? "Focus Sprint Complete!" : "Break Finished!",
            body: isBreak ? "Take a short break and stretch." : "Ready for your next focus session?"
        )
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }
}
