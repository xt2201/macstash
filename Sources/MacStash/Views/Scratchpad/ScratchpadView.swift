import SwiftUI
import AppKit
import MacStashCore

/// An instant floating scratchpad drawer for capturing ephemeral thoughts,
/// verification codes, terminal commands, or text snippets with automatic local persistence,
/// styled with Apple Liquid Glass optical shading.
public struct ScratchpadView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var manager = ScratchpadManager.shared

    @State private var copyFeedback: Bool = false
    @FocusState private var isEditorFocused: Bool

    private let drawerWidth: CGFloat = Defaults.Scratchpad.defaultWidthPoints
    private let drawerHeight: CGFloat = Defaults.Scratchpad.defaultHeightPoints

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 1. Liquid Glass Header Bar
            headerBar

            Divider()
                .background(
                    LinearGradient(
                        colors: [Color.green.opacity(0.4), Color.white.opacity(0.06)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            // 2. Text Editor Area
            editorArea
        }
        .frame(width: drawerWidth, height: drawerHeight)
        .liquidGlass(
            cornerRadius: 20,
            tint: .green,
            specularIntensity: 1.15,
            causticOpacity: 0.18,
            shadowRadius: 22
        )
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "note.text")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.green)
                .shadow(color: Color.green.opacity(0.45), radius: 3, x: 0, y: 0)

            Text("SCRATCHPAD")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Spacer()

            Text("\(manager.wordCount)w · \(manager.characterCount)c")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 2.5)
                .background(Capsule().fill(Color.white.opacity(0.08)))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                )

            // Copy All Button
            Button(action: {
                manager.copyAll()
                withAnimation(.easeInOut(duration: 0.15)) { copyFeedback = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeInOut(duration: 0.15)) { copyFeedback = false }
                }
            }) {
                Image(systemName: copyFeedback ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(copyFeedback ? .green : .secondary)
                    .frame(width: 26, height: 26)
                    .circularLiquidGlass(
                        tint: copyFeedback ? .green : .clear,
                        specularIntensity: 0.8,
                        causticOpacity: 0.2,
                        isHighlighted: copyFeedback
                    )
            }
            .buttonStyle(.plain)
            .help("Copy All to Clipboard")

            // Undo Clear Button (if available)
            if manager.canUndoClear {
                Button(action: {
                    manager.undoClear()
                }) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.green)
                        .frame(width: 26, height: 26)
                        .circularLiquidGlass(
                            tint: .green,
                            specularIntensity: 0.8,
                            causticOpacity: 0.2,
                            isHighlighted: true
                        )
                }
                .buttonStyle(.plain)
                .help("Restore Cleared Notes")
            }

            // Clear Button
            Button(action: {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    manager.clear()
                }
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 26, height: 26)
                    .circularLiquidGlass(
                        tint: .clear,
                        specularIntensity: 0.8,
                        causticOpacity: 0.15
                    )
            }
            .buttonStyle(.plain)
            .help("Clear All")

            // Pin / Keep Open Button
            Button(action: {
                manager.togglePin()
            }) {
                Image(systemName: manager.isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(manager.isPinned ? .green : .secondary)
                    .frame(width: 26, height: 26)
                    .circularLiquidGlass(
                        tint: manager.isPinned ? .green : .clear,
                        specularIntensity: 0.8,
                        causticOpacity: manager.isPinned ? 0.25 : 0.15,
                        isHighlighted: manager.isPinned
                    )
            }
            .buttonStyle(.plain)
            .help(manager.isPinned ? "Unpin Scratchpad" : "Pin Scratchpad (Keep Open)")

            // Close Button
            Button(action: {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    manager.isScratchpadOpen = false
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 26, height: 26)
                    .circularLiquidGlass(
                        tint: .clear,
                        specularIntensity: 0.8,
                        causticOpacity: 0.15
                    )
            }
            .buttonStyle(.plain)
            .help("Close (Esc)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Editor Area

    private var editorArea: some View {
        ZStack(alignment: .topLeading) {
            if manager.text.isEmpty {
                Text("Type or paste quick notes, snippets, OTP codes, or prompts here...\nAutomatically saved.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.6))
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
}
