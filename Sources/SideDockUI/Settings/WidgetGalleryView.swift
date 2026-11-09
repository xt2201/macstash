import SwiftUI
import SideDockCore
import SideDockWidgets

public struct WidgetGalleryView: View {
    public let onAddWidget: (WidgetItem) -> Void
    @State private var searchText: String = ""
    @State private var selectedCategory: WidgetCategory? = nil
    @State private var selectedSizeForWidget: [String: WidgetSize] = [:]

    public init(onAddWidget: @escaping (WidgetItem) -> Void) {
        self.onAddWidget = onAddWidget
    }

    private var filteredDescriptors: [WidgetDescriptor] {
        WidgetRegistry.shared.searchDescriptors(query: searchText, category: selectedCategory)
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Search and Category Bar
            HStack(spacing: 10) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search widgets...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.06)))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        CategoryChip(title: "All", isSelected: selectedCategory == nil) {
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
            .padding(.top, 12)

            Divider()

            // Widgets Grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260, maximum: 340), spacing: 12)], spacing: 12) {
                    ForEach(filteredDescriptors) { desc in
                        WidgetCardView(
                            descriptor: desc,
                            selectedSize: selectedSizeForWidget[desc.id] ?? desc.supportedSizes.first ?? .medium,
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
        .frame(minWidth: 580, minHeight: 440)
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
    let onSelectSize: (WidgetSize) -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: descriptor.systemIconName)
                    .font(.system(size: 18))
                    .foregroundColor(.accentColor)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 1) {
                    Text(descriptor.displayName)
                        .font(.system(size: 13, weight: .bold))
                    Text(descriptor.category.rawValue)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Add", action: onAdd)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }

            Text(descriptor.description)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Size Picker
            HStack(spacing: 6) {
                Text("Size:")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)

                ForEach(descriptor.supportedSizes, id: \.self) { sz in
                    Button {
                        onSelectSize(sz)
                    } label: {
                        Text(sz.rawValue.capitalized)
                            .font(.system(size: 9, weight: selectedSize == sz ? .bold : .regular))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(selectedSize == sz ? Color.accentColor.opacity(0.2) : Color.primary.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(selectedSize == sz ? Color.accentColor : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }

            // Privacy Note / Permissions
            HStack(spacing: 4) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                Text(descriptor.privacyNote)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}
