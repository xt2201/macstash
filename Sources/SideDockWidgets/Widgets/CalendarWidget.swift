import SwiftUI
import EventKit
import AppKit
import SideDockCore

public struct CalendarConfig: Codable, Equatable, Sendable {
    public var showMeetingJoinButton: Bool
    public var selectedCalendarIdentifiers: [String]

    public init(showMeetingJoinButton: Bool = true, selectedCalendarIdentifiers: [String] = []) {
        self.showMeetingJoinButton = showMeetingJoinButton
        self.selectedCalendarIdentifiers = selectedCalendarIdentifiers
    }
}

public struct UpcomingCalendarEvent: Equatable, Sendable {
    public let title: String
    public let startDate: Date
    public let endDate: Date
    public let meetingURL: URL?

    public init(title: String, startDate: Date, endDate: Date, meetingURL: URL? = nil) {
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.meetingURL = meetingURL
    }
}

public struct CalendarWidgetView: View {
    public let config: CalendarConfig
    public let size: WidgetSize
    @State private var hasPermission: Bool = false
    @State private var nextEvent: UpcomingCalendarEvent?
    @State private var eventStore = EKEventStore()

    public init(config: CalendarConfig = CalendarConfig(), size: WidgetSize = .medium) {
        self.config = config
        self.size = size
    }

    private var countdownText: String {
        guard let event = nextEvent else { return "No events" }
        let interval = event.startDate.timeIntervalSince(Date())
        if interval <= 0 {
            return "Now"
        }
        let minutes = Int(ceil(interval / 60.0))
        if minutes < 60 {
            return "in \(minutes)m"
        }
        let hours = minutes / 60
        return "in \(hours)h \(minutes % 60)m"
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.system(size: 16))
                .foregroundColor(.red)

            if !hasPermission {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Calendar")
                        .font(.system(size: 11, weight: .semibold))
                    Button("Enable") {
                        requestPermission()
                    }
                    .buttonStyle(.link)
                    .font(.system(size: 9))
                }
            } else if let event = nextEvent {
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)

                    Text(countdownText)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }

                if config.showMeetingJoinButton, let url = event.meetingURL, size != .small {
                    Button {
                        NSWorkspace.shared.open(url)
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "video.fill")
                            Text("Join")
                        }
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.green.opacity(0.8)))
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("No upcoming events")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .onAppear {
            checkPermissionAndFetch()
        }
    }

    private func checkPermissionAndFetch() {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(macOS 14.0, *) {
            hasPermission = (status == .fullAccess || status == .writeOnly)
        } else {
            hasPermission = (status == .authorized)
        }

        if hasPermission {
            fetchNextEvent()
        }
    }

    private func requestPermission() {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { granted, _ in
                DispatchQueue.main.async {
                    self.hasPermission = granted
                    if granted {
                        self.fetchNextEvent()
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, _ in
                DispatchQueue.main.async {
                    self.hasPermission = granted
                    if granted {
                        self.fetchNextEvent()
                    }
                }
            }
        }
    }

    private func fetchNextEvent() {
        let now = Date()
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(86400)
        let predicate = eventStore.predicateForEvents(withStart: now, end: endOfDay, calendars: nil)
        let events = eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }

        if let first = events.first {
            var meetURL: URL?
            if let url = first.url, isVideoMeetingURL(url) {
                meetURL = url
            } else if let notes = first.notes, let extracted = extractMeetingURL(from: notes) {
                meetURL = extracted
            }
            self.nextEvent = UpcomingCalendarEvent(
                title: first.title ?? "Event",
                startDate: first.startDate,
                endDate: first.endDate,
                meetingURL: meetURL
            )
        } else {
            self.nextEvent = nil
        }
    }

    private func isVideoMeetingURL(_ url: URL) -> Bool {
        let str = url.absoluteString.lowercased()
        return str.contains("zoom.us") || str.contains("meet.google.com") || str.contains("teams.microsoft.com") || str.contains("webex.com")
    }

    private func extractMeetingURL(from text: String) -> URL? {
        let patterns = [
            "https://[a-zA-Z0-9.-]*zoom.us/j/[0-9]+[^\\s]*",
            "https://meet.google.com/[a-z]{3}-[a-z]{4}-[a-z]{3}",
            "https://teams.microsoft.com/l/meetup-join/[^\\s]*"
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {
                return URL(string: String(text[range]))
            }
        }
        return nil
    }
}
