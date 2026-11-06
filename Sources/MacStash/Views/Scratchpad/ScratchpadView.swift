import SwiftUI
import AppKit
import MacStashCore

/// An instant floating scratchpad drawer for capturing ephemeral thoughts,
/// verification codes, terminal commands, or text snippets with automatic local persistence.
public struct ScratchpadView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var manager = ScratchpadManager.shared

    private let drawerWidth: CGFloat = Defaults.Scratchpad.defaultWidthPoints
    private let drawerHeight: CGFloat = Defaults.Scratchpad.defaultHeightPoints

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        let isVisible = appState.isEnabled && appState.settings.isScratchpadEnabled
        let isOpen = manager.isScratchpadOpen

        ZStack(alignment: .leading) {
            if isVisible && isOpen {
                VStack(spacing: 0) {
                    // 1. Header
                    headerBar

                    Divider()
                        .background(Color.white.opacity(0.12))

                    // 2. Text Editor Area
                    editorArea
                }
                .frame(width: drawerWidth, height: drawerHeight)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.35), radius: 16, x: 4, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.green.opacity(0.6), Color.white.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.0
                        )
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: isOpen)
    }

    private var headerBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "note.text")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.green)

            Text("SCRATCHPAD")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Spacer()

            Text("\(manager.wordCount)w · \(manager.characterCount)c")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)

            Button(action: { manager.copyAll() }) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("Copy All")

            Button(action: { manager.clear() }) {
                Image(systemName: "trash")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("Clear")

            Button(action: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                    manager.isScratchpadOpen = false
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.8))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("Close")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var editorArea: some View {
        ZStack(alignment: .topLeading) {
            if manager.text.isEmpty {
                Text("Type or paste quick notes, snippets, OTP codes, or prompts here...\nAutomatically saved.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
            }

            TextEditor(text: $manager.text)
                .font(.system(size: 12, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
