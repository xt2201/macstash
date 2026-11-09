import SwiftUI
import AppKit
import MacStashCore

/// Outer Left-Edge Container View that hosts the tactile Stash Shelf
/// and the Quick Scratchpad Drawer with a sleek, non-intrusive edge peek affordance.
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
        HStack(alignment: .center, spacing: 6) {
            if isOpen {
                // When open: Show active drawer with integrated mini tab bar
                HStack(spacing: 6) {
                    drawerTabBar

                    if shelf.isShelfOpen || shelf.isDropTargetActive {
                        StashShelfView(appState: appState)
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else if scratchpad.isScratchpadOpen {
                        ScratchpadView(appState: appState)
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isOpen)
    }

    // MARK: - Drawer Tab Bar (Mode Switcher when Open)

    private var drawerTabBar: some View {
        VStack(spacing: 8) {
            // Stash Shelf Mode
            Button(action: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                    scratchpad.isScratchpadOpen = false
                    shelf.openShelf()
                }
            }) {
                ZStack {
                    Circle()
                        .fill((shelf.isShelfOpen || shelf.isDropTargetActive) ? Color.cyan : Color.white.opacity(0.12))
                        .frame(width: 28, height: 28)

                    Image(systemName: "tray.2.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor((shelf.isShelfOpen || shelf.isDropTargetActive) ? .black : .white)
                }
            }
            .buttonStyle(.plain)
            .help("Stash Shelf")

            // Scratchpad Mode
            Button(action: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                    shelf.closeShelf()
                    scratchpad.isScratchpadOpen = true
                }
            }) {
                ZStack {
                    Circle()
                        .fill(scratchpad.isScratchpadOpen ? Color.green : Color.white.opacity(0.12))
                        .frame(width: 28, height: 28)

                    Image(systemName: "note.text")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(scratchpad.isScratchpadOpen ? .black : .white)
                }
            }
            .buttonStyle(.plain)
            .help("Quick Scratchpad")

            Spacer()

            // Close Drawer Button
            Button(action: {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    shelf.closeShelf()
                    scratchpad.isScratchpadOpen = false
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 24, height: 24)

                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            .help("Close (Esc)")
        }
        .frame(width: 32, height: 160)
        .padding(.vertical, 8)
        .padding(.horizontal, 2)
        .liquidGlass(cornerRadius: 16, tint: .cyan, specularIntensity: 0.9, causticOpacity: 0.12, shadowRadius: 10)
        .padding(.leading, 4)
    }
}
