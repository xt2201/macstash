import SwiftUI
import AppKit
import MacStashCore

/// Outer Left-Edge Container View that hosts the tactile Stash Shelf
/// and the Quick Scratchpad Drawer with a sleek, non-intrusive edge peek affordance.
public struct LeftEdgeContainerView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var shelf = StashShelfManager.shared
    @ObservedObject private var scratchpad = ScratchpadManager.shared

    @State private var isHandleHovered: Bool = false

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
            } else {
                // When closed: Minimalist, elegant Peek Handle flush with physical screen edge
                restingPeekHandle
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .animation(.spring(response: 0.30, dampingFraction: 0.82), value: isOpen)
    }

    // MARK: - Resting Peek Handle (Zero Obtrusion)

    private var restingPeekHandle: some View {
        ZStack(alignment: .leading) {
            // Invisible hover sensor zone (22pt wide, 64pt high centered)
            Color.clear
                .frame(width: 22, height: 64)
                .contentShape(Rectangle())

            // Visual handle
            HStack(spacing: 0) {
                if isHandleHovered {
                    // Expanded state on hover: Frosted pill with quick launcher icons
                    VStack(spacing: 8) {
                        Button(action: {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                                scratchpad.isScratchpadOpen = false
                                shelf.openShelf()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.cyan.opacity(0.25))
                                    .frame(width: 24, height: 24)

                                Image(systemName: "tray.2.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.cyan)
                            }
                        }
                        .buttonStyle(.plain)
                        .help("Open Stash Shelf (⌥S)")

                        Button(action: {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                                shelf.closeShelf()
                                scratchpad.isScratchpadOpen = true
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.25))
                                    .frame(width: 24, height: 24)

                                Image(systemName: "note.text")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.green)
                            }
                        }
                        .buttonStyle(.plain)
                        .help("Open Quick Scratchpad (⌥N)")
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 2, y: 2)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .transition(.move(edge: .leading).combined(with: .opacity))
                } else {
                    // Resting state: Subtle 3.5pt vertical indicator
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 3.5, height: 48)
                        .shadow(color: Color.black.opacity(0.25), radius: 3, x: 1, y: 1)
                }
            }
        }
        .onHover { hovering in
            withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                isHandleHovered = hovering
            }
        }
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
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.25), radius: 10, x: 2, y: 2)
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .padding(.leading, 4)
    }
}
