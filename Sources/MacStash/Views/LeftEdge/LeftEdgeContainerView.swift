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
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isOpen)
    }

    // MARK: - Resting Peek Handle (Zero Obtrusion)

    private var restingPeekHandle: some View {
        ZStack(alignment: .leading) {
            // Generous hover & click sensor zone (44pt wide, 84pt high centered)
            Color.clear
                .frame(width: 44, height: 84)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        scratchpad.isScratchpadOpen = false
                        shelf.openShelf()
                    }
                }

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
                            .circularLiquidGlass(tint: .cyan, specularIntensity: 0.9, causticOpacity: 0.25, isHighlighted: true)
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
                            .circularLiquidGlass(tint: .green, specularIntensity: 0.9, causticOpacity: 0.25, isHighlighted: false)
                        }
                        .buttonStyle(.plain)
                        .help("Open Quick Scratchpad (⌥N)")
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .liquidGlass(cornerRadius: 16, tint: .cyan, specularIntensity: 1.0, causticOpacity: 0.15, shadowRadius: 10)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                } else {
                    // Resting state: Subtle 3.5pt vertical indicator
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color.white.opacity(0.28))
                        .frame(width: 3.5, height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .stroke(Color.white.opacity(0.4), lineWidth: 0.5)
                        )
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
        .liquidGlass(cornerRadius: 16, tint: .cyan, specularIntensity: 0.9, causticOpacity: 0.12, shadowRadius: 10)
        .padding(.leading, 4)
    }
}
