import SwiftUI
import EventKit
import SideDockCore

public struct RemindersConfig: Codable, Equatable, Sendable {
    public var selectedListIdentifier: String?
    public var showQuickAdd: Bool

    public init(selectedListIdentifier: String? = nil, showQuickAdd: Bool = true) {
        self.selectedListIdentifier = selectedListIdentifier
        self.showQuickAdd = showQuickAdd
    }
}

public struct ReminderItemUI: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let isCompleted: Bool

    public init(id: String, title: String, isCompleted: Bool) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

public struct RemindersWidgetView: View {
    public let config: RemindersConfig
    public let size: WidgetSize
    @State private var hasPermission: Bool = false
    @State private var topReminder: ReminderItemUI?
    @State private var quickAddText: String = ""
    @State private var isAdding: Bool = false
    @State private var eventStore = EKEventStore()

    public init(config: RemindersConfig = RemindersConfig(), size: WidgetSize = .medium) {
        self.config = config
        self.size = size
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checklist")
                .font(.system(size: 15))
                .foregroundColor(.blue)

            if !hasPermission {
                Button("Reminders") {
                    requestPermission()
                }
                .buttonStyle(.link)
                .font(.system(size: 11))
            } else if let reminder = topReminder {
                Button {
                    toggleComplete(reminder)
                } label: {
                    Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(reminder.isCompleted ? .green : .secondary)
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)

                Text(reminder.title)
                    .font(.system(size: 11))
                    .strikethrough(reminder.isCompleted)
                    .lineLimit(1)
            } else {
                Text("All done!")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            if config.showQuickAdd && size == .large {
                if isAdding {
                    TextField("New task...", text: $quickAddText)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 10))
                        .frame(width: 80)
                        .onSubmit {
                            addReminder()
                        }
                } else {
                    Button {
                        isAdding = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .onAppear {
            checkPermissionAndFetch()
        }
    }

    private func checkPermissionAndFetch() {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        if #available(macOS 14.0, *) {
            hasPermission = (status == .fullAccess || status == .writeOnly)
        } else {
            hasPermission = (status == .authorized)
        }

        if hasPermission {
            fetchReminders()
        }
    }

    private func requestPermission() {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToReminders { granted, _ in
                DispatchQueue.main.async {
                    self.hasPermission = granted
                    if granted { self.fetchReminders() }
                }
            }
        } else {
            eventStore.requestAccess(to: .reminder) { granted, _ in
                DispatchQueue.main.async {
                    self.hasPermission = granted
                    if granted { self.fetchReminders() }
                }
            }
        }
    }

    private func fetchReminders() {
        let predicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
        eventStore.fetchReminders(matching: predicate) { reminders in
            DispatchQueue.main.async {
                if let first = reminders?.first {
                    self.topReminder = ReminderItemUI(
                        id: first.calendarItemIdentifier,
                        title: first.title ?? "Task",
                        isCompleted: first.isCompleted
                    )
                } else {
                    self.topReminder = nil
                }
            }
        }
    }

    private func toggleComplete(_ item: ReminderItemUI) {
        guard let ekReminder = eventStore.calendarItem(withIdentifier: item.id) as? EKReminder else { return }
        ekReminder.isCompleted = true
        try? eventStore.save(ekReminder, commit: true)
        self.topReminder = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            fetchReminders()
        }
    }

    private func addReminder() {
        guard !quickAddText.trimmingCharacters(in: .whitespaces).isEmpty else {
            isAdding = false
            return
        }
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = quickAddText
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
        try? eventStore.save(reminder, commit: true)
        quickAddText = ""
        isAdding = false
        fetchReminders()
    }
}
