import SwiftUI
import SideDockCore
import SideDockWidgets
import MacStashCore

public struct WidgetGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    public let onAddWidget: (WidgetItem) -> Void
    @State private var searchText: String = ""
    @State private var selectedCategory: WidgetCategory? = nil
    @State private var selectedSizeForWidget: [String: WidgetSize] = [:]

    private func localized(_ key: String) -> String {
        LocalizationService.shared.localized(key)
    }

    public init(onAddWidget: @escaping (WidgetItem) -> Void) {
        self.onAddWidget = onAddWidget
    }

    private var filteredDescriptors: [WidgetDescriptor] {
        WidgetRegistry.shared.searchDescriptors(query: searchText, category: selectedCategory)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header + Close
            HStack {
                Text(localized("dock.browseWidgets").replacingOccurrences(of: "...", with: ""))
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Button(localized("dock.done")) {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Search and Category Bar
            HStack(spacing: 10) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField(localized("gallery.searchPlaceholder"), text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(7)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.06)))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        CategoryChip(title: localized("gallery.all"), isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach(WidgetCategory.allCases, id: \.self) { cat in
                            CategoryChip(title: cat.rawValue, isSelected: selectedCategory == cat) {
                                selectedCategory = cat
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            Divider()

            // Widgets Grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260, maximum: 340), spacing: 12)], spacing: 12) {
                    ForEach(filteredDescriptors) { desc in
                        WidgetCardView(
                            descriptor: desc,
                            selectedSize: selectedSizeForWidget[desc.id] ?? desc.supportedSizes.first ?? .medium,
                            addLabel: localized("gallery.add"),
                            sizeLabel: localized("gallery.size"),
                            onSelectSize: { size in
                                selectedSizeForWidget[desc.id] = size
                            },
                            onAdd: {
                                let size = selectedSizeForWidget[desc.id] ?? desc.supportedSizes.first ?? .medium
                                let item = WidgetItem(widgetKind: desc.id, size: size, customTitle: desc.displayName)
                                onAddWidget(item)
                            }
                        )
                    }
                }
                .padding(16)
            }
        }
        .frame(minWidth: 620, minHeight: 460)
    }
}

private struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color.primary.opacity(0.08))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

private struct WidgetCardView: View {
    let descriptor: WidgetDescriptor
    let selectedSize: WidgetSize
    let addLabel: String
    let sizeLabel: String
    let onSelectSize: (WidgetSize) -> Void
    let onAdd: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 9) {
                Image(systemName: descriptor.systemIconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.accentColor.gradient)
                    )

                VStack(alignment: .leading, spacing: 1) {
                    Text(descriptor.displayName)
                        .font(.system(size: 13, weight: .bold))
                    Text(descriptor.category.rawValue)
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(addLabel, action: onAdd)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }

            Text(descriptor.description)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Text(sizeLabel)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)

                ForEach(descriptor.supportedSizes, id: \.self) { sz in
                    Button {
                        onSelectSize(sz)
                    } label: {
                        Text(sz.rawValue.capitalized)
                            .font(.system(size: 9.5, weight: selectedSize == sz ? .bold : .regular))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(selectedSize == sz ? Color.accentColor.opacity(0.2) : Color.primary.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(selectedSize == sz ? Color.accentColor : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }

            HStack(spacing: 4) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 8.5))
                    .foregroundColor(.secondary)
                Text(descriptor.privacyNote)
                    .font(.system(size: 9.5))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isHovered ? Color.primary.opacity(0.07) : Color.primary.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isHovered ? Color.accentColor.opacity(0.35) : Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
        .onHover { isHovered = $0 }
    }
}
