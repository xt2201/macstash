import SwiftUI
import AppKit
import MacStashCore

/// Outer edge container view that hosts the tactile Stash Shelf
/// and Quick Scratchpad Drawer with symmetrical Left/Right edge attachment.
public struct LeftEdgeContainerView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var shelf = StashShelfManager.shared
    @ObservedObject private var scratchpad = ScratchpadManager.shared

    public init(appState: AppState) {
        self.appState = appState
    }

    private var isOpen: Bool {
        shelf.isShelfOpen || shelf.isDropTargetActive || scratchpad.isScratchpadOpen
    }

    public var body: some View {
        let isRight = appState.settings.drawerEdgePosition == .right
        let transitionEdge: Edge = isRight ? .trailing : .leading

        HStack(alignment: .center, spacing: 6) {
            if isOpen {
                HStack(spacing: 6) {
                    if isRight {
                        drawerView(transitionEdge: transitionEdge)
                        drawerTabBar(isRight: true)
                    } else {
                        drawerTabBar(isRight: false)
                        drawerView(transitionEdge: transitionEdge)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isRight ? .trailing : .leading)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isOpen)
        .onHover { isHovered in
            if isHovered {
                ScreenManager.shared.cancelPendingLeftEdgeHide()
            } else {
                let isAnyPinned = (shelf.isShelfOpen && shelf.isPinned) || (scratchpad.isScratchpadOpen && scratchpad.isPinned)
                if isOpen && !isAnyPinned && !shelf.isDropTargetActive {
                    ScreenManager.shared.scheduleLeftEdgeHideTimer()
                }
            }
        }
        .macStashTheme(appState.resolvedColorScheme)
    }

    @ViewBuilder
    private func drawerView(transitionEdge: Edge) -> some View {
        if shelf.isShelfOpen || shelf.isDropTargetActive {
            StashShelfView(appState: appState)
                .transition(.asymmetric(
                    insertion: .move(edge: transitionEdge).combined(with: .opacity),
                    removal: .move(edge: transitionEdge).combined(with: .opacity)
                ))
        } else if scratchpad.isScratchpadOpen {
            ScratchpadView(appState: appState)
                .transition(.asymmetric(
                    insertion: .move(edge: transitionEdge).combined(with: .opacity),
                    removal: .move(edge: transitionEdge).combined(with: .opacity)
                ))
        }
    }

    // MARK: - Drawer Tab Bar (Mode Switcher when Open)

    private func drawerTabBar(isRight: Bool) -> some View {
        let isShelfActive = shelf.isShelfOpen || shelf.isDropTargetActive
        let isPadActive = scratchpad.isScratchpadOpen && !isShelfActive

        return VStack(spacing: 8) {
            if appState.settings.isStashShelfEnabled || isShelfActive {
                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        scratchpad.isScratchpadOpen = false
                        shelf.openShelf()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(isShelfActive ? Color.cyan : Color.primary.opacity(0.10))
                            .frame(width: 28, height: 28)

                        Image(systemName: "tray.2.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(isShelfActive ? .black : .primary)
                    }
                }
                .buttonStyle(.plain)
                .help(appState.localized("general.stashShelf"))
            }

            if appState.settings.isScratchpadEnabled || isPadActive {
                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        shelf.closeShelf()
                        scratchpad.isScratchpadOpen = true
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(isPadActive ? Color.green : Color.primary.opacity(0.10))
                            .frame(width: 28, height: 28)

                        Image(systemName: "note.text")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(isPadActive ? .black : .primary)
                    }
                }
                .buttonStyle(.plain)
                .help(appState.localized("general.scratchpad"))
            }

            Spacer()

            Button(action: {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    shelf.closeShelf()
                    scratchpad.isScratchpadOpen = false
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 24, height: 24)

                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            .help(appState.localized("scratchpad.close"))
        }
        .frame(width: 32, height: 156)
        .padding(.vertical, 8)
        .padding(.horizontal, 2)
        .liquidGlass(cornerRadius: 16, tint: isPadActive ? .green : .cyan, specularIntensity: 0.9, causticOpacity: 0.14, shadowRadius: 10)
        .padding(isRight ? .trailing : .leading, 4)
    }
}
