import SwiftUI
import SideDockCore
import SideDockWidgets
import MacStashCore

public struct SmartStackEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let existing: SmartStackItem?
    public let onSave: (SmartStackItem) -> Void

    @State private var title: String
    @State private var widgets: [WidgetItem]
    @State private var size: WidgetSize
    @State private var autoRotateSeconds: Double
    @State private var selectedKindToAdd: String = "weather"

    public init(existing: SmartStackItem? = nil, onSave: @escaping (SmartStackItem) -> Void) {
        self.existing = existing
        self.onSave = onSave
        _title = State(initialValue: existing?.title ?? "Smart Stack")
        _widgets = State(initialValue: existing?.widgets ?? [
            WidgetItem(widgetKind: "weather", size: .medium),
            WidgetItem(widgetKind: "nowPlaying", size: .medium)
        ])
        _size = State(initialValue: existing?.size ?? .medium)
        _autoRotateSeconds = State(initialValue: existing?.autoRotateSeconds ?? 0.0)
    }

    private func localized(_ key: String) -> String {
        LocalizationService.shared.localized(key)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(localized("dock.smartStackEditorTitle"))
                .font(.system(size: 15, weight: .bold))

            Divider()

            TextField("Stack Title", text: $title)
                .textFieldStyle(.roundedBorder)

            VStack(alignment: .leading, spacing: 6) {
                Text(localized("dock.widgetSize"))
                    .font(.system(size: 12, weight: .medium))
                Picker("", selection: $size) {
                    Text(localized("dock.sizeSmall")).tag(WidgetSize.small)
                    Text(localized("dock.sizeMedium")).tag(WidgetSize.medium)
                    Text(localized("dock.sizeLarge")).tag(WidgetSize.large)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            HStack {
                Text(localized("dock.autoRotate"))
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Picker("", selection: $autoRotateSeconds) {
                    Text("Off").tag(0.0)
                    Text("10s").tag(10.0)
                    Text("15s").tag(15.0)
                    Text("30s").tag(30.0)
                    Text("60s").tag(60.0)
                }
                .pickerStyle(.menu)
                .frame(width: 110)
            }

            HStack {
                Picker("", selection: $selectedKindToAdd) {
                    ForEach(WidgetRegistry.shared.allDescriptors()) { desc in
                        Text(desc.displayName).tag(desc.id)
                    }
                }
                .pickerStyle(.menu)

                Button(localized("dock.add")) {
                    widgets.append(WidgetItem(widgetKind: selectedKindToAdd, size: size))
                }
                .buttonStyle(.bordered)
            }

            ScrollView {
                VStack(spacing: 4) {
                    ForEach(Array(widgets.enumerated()), id: \.element.id) { idx, w in
                        let name = WidgetRegistry.shared.descriptor(for: w.widgetKind)?.displayName ?? w.widgetKind
                        HStack {
                            Text(name).font(.system(size: 12, weight: .medium))
                            Spacer()
                            if idx > 0 {
                                Button { widgets.swapAt(idx, idx - 1) } label: {
                                    Image(systemName: "chevron.up").font(.system(size: 10))
                                }
                                .buttonStyle(.plain)
                            }
                            if widgets.count > 1 {
                                Button { widgets.remove(at: idx) } label: {
                                    Image(systemName: "trash").font(.system(size: 11)).foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.05)))
                    }
                }
            }
            .frame(height: 140)

            Divider()

            HStack {
                Spacer()
                Button(localized("dock.cancel")) { dismiss() }
                    .buttonStyle(.bordered)
                Button(localized("dock.done")) {
                    let stack = SmartStackItem(
                        id: existing?.id ?? UUID(),
                        title: title.isEmpty ? "Smart Stack" : title,
                        widgets: widgets,
                        activeIndex: existing?.activeIndex ?? 0,
                        size: size,
                        autoRotateSeconds: autoRotateSeconds > 0 ? autoRotateSeconds : nil
                    )
                    onSave(stack)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(widgets.isEmpty)
            }
        }
        .padding(18)
        .frame(width: 410)
    }
}
