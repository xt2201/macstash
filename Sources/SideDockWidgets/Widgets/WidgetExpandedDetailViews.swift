import SwiftUI
import AppKit
import SideDockCore
import MacStashDesignSystem

/// Rich expandable floating detail cards shown when a user clicks or expands a dock widget.
public struct WidgetExpandedDetailView: View {
    public let item: WidgetItem

    public init(item: WidgetItem) {
        self.item = item
    }

    public var body: some View {
        let data = item.configurationData ?? Data()
        switch item.widgetKind {
        case "batteries":
            let cfg = (try? JSONDecoder().decode(BatteriesConfig.self, from: data)) ?? BatteriesConfig()
            BatteriesExpandedView(config: cfg)
        case "photoFrame":
            let cfg = (try? JSONDecoder().decode(PhotoFrameConfig.self, from: data)) ?? PhotoFrameConfig()
            PhotoFrameExpandedView(config: cfg)
        case "search":
            ExpandedSpotlightSearchView()
        case "quickNote":
            ExpandedQuickNoteView()
        case "clipboard":
            ExpandedClipboardView()
        default:
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: WidgetRegistry.shared.descriptor(for: item.widgetKind)?.systemIconName ?? "square.grid.2x2")
                        .foregroundColor(.accentColor)
                    Text(item.customTitle ?? WidgetRegistry.shared.descriptor(for: item.widgetKind)?.displayName ?? item.widgetKind.capitalized)
                        .font(.system(size: 13, weight: .bold))
                    Spacer()
                }
                Divider()
                WidgetRegistry.shared.makeWidgetView(for: WidgetItem(
                    id: item.id,
                    widgetKind: item.widgetKind,
                    size: .large,
                    customTitle: item.customTitle,
                    configurationData: item.configurationData
                ))
                .frame(maxWidth: .infinity, minHeight: 72)
            }
            .padding(14)
            .frame(width: 280)
        }
    }
}

private struct ExpandedSpotlightSearchView: View {
    @State private var query: String = ""
    @State private var matchingApps: [URL] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search apps or Spotlight...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .onSubmit {
                        if let first = matchingApps.first {
                            NSWorkspace.shared.open(first)
                        } else if let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                                  let url = URL(string: "spotlight://\(encoded)") {
                            NSWorkspace.shared.open(url)
                        }
                    }
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.primary.opacity(0.08)))

            if !matchingApps.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(matchingApps.prefix(6), id: \.path) { url in
                        Button {
                            NSWorkspace.shared.open(url)
                        } label: {
                            HStack(spacing: 8) {
                                Image(nsImage: AppIconCache.shared.icon(forPath: url.path, targetSize: NSSize(width: 20, height: 20)))
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Text(url.deletingPathExtension().lastPathComponent)
                                    .font(.system(size: 12, weight: .medium))
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .frame(width: 300)
        .onChange(of: query) { _, newValue in
            scanMatchingApps(query: newValue)
        }
    }

    private func scanMatchingApps(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else {
            matchingApps = []
            return
        }
        Task {
            let found = await Task.detached(priority: .userInitiated) {
                let dirs = ["/Applications", "/System/Applications", "/System/Applications/Utilities"]
                var matches: [URL] = []
                for dir in dirs {
                    if let urls = try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: dir), includingPropertiesForKeys: nil) {
                        for u in urls where u.pathExtension == "app" {
                            let name = u.deletingPathExtension().lastPathComponent.lowercased()
                            if name.contains(trimmed) {
                                matches.append(u)
                            }
                        }
                    }
                }
                return matches
            }.value
            await MainActor.run {
                matchingApps = found
            }
        }
    }
}

private struct ExpandedQuickNoteView: View {
    @AppStorage("SideDock_QuickNoteText") private var noteText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Quick Note", systemImage: "note.text")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Text("\(noteText.count) chars")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                Button("Clear") { noteText = "" }
                    .controlSize(.small)
            }

            TextEditor(text: $noteText)
                .font(.system(size: 12))
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(height: 150)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.primary.opacity(0.06)))
        }
        .padding(14)
        .frame(width: 300)
    }
}

private struct ExpandedClipboardView: View {
    @State private var currentText: String = ""
    @State private var copiedFeedback: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Clipboard", systemImage: "doc.on.clipboard")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Button(copiedFeedback ? "Copied" : "Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(currentText, forType: .string)
                    copiedFeedback = true
                }
                .controlSize(.small)
                .disabled(currentText.isEmpty)
            }

            Text(currentText.isEmpty ? "Clipboard has no plain text." : currentText)
                .font(.system(size: 11.5))
                .foregroundColor(currentText.isEmpty ? .secondary : .primary)
                .lineLimit(6)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.primary.opacity(0.06)))
        }
        .padding(14)
        .frame(width: 280)
        .onAppear {
            currentText = NSPasteboard.general.string(forType: .string) ?? ""
        }
    }
}
