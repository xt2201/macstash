import SwiftUI
import AppKit
import SideDockCore

public struct ClipboardConfig: Codable, Equatable, Sendable {
    public var maxHistory: Int

    public init(maxHistory: Int = 10) {
        self.maxHistory = maxHistory
    }
}

public struct ClipboardWidgetView: View {
    public let config: ClipboardConfig
    public let size: WidgetSize

    @State private var history: [String] = []
    @State private var lastChangeCount: Int = -1
    @State private var copiedIndex: Int?
    @State private var monitorTimer: Timer?

    public init(config: ClipboardConfig = ClipboardConfig(), size: WidgetSize = .medium) {
        self.config = config
        self.size = size
    }

    public var body: some View {
        Group {
            switch size {
            case .small:
                smallView
            case .medium, .large:
                mediumView
            }
        }
        .onAppear {
            startMonitoring()
        }
        .onDisappear {
            stopMonitoring()
        }
    }

    private var smallView: some View {
        Button {
            if let first = history.first {
                copyToClipboard(first, index: 0)
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: copiedIndex == 0 ? "checkmark" : "doc.on.clipboard")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(copiedIndex == 0 ? .green : .accentColor)
                Text(history.first?.prefix(8).description ?? "Empty")
                    .font(.system(size: 9))
                    .lineLimit(1)
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Clipboard: \(history.first ?? "Empty")")
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label("Clipboard", systemImage: "doc.on.clipboard")
                    .font(.system(size: 10, weight: .bold))
                Spacer()
                if !history.isEmpty {
                    Button {
                        history.removeAll()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            if history.isEmpty {
                Text("No recent clips")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(Array(history.prefix(3).enumerated()), id: \.offset) { idx, item in
                    Button {
                        copyToClipboard(item, index: idx)
                    } label: {
                        HStack {
                            Text(item)
                                .font(.system(size: 9))
                                .lineLimit(1)
                            Spacer()
                            if copiedIndex == idx {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8))
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 3).fill(Color.primary.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(6)
        .frame(width: size == .large ? 180 : 130, height: 44)
    }

    private func startMonitoring() {
        checkPasteboard()
        monitorTimer?.invalidate()
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            Task { @MainActor in
                self.checkPasteboard()
            }
        }
    }

    private func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
    }

    private func checkPasteboard() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount

        if let str = pb.string(forType: .string), !str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
            if !history.contains(trimmed) {
                history.insert(trimmed, at: 0)
                if history.count > config.maxHistory {
                    history.removeLast()
                }
            }
        }
    }

    private func copyToClipboard(_ text: String, index: Int) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        lastChangeCount = pb.changeCount
        copiedIndex = index
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if self.copiedIndex == index {
                self.copiedIndex = nil
            }
        }
    }
}
