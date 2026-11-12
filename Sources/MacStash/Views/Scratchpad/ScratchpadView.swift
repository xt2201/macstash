import SwiftUI
import AppKit
import MacStashCore

/// An instant floating scratchpad drawer for capturing ephemeral thoughts,
/// verification codes, terminal commands, or text snippets with automatic local persistence.
public struct ScratchpadView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var manager = ScratchpadManager.shared

    @State private var copyFeedback: Bool = false
    @State private var sentToStashFeedback: Bool = false
    @FocusState private var isEditorFocused: Bool

    private let drawerWidth: CGFloat = Defaults.Scratchpad.defaultWidthPoints
    private let drawerHeight: CGFloat = Defaults.Scratchpad.defaultHeightPoints

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        let screenHeight = NSScreen.main?.visibleFrame.height ?? 800
        let targetHeight = max(280, min(drawerHeight, screenHeight * 0.72))

        return VStack(spacing: 0) {
            // 1. Liquid Glass Header Bar
            headerBar

            Divider()
                .background(
                    LinearGradient(
                        colors: [Color.green.opacity(0.4), Color.primary.opacity(0.06)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            // 2. Text Editor Area
            editorArea

            // 3. Subtle Footer Hint & Live Metrics
            footerBar
        }
        .frame(width: drawerWidth, height: targetHeight)
        .liquidGlass(
            cornerRadius: 20,
            tint: .green,
            specularIntensity: 1.15,
            causticOpacity: 0.16,
            shadowRadius: 22,
            backdropOpacity: appState.settings.dialOpacity
        )
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "note.text")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.green)
                .shadow(color: Color.green.opacity(0.35), radius: 3, x: 0, y: 0)

            Text(appState.localized("scratchpad.title"))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer()

            if !manager.text.isEmpty {
                HoverActionButton(
                    systemImage: sentToStashFeedback ? "checkmark" : "tray.and.arrow.down",
                    tint: sentToStashFeedback ? .cyan : .secondary,
                    size: 24,
                    helpText: appState.localized("scratchpad.moveToStash")
                ) {
                    appState.stashShelf.addTextSnippet(manager.text)
                    withAnimation(.easeInOut(duration: 0.15)) { sentToStashFeedback = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation(.easeInOut(duration: 0.15)) { sentToStashFeedback = false }
                    }
                }
            }

            HoverActionButton(
                systemImage: copyFeedback ? "checkmark" : "doc.on.doc",
                tint: copyFeedback ? .green : .secondary,
                size: 24,
                helpText: appState.localized("scratchpad.copyAll")
            ) {
                manager.copyAll()
                withAnimation(.easeInOut(duration: 0.15)) { copyFeedback = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeInOut(duration: 0.15)) { copyFeedback = false }
                }
            }

            if manager.canUndoClear {
                HoverActionButton(
                    systemImage: "arrow.uturn.backward",
                    tint: .green,
                    size: 24,
                    helpText: appState.localized("scratchpad.restore")
                ) {
                    manager.undoClear()
                }
            }

            if !manager.text.isEmpty {
                HoverActionButton(
                    systemImage: "trash",
                    tint: .red,
                    size: 24,
                    helpText: appState.localized("scratchpad.clear")
                ) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        manager.clear()
                    }
                }
            }

            HoverActionButton(
                systemImage: manager.isPinned ? "pin.fill" : "pin",
                tint: manager.isPinned ? .green : .secondary,
                size: 24,
                helpText: manager.isPinned ? appState.localized("scratchpad.unpin") : appState.localized("scratchpad.pin")
            ) {
                manager.togglePin()
            }

            HoverActionButton(
                systemImage: "xmark",
                tint: .secondary,
                size: 24,
                helpText: appState.localized("scratchpad.close")
            ) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    manager.isScratchpadOpen = false
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Editor Area

    private var editorArea: some View {
        ZStack(alignment: .topLeading) {
            if manager.text.isEmpty {
                Text(appState.localized("scratchpad.placeholder"))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.65))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $manager.text)
                .font(.system(size: 12, design: .monospaced))
                .scrollContentBackground(.hidden)
                .focused($isEditorFocused)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        isEditorFocused = true
                    }
                }
        }
    }

    // MARK: - Footer Bar

    private var footerBar: some View {
        HStack {
            Text(appState.localized("scratchpad.shortcutHint"))
                .font(.system(size: 9.5))
                .foregroundColor(.secondary.opacity(0.8))

            Spacer()

            Text(String(format: appState.localized("scratchpad.wordsChars"), manager.wordCount, manager.characterCount))
                .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                .monospacedDigit()
                .foregroundColor(.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.primary.opacity(0.06)))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.primary.opacity(0.025))
    }
}
