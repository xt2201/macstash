import SwiftUI
import SideDockCore
import SideDockWidgets

public struct SmartStackTileView: View {
    public let stack: SmartStackItem
    public let baseTileSize: CGFloat
    public let tileSpacing: CGFloat
    public let onCycle: (Int) -> Void
    public let onExpand: (WidgetItem) -> Void

    @State private var autoRotateTimer: Timer?

    public init(
        stack: SmartStackItem,
        baseTileSize: CGFloat,
        tileSpacing: CGFloat,
        onCycle: @escaping (Int) -> Void,
        onExpand: @escaping (WidgetItem) -> Void
    ) {
        self.stack = stack
        self.baseTileSize = baseTileSize
        self.tileSpacing = tileSpacing
        self.onCycle = onCycle
        self.onExpand = onExpand
    }

    private var tileWidth: CGFloat {
        stack.size.width(forBaseTileSize: Double(baseTileSize), spacing: Double(tileSpacing))
    }

    public var body: some View {
        ZStack(alignment: .trailing) {
            if let active = stack.activeWidget {
                WidgetRegistry.shared.makeWidgetView(for: WidgetItem(
                    id: active.id,
                    widgetKind: active.widgetKind,
                    size: stack.size,
                    customTitle: active.customTitle,
                    configurationData: active.configurationData
                ))
                .id(active.id)
                .frame(width: max(baseTileSize, tileWidth - 10), height: baseTileSize)
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    onExpand(active)
                }
            } else {
                VStack(spacing: 2) {
                    Image(systemName: "square.stack.3d.up")
                        .font(.system(size: 14))
                    Text("Empty")
                        .font(.system(size: 9))
                }
                .foregroundColor(.secondary)
                .frame(width: tileWidth, height: baseTileSize)
            }

            if stack.widgets.count > 1 {
                VStack(spacing: 3) {
                    ForEach(0..<min(stack.widgets.count, 5), id: \.self) { idx in
                        let currentIdx = ((stack.activeIndex % stack.widgets.count) + stack.widgets.count) % stack.widgets.count
                        Circle()
                            .fill(idx == currentIdx ? Color.accentColor : Color.primary.opacity(0.28))
                            .frame(width: idx == currentIdx ? 4.5 : 3.5, height: idx == currentIdx ? 4.5 : 3.5)
                            .onTapGesture {
                                onCycle(idx - currentIdx)
                            }
                    }
                }
                .padding(.trailing, 4)
            }
        }
        .frame(width: tileWidth, height: baseTileSize)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.11), lineWidth: 0.7)
        )
        .overlay(
            ScrollWheelCaptureView { step in
                if stack.widgets.count > 1 {
                    onCycle(step)
                }
            }
        )
        .contextMenu {
            if stack.widgets.count > 1 {
                Button("Next Widget") { onCycle(1) }
                Button("Previous Widget") { onCycle(-1) }
                Divider()
            }
            if let active = stack.activeWidget {
                Button("Expand Widget...") { onExpand(active) }
            }
        }
        .onAppear {
            startAutoRotateIfNeeded()
        }
        .onDisappear {
            autoRotateTimer?.invalidate()
            autoRotateTimer = nil
        }
    }

    private func startAutoRotateIfNeeded() {
        autoRotateTimer?.invalidate()
        guard let interval = stack.autoRotateSeconds, interval >= 3.0, stack.widgets.count > 1 else {
            return
        }
        autoRotateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task { @MainActor in
                onCycle(1)
            }
        }
    }
}
