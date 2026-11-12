import SwiftUI
import SideDockCore
import SideDockWidgets

public struct DockSettingsTabView: View {
    @Binding public var config: SideDockFileConfig
    public let onSave: (Bool) -> Void
    public let onResetLayout: () -> Void

    @State private var showWidgetGallery: Bool = false
    @State private var editingWidgetItem: WidgetItem? = nil

    public init(
        config: Binding<SideDockFileConfig>,
        onSave: @escaping (Bool) -> Void,
        onResetLayout: @escaping () -> Void
    ) {
        self._config = config
        self.onSave = onSave
        self.onResetLayout = onResetLayout
    }

    private var activeProfileIndex: Int {
        if let idx = config.profiles.firstIndex(where: { $0.id == config.activeProfileId }) {
            return idx
        }
        return 0
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            DockPlacementSection(
                config: $config,
                activeProfileIndex: activeProfileIndex,
                onSave: onSave
            )

            DockBehaviorSection(
                config: $config,
                activeProfileIndex: activeProfileIndex,
                onSave: onSave
            )

            DockAppearanceSection(
                config: $config,
                activeProfileIndex: activeProfileIndex,
                onSave: onSave
            )

            DockProfilesSection(
                config: $config,
                activeProfileIndex: activeProfileIndex,
                onSave: onSave,
                onResetLayout: onResetLayout,
                onOpenWidgetGallery: { showWidgetGallery = true }
            )

            DockItemsEditorSection(
                config: $config,
                activeProfileIndex: activeProfileIndex,
                onSave: onSave,
                onOpenWidgetGallery: { showWidgetGallery = true },
                onEditWidget: { widget in editingWidgetItem = widget }
            )

            DockShortcutsAndPermissionsSection(
                config: $config,
                onSave: onSave
            )
        }
        .padding(.bottom, 20)
        .sheet(isPresented: $showWidgetGallery) {
            WidgetGalleryView { newItem in
                config.profiles[activeProfileIndex].items.append(.widget(newItem))
                onSave(true)
                showWidgetGallery = false
            }
        }
        .sheet(item: $editingWidgetItem) { widgetItem in
            WidgetConfigSheet(widgetItem: widgetItem) { updatedWidget in
                if let itemIdx = config.profiles[activeProfileIndex].items.firstIndex(where: { $0.id == updatedWidget.id }) {
                    config.profiles[activeProfileIndex].items[itemIdx] = .widget(updatedWidget)
                    onSave(true)
                }
            }
        }
    }
}
