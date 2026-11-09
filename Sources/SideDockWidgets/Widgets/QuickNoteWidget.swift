import SwiftUI
import AppKit
import SideDockCore

public struct QuickNoteConfig: Codable, Equatable, Sendable {
    public var defaultNote: String

    public init(defaultNote: String = "") {
        self.defaultNote = defaultNote
    }
}

public struct QuickNoteWidgetView: View {
    public let config: QuickNoteConfig
    public let size: WidgetSize

    @AppStorage("SideDock_QuickNoteText") private var noteText: String = ""
    @State private var isEditing: Bool = false

    public init(config: QuickNoteConfig = QuickNoteConfig(), size: WidgetSize = .medium) {
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
    }

    private var smallView: some View {
        Button {
            isEditing.toggle()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: "note.text")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.yellow)
                Text(noteText.isEmpty ? "Notes" : "\(noteText.count) chars")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isEditing) {
            popoverEditor
        }
    }

    private var mediumView: some View {
        Button {
            isEditing.toggle()
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Label("Quick Note", systemImage: "note.text")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.yellow)
                    Spacer()
                    Text("\(noteText.split(whereSeparator: \.isWhitespace).count) words")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }

                Text(noteText.isEmpty ? "Click to write a quick thought..." : noteText)
                    .font(.system(size: 9))
                    .foregroundColor(noteText.isEmpty ? .secondary : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(6)
            .frame(width: size == .large ? 180 : 130, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isEditing) {
            popoverEditor
        }
    }

    private var popoverEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Quick Scratchpad")
                    .font(.system(size: 11, weight: .bold))
                Spacer()
                Button("Clear") {
                    noteText = ""
                }
                .font(.system(size: 10))
            }

            TextEditor(text: $noteText)
                .font(.system(size: 11))
                .frame(width: 220, height: 120)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.primary.opacity(0.12), lineWidth: 1))
        }
        .padding(10)
    }
}
