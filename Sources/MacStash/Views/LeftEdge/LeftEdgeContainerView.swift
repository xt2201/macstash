import SwiftUI
import AppKit
import MacStashCore

/// Outer Left-Edge Container View that hosts both the Tactile Stash Shelf
/// and the Quick Scratchpad Drawer with a sleek edge tab selector.
public struct LeftEdgeContainerView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var shelf = StashShelfManager.shared
    @ObservedObject private var scratchpad = ScratchpadManager.shared

    @State private var isEdgeHovered: Bool = false

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 6) {
            // Left Edge Touch & Tab Bar (Always accessible along physical left edge)
            edgeTabBar

            // Active Slide-Out Drawer Content
            if shelf.isShelfOpen || shelf.isDropTargetActive {
                StashShelfView(appState: appState)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            } else if scratchpad.isScratchpadOpen {
                ScratchpadView(appState: appState)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: shelf.isShelfOpen || shelf.isDropTargetActive || scratchpad.isScratchpadOpen)
    }

    private var edgeTabBar: some View {
        ZStack(alignment: .leading) {
            // Thin invisible hit zone along physical screen edge
            Color.clear
                .frame(width: 14)
                .contentShape(Rectangle())

            // Slide-out mini tabs visible on hover
            if isEdgeHovered || shelf.isShelfOpen || scratchpad.isScratchpadOpen {
                VStack(spacing: 8) {
                    // Stash Shelf Tab
                    Button(action: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.76)) {
                            scratchpad.isScratchpadOpen = false
                            shelf.isShelfOpen.toggle()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(shelf.isShelfOpen ? Color.cyan.opacity(0.35) : Color.black.opacity(0.4))
                                .frame(width: 28, height: 28)
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))

                            Image(systemName: "tray.2.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(shelf.isShelfOpen ? .cyan : .white)
                        }
                    }
                    .buttonStyle(.plain)
                    .help("Stash Shelf")

                    // Scratchpad Tab
                    Button(action: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.76)) {
                            shelf.isShelfOpen = false
                            scratchpad.isScratchpadOpen.toggle()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(scratchpad.isScratchpadOpen ? Color.green.opacity(0.35) : Color.black.opacity(0.4))
                                .frame(width: 28, height: 28)
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))

                            Image(systemName: "note.text")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(scratchpad.isScratchpadOpen ? .green : .white)
                        }
                    }
                    .buttonStyle(.plain)
                    .help("Quick Scratchpad")
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 2, y: 2)
                )
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .frame(width: 36, height: 100)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isEdgeHovered = hovering
            }
        }
    }
}
